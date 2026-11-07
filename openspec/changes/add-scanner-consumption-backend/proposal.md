# Proposal

Status: scope disetujui pengguna dan backend sudah diimplementasikan. Revisi seed setelah apply juga telah disetujui: password dummy minimal 5 karakter dan profil demo lengkap tanpa null. Frontend tetap di luar scope. Verifikasi provider mock dan live smoke test service DeepSeek melalui 9Router telah dijalankan; hasil/batas uji ada di README backend dan tasks.

## Why

Scanner perlu backend yang mengubah foto makanan atau foto label beserta OCR dan deskripsi menjadi catatan konsumsi harian dengan insight personal. Sebelum change ini, backend baru menyediakan starter Express, OpenAPI, dan Prisma MySQL tanpa model domain atau integrasi scanner.

## What Changes

- Tambahkan schema, migration, dan seed idempotent di `server/prisma` untuk user dummy development, profil nutrisi, catatan konsumsi, referensi RAG, dan deduplikasi request scan.
- Selaraskan NutritionProfile dengan seluruh screen profil Flutter: name, age, heightCm, weightKg, preference, priorities, eatingPattern, prefersHalal, allergyStatus, allergies, otherAllergies; sertakan audioAnalysisEnabled dari switch audio yang saat ini terpisah dari model Dart. Timezone tetap metadata backend. Pertahankan validasi UI, field opsional, dan pemisahan update identitas/personalisasi/pengaturan.
- User dummy memiliki email dan password hash; backend memilih user dari konfigurasi development. Tidak ada endpoint login, registrasi, token, atau autentikasi produksi dalam change ini (pilihan pengguna).
- Seed development menerima password 5–128 karakter dan membuat profil fixture lengkap untuk seluruh field, tanpa null. Identitas, ukuran tubuh, prioritas, alergi dan audio fixture adalah contoh fiktif, bukan asumsi tentang pengguna nyata. Seed ulang mempertahankan profil dan jurnal yang sudah ada. Atas permintaan pengguna, record seed lama yang belum memiliki konsumsi/scan dihapus secara terbatas lalu dibuat ulang; tidak ada reset database menyeluruh.
- Tambahkan API versioned untuk profil, scan, daftar/detail konsumsi, koreksi jumlah porsi, penghapusan catatan, dan ringkasan harian. Setiap route memiliki kontrak OpenAPI di samping router.
- Scan menerima gambar pada kedua mode; mode label juga menerima raw OCR. Deskripsi tambahan bersifat opsional. Foto yang valid dan relevan diproses dengan paling banyak satu panggilan DeepSeek Vision untuk satu request scan unik.
- Retrieval SQL mengambil profil aktif, catatan konsumsi sebelumnya, dan referensi terkurasi sebelum request DeepSeek. Sertakan provenance dan kelengkapan data; tidak menambahkan vector database, embedding API, atau panggilan LLM kedua.
- Konteks retrieval mencakup subtotal hari lokal sebelum waktu konsumsi, maksimal lima catatan relevan dalam tujuh hari sebelumnya, dan maksimal tiga referensi reviewed. KnowledgeChunk berisi parafrasa edukasi FDA; isi tidak otomatis berubah mengikuti preferensi. Preferensi/tag dan teks scan menentukan referensi yang dipilih. Riwayat dan referensi dibatasi pada konteks sekitar 8.000 karakter.
- Hasil valid langsung disimpan sebagai konsumsi. Koreksi jumlah porsi menghitung ulang deterministik dari basis tersimpan tanpa panggilan DeepSeek; scan gagal tidak masuk jurnal.
- Tambahkan `ttsSummary` berbahasa Indonesia untuk dibacakan frontend: ringkas, mudah dipahami, fokus pada insight utama dan trade-off. Dihasilkan dalam respons DeepSeek yang sama, disimpan bersama konsumsi, dan tidak memerlukan layanan audio backend atau request LLM tambahan.
- Klarifikasi consumer setelah uji live: respons entry menyediakan `pros`/`cons` sebagai alias advantages/tradeoffs tersimpan untuk kartu Kelebihan/Kekurangan. Prompt meminta hubungan konkret dengan profil/retrieval; `ttsSummary` merangkum pro, cons dan ketidakpastian bagi user, dengan penjelasan nutrisi singkat bila didukung. Fallback mencoba insight yang sama tanpa panggilan provider tambahan. Frontend tetap tidak diubah.
- Tetapkan batas sumber data: angka dari foto adalah estimasi model; ekstraksi OCR/gambar belum otomatis terverifikasi. Nilai hilang tetap null. Personalisasi mengubah insight, bukan nilai sumber.
- Pengguna telah menyetujui perubahan arah DEC-004/005/006 untuk jalur scanner: DeepSeek untuk identifikasi/estimasi, saran satuan dari LLM dengan validasi backend, dan kalkulasi porsi tetap deterministik. Keputusan lama dipertahankan sebagai riwayat di DECISIONS.md.

