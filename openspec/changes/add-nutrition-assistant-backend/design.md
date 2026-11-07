# Design

Status: disetujui dan diimplementasikan pada 8 November 2026. Design mencatat route/parser, privasi log, retrieval, agregasi dan provider yang diterapkan. Lihat proposal.md untuk motivasi dan tasks.md untuk verifikasi aktual.

## Context

AssistantScreen memiliki mode general/pattern serta compare historis; semua reply masih lokal. Scope baru hanya general/pattern, sesuai arahan pengguna agar compare diabaikan. Flutter dan penghapusan navigasi compare dikerjakan terpisah.

Backend sudah menyediakan dummy owner, requestVision (JSON, timeout 45 detik, no retry), scanSlot (dua operasi), serta kalkulasi Decimal dan tanggal lokal. retrieveContext memilih profil allowlist, subtotal hari ini, lima riwayat dari maksimal 100 kandidat dan tiga referensi reviewed; konteksnya maksimal sekitar 8000 karakter. Sampel ini bukan agregasi tujuh hari lengkap. app.ts sekarang memakai parser JSON global 10 MB; assistant membutuhkan batas lokal lebih kecil. Logger saat ini mengecualikan body compare saja.

## Goals / Non-Goals

**Goals:** satu endpoint teks yang dapat dihubungkan tim Flutter, sumber jelas, ringkasan pola dari seluruh catatan pada window terbatas, reuse fungsi lama dan zero writes.

**Non-Goals:** histori chat permanen, chat server session, tool calling/agent loop, semantic/vector search, foto/OCR assistant, compare handoff, CRUD konsumsi lewat chat, streaming, TTS assistant atau model baru. Tidak mengubah prompt/perilaku scanner dan compare.

## Decisions

### 1. Kontrak sesi sederhana

POST `{API_PREFIX}/v1/assistant/messages`, default `/api/v1/assistant/messages`, JSON `application/json`. Required mode=general|pattern dan message; history opsional default []. Semua objek additionalProperties=false. message dan history[].text di-trim, wajib nonblank dan masing-masing maksimal 2000 Unicode code points; history maksimal 10 pesan, mulai user dan berakhir assistant, berpasangan bergantian. Total teks saat ini plus history maksimal 12000 code points. Role selain user/assistant ditolak. Tidak menerima userId, system prompt, tanggal custom, gambar atau compareSnapshot.

Baseline proposal adalah chat selama sesi; belum ada kebutuhan eksplisit membuka chat lama setelah restart. Tidak membuat tabel atau migration. Flutter kelak menyimpan pasangan selesai dalam sesi, memilih maksimal lima pasangan terakhir dan mengirimnya secara eksplisit. Backend tidak memangkas diam-diam atau percaya isi history sebagai fakta server. Pesan saat ini tidak diduplikasi dalam history. Saat user berpindah general/pattern, frontend sebaiknya memulai history baru agar konteks jelas.

Alternatif session memory backend ditolak karena hilang saat restart dan membutuhkan lifecycle; persistensi dua tabel ditunda sampai ada kebutuhan histori chat. Provider tidak memiliki memori otomatis lintas request.

### 2. Batas parser dan kapasitas bersama

Pasang parser JSON khusus assistant di app.ts sebelum parser global, cocok case-insensitive dan trailing slash seperti routing Express. Batas 64 KiB, termasuk chunked; compressed request tidak didukung. Pastikan malformed JSON/charset/encoding/batas byte dipetakan ke envelope domain 400/413/415 dan route lain tetap memakai kebijakan lama. Implementasi guard/schema tetap di validation/assistant.ts; jangan menambah framework middleware baru.

Router assistant menggunakan demoOwner dan scanSlot yang sama. Controller menandai scanRunning selama analisis dan melepas releaseScanSlot pada finally; disconnect tidak melepas provider in-flight. Pertahankan kode 429 SCAN_BUSY untuk kompatibilitas kapasitas bersama, jelaskan maknanya di kontrak assistant. Tidak menjanjikan idempotency atau exactly-once lintas submission.

### 3. Reuse konteks tanpa mengubah retrieval scanner

getProfile dan retrieveContext dipanggil sekali per request dengan waktu snapshot yang sama dan query dari current message ditambah history user yang dibatasi. Pilih context.profile dan context.references untuk general; jangan kirim context.history, recordedDaily atau identitas. Pembacaan internal helper lama yang tidak terpakai diterima demi diff kecil; tidak perlu merombak retrieval scanner. Untuk pattern, sertakan maksimal lima contoh history relevan jika budget cukup, dengan penanda bahwa contoh bukan keseluruhan window.