## Pembaruan implementasi dan handoff Flutter

Rekonsiliasi 7 November 2026; perubahan berikut sudah diimplementasikan, bukan rencana tambahan:

- Konfigurasi provider memakai `DEEPSEEK_BASE_URL`, `DEEPSEEK_API_KEY` dan `DEEPSEEK_MODEL` pada `server/.env`. Backend menambahkan `/chat/completions`, termasuk base path `/v1` untuk 9Router. Flutter hanya menghubungi backend Node.js; key provider tidak dikirim ke aplikasi.
- Gambar food maupun label dinormalisasi backend ke JPEG tepat 544 × 544, orientasi dikoreksi, rasio dipertahankan dengan padding putih tanpa crop. Input tetap JPEG/PNG maksimal 5 MiB/20 MP; total multipart maksimal 6 MiB. Raw OCR label tetap dikirim bersama gambar. Resolusi kecil dapat mengurangi detail label; penghematan token bergantung provider.
- Prompt `scanner-2026-11-v3` memakai bahasa obrolan sopan, sapaan kamu, kalimat pendek dan tanpa jargon untuk TTS. Summary merangkum pro/cons personal serta ketidakpastian dalam 2–3 kalimat, maksimal 60 kata/450 karakter. Fallback lokal tetap tersedia tanpa panggilan provider tambahan.
- Kontrak consumer: `data.title`, `data.analysis.portion`, `data.quantity`, `data.baseNutrients`, `data.nutrients`, `data.pros`, `data.cons`, `data.ttsSummary` dan `data.ttsSummarySource`. Total pada `data.nutrients` sudah dihitung sesuai quantity; nilai null harus tampil sebagai belum diketahui. Koreksi quantity mengembalikan entry terbaru dengan insight/TTS snapshot yang sama.
- Panduan integrasi operasional: [server/SCANNER_API.md](../../../server/SCANNER_API.md#alur-integrasi-flutter), mencakup request multipart, mapping screen, unit nutrisi, idempotency, error recovery dan batas UI yang belum didukung. OpenAPI route-local tetap sumber kontrak lengkap. Endpoint dan frontend tidak berubah dalam rekonsiliasi dokumentasi ini.
- Verifikasi terkini: 11 tes lulus, satu integrasi dilewati tanpa `TEST_DATABASE_URL`; build dan OpenSpec strict lulus pada perubahan resolusi. Live service sebelumnya menguji prompt v2; gaya v3 dan preprocessing 544 × 544 belum diuji live bersama provider.

## Capabilities

### New Capabilities
- `development-nutrition-identity`: seed user/profil development dan resolusi pemilik tetap tanpa login.
- `personalized-scan-analysis`: validasi input, retrieval konteks, satu panggilan multimodal, dan validasi provenance hasil.
- `daily-consumption-journal`: penyimpanan otomatis, deduplikasi request, koreksi porsi, penghapusan, dan ringkasan konsumsi nullable.

### Modified Capabilities
Tidak ada spec OpenSpec yang sudah tersedia.

## Impact

- Area implementasi: `server/prisma`, `server/prisma.config.ts`, konfigurasi/backend services/controllers/routes/validation/types, OpenAPI assembler, package/lockfile, `.env.example`, dan tes backend.
- Dokumentasi implementasi: `server/README.md`, `docs/WORKSPACE.md`, `docs/architecture.md`, `docs/DECISIONS.md`, dokumen produk yang terdampak, dan `CHANGELOG.md`.
- Seluruh `app/` di luar scope; frontend dan ML Kit dikerjakan tim lain. Kontrak backend menjadi bahan handoff.
- Gunakan Express, AJV, Prisma/MySQL, Node test runner yang tersedia; tambahkan parsing multipart dan decoder gambar hanya bila diperlukan. DeepSeek memakai HTTP native. Tidak ada microservice, deployment, training model, atau penyimpanan gambar permanen dalam MVP ini.
- Migration dan seed telah diterapkan pada database lokal yang dikonfigurasi pengguna. Profil seed memiliki 13 field terisi, satu user/profil dan tiga referensi; seed ulang telah diverifikasi tidak menggandakan atau menimpa profil.
- Analisis pola mingguan terstruktur, memori koreksi identitas/porsi dan alternatif personal dari riwayat masih ide lanjutan, belum termasuk change ini. Retrieval tujuh hari saat ini mengambil catatan relevan, bukan membangun fitur analisis pola mingguan tersendiri.
- Status verifikasi rinci dicatat pada tasks setelah pemeriksaan akhir. Live service food/label melalui 9Router lolos; HTTP multipart/persistensi live, integrasi frontend, audit retry internal router serta archive tidak dianggap selesai.