Profil provider hanya priorities, preference, eatingPattern, prefersHalal, allergyStatus, allergies dan otherAllergies. Nama/email/password/usia/tinggi/berat/audio tidak dikirim. Referensi maksimal tiga reviewed dari helper lama. Tidak menambah embedding, lookup eksternal atau referensi baru yang belum direview. Semua data, termasuk history role assistant dari klien dan teks referensi, diposisikan sebagai data tidak tepercaya di bawah system prompt server.

### 4. Evidence pola dihitung dari tujuh tanggal lokal

Untuk pattern, ambil tanggal hari ini menurut timezone profil dan enam tanggal sebelumnya lewat aritmetika tanggal kalender, bukan subtract 7*24 jam. dayBounds menentukan batas awal tiap tanggal; batas akhir window adalah snapshotAt, sehingga future entries tidak ikut. Satu query FoodEntry owner-scope dengan take=1001 dan urutan consumedAt/id stabil; jika lebih dari 1000, kembalikan 422 PATTERN_LIMIT_EXCEEDED tanpa dispatch. Tidak memakai sampel retrieveContext untuk menghitung tren lengkap.

Gunakan summarize untuk total periode dan masing-masing tujuh hari: entryCount, recordedIntakeOnly=true, delapan nutrients dengan knownTotal/knownCount/missingCount/complete/provenanceCounts. totals/summarize menghormati quantity/baseQuantity dengan Decimal dan round enam desimal. Hari kosong mendapat entryCount=0, knownTotal=null, complete=false. daysWithEntries menghitung tanggal yang memiliki catatan, bukan kecukupan konsumsi.

Kelompok makanan memakai title.trim().toLowerCase() yang sama persis, bukan kategori hasil tebakan. Frekuensi adalah jumlah entri, bukan jumlah porsi atau hari. Pilih lima grup teratas berdasarkan count desc lalu title asc; pertahankan nama tampilan, entryCount dan summarize(group) sebagai kontribusi nutrisi. Tidak mengklaim dua judul mirip pasti makanan yang sama. Tidak menghitung persentase, target klinis atau verdict aman; UI bisa membaca agregasi yang dikirim tanpa parsing narasi.

Konteks provider maksimal 64 KiB UTF-8 setelah serialization, terpisah dari budget request/history. Buang contoh history lalu referensi terakhir bila perlu; jangan membuang hari/angka untuk mengaku window tetap lengkap. sources dan flags dibentuk hanya dari referensi yang benar-benar terkirim. Jika profil+evidence wajib masih melebihi batas, gagal 503 CONTEXT_TOO_LARGE sebelum provider. Tidak menyimpan snapshot ke database.

### 5. Prompt dan output assistant terpisah

assistant.service.ts memiliki assistantPrompt/promptVersion, membangun system prompt dan satu user JSON berisi mode, current message, history dan konteks server. History role menjadi data terstruktur; klien tidak dapat menyuntik system/tool message. Gunakan requestVision yang sudah menerima messages generik; namanya tidak mewajibkan image. Tidak perlu mengekstrak transport lagi atau mengubah kontrak DeepSeek/scanner. Reuse env/model yang sama, max_tokens=2048, output maksimum 64 KiB, timeout 45 detik, stream=false.

Provider diminta JSON ketat `{reply, citationIds}`: reply plain text Indonesia sehari-hari, nonblank, maksimal 4000 karakter; citationIds unik, maksimal tiga dari context.references. Validasi tipe/field/ukuran/ID dan tolak core output tidak valid dengan 502, tanpa repair. URL sumber selalu dibentuk server dari ID yang valid; larang URL/Markdown sumber buatan model di reply. Prompt melarang diagnosis, pengobatan, jaminan aman/alergen/halal, angka nutrisi makanan spesifik dari memori, perhitungan baru dan pola yang tidak ada pada evidence. Informasi umum boleh dijelaskan kualitatif; batas numerik harus didukung referensi yang tersedia.

Tidak ada fake reply saat provider gagal. Data terstruktur tetap menjadi sumber angka. Validasi schema/ID dan contoh tes prompt bukan pembuktian kebenaran seluruh makna prosa model; keterbatasan ini wajib ada pada handoff, bukan klaim sistem menjamin fakta.

### 6. Respons dan error

Envelope sukses HTTP 200: `{success,message,data,timestamp}`. data berisi:

| Field | Isi |
|---|---|
| reply | Teks model tervalidasi, langsung untuk bubble assistant |
| sources | Referensi yang dikutip, ID/title/sourceTitle/sourceUrl/version/reviewedAt dari server |
| warnings | Keterbatasan deterministik: referensi kosong, data parsial, hanya konsumsi tercatat/cold start |
| contextSummary | mode, snapshotAt, timezone, historyMessageCount, referencesAvailable; patternEvidence=null untuk general |
| contextSummary.patternEvidence | dateFrom/dateTo (inklusif), windowEndExclusive, entryCount, daysWithEntries, recordedIntakeOnly, periodSummary, dailySummaries, frequentFoods |
| model / promptVersion | Metadata konfigurasi dan versi prompt |

Tidak mengembalikan prompt, raw context/history, profil personal atau persisted conversation/message ID. patternEvidence menggunakan struktur deterministik pada keputusan 4; dailySummaries selalu tujuh tanggal termasuk yang kosong. recordedIntakeOnly berlaku untuk agregasi dan harus dijelaskan pada reply/warnings. Pembukaan general cukup greeting lokal tanpa call; shortcut pattern kelak mengirim pertanyaan awal eksplisit, tidak memakai percakapan contoh.

Error domain `{success:false,message,data:{code},timestamp}`: 400 input/JSON/owner override; 404 demo disabled; 413 byte limit; 415 content type/encoding; 422 PATTERN_LIMIT_EXCEEDED; 429 SCAN_BUSY; 502 provider/output/citation gagal; 503 profil/database/provider config/context budget; 504 timeout. Tidak mengekspos provider body, key atau stack.

### 7. Privasi, kompatibilitas dan file terdampak

requestLogger harus mengenali path assistant sebelum parsing, menghilangkan body request/response dan query termasuk error, case-insensitive dan trailing slash. Header tetap mengikuti redaksi yang ada; hanya metadata operasional disimpan. Tidak ada cache hasil, file chat, write Prisma atau createScan.

File baru sesuai proposal; tambahkan app.ts pada daftar file berubah untuk parser khusus. Tes assistant.test.cjs memuat validasi/HTTP, pure pattern aggregation, provider mock, read-only Prisma, concurrency dan disconnect. openapi.test.cjs/requestLogger.test.cjs menangani registrasi dan privasi. Dokumentasi handoff menjelaskan history, loading/error, cold start, sources dan penggantian reply contoh; bukan implementasi Flutter. docs/DECISIONS.md mencatat assistant tidak menerima compare; catatan compare historis dipertahankan dengan status sudah digantikan, bukan dihapus diam-diam. PRD/SUMMARY tidak memerlukan perubahan tujuan produk; FRD/architecture menjelaskan implementasi baru saat apply.

## Risks / Trade-offs

- [Chat hilang setelah restart] Baseline MVP tanpa tabel; histori permanen membutuhkan scope baru dan aturan retensi.
- [History klien dapat diedit] Jangan gunakan sebagai evidence konsumsi/nutrisi, sumber atau otorisasi.
- [Catatan parsial disalahartikan sebagai diet lengkap] Selalu sertakan coverage/unknown/provenance dan batas recorded-only; tidak ada verdict klinis.
- [Corpus referensi kecil] sources kosong bila tidak cocok, jangan membuat angka/sitasi baru. Semantic search ditunda.
- [LLM membuat klaim tanpa dukungan] Prompt terpisah, bukti terstruktur, validasi citation/output dan tes contoh; bukan jaminan semantik prosa.
- [Window terlalu besar] Limit 1000 entri dengan error eksplisit; tidak memotong diam-diam atau mengarang tren.
- [Assistant bersaing dengan scanner] Dua slot bersama, timeout dan no retry; 429 terdokumentasi, tanpa mengaktifkan rate limiter baru.
- [Live provider belum diuji untuk assistant] Tes mock bukan bukti live. Smoke test teks sintetis memerlukan provider lokal siap dan hasil aktual dicatat.

## Migration Plan

Tidak ada migration/seed/env/dependency. Setelah review dan apply terpisah: kontrak+validasi/parser/logger, agregasi/konteks, prompt/service, route/HTTP, dokumentasi dan verifikasi. Pisahkan commit fitur API beserta kontrak/tes dari handoff dokumentasi bila pengguna meminta commit. Rollback revert commit assistant; data konsumsi lama tidak disentuh. Jangan push atau archive tanpa permintaan.
