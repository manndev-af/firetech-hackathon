# Tasks

Status: apply disetujui pengguna; checkbox mengikuti implementasi dan hasil verifikasi nyata. Baseline: general/pattern, chat selama sesi, tanpa compare, tabel baru atau perubahan frontend.

## 1. Kontrak input dan batas request

- [x] 1.1 Buat validation/assistant.ts untuk mode/message/history dan output provider; verifikasi assistant.test.cjs menolak field asing/owner/system/tool/compare/gambar, pesan kosong, urutan pasangan salah serta batas 2000/12000 karakter dan 10 history termasuk Unicode.
- [x] 1.2 Pasang parser JSON assistant 64 KiB sebelum parser global di app.ts, tanpa compressed input; verifikasi HTTP malformed JSON, Content-Type/charset/encoding, oversized/chunked request dan API_PREFIX khusus menghasilkan envelope 400/413/415 tanpa dispatch, sementara parser route lama tetap sama.
- [x] 1.3 Tulis bagian request/status assistant.openapi.ts dan ASSISTANT_API.md sebelum route aktif; verifikasi kontrak mencakup default history kosong, pasangan user/assistant, batas karakter/byte, kedua mode, semua status dan tidak menjanjikan chat persisten.

## 2. Privasi percakapan

- [x] 2.1 Perluas requestLogger agar body request/response dan query assistant dihilangkan sebelum parsing; verifikasi requestLogger.test.cjs untuk sukses/error/parser failure, variasi kapitalisasi/trailing slash, tanpa teks chat/context/sumber privat, serta log scanner/compare tetap berperilaku seperti sebelumnya.
- [x] 2.2 Dokumentasikan privasi, kebutuhan pengiriman teks/preferensi/catatan ke provider dan tidak ada retensi chat aplikasi pada ASSISTANT_API.md/README/CHANGELOG; verifikasi dokumen membedakan log operasional, penyimpanan backend dan kebijakan retensi provider eksternal.

## 3. Konteks personal dan agregasi pola

- [x] 3.1 Implementasikan agregasi tujuh tanggal lokal di assistant.service.ts memakai dayBounds/localDate/summarize/totals; verifikasi assistant.test.cjs untuk midnight/DST, quantity pecahan, null/nol, future exclusion, daily/period totals dan cold start tanpa mengubah fungsi jurnal lama.
- [x] 3.2 Ambil seluruh window owner-scope maksimal 1000 entri, hitung daysWithEntries dan lima kelompok judul tersering beserta kontribusi; verifikasi entri ke-1001 menghasilkan 422 tanpa provider, grouping/count/tie-break deterministik dan tidak memakai lima contoh retrieval sebagai total lengkap.
- [x] 3.3 Reuse getProfile/retrieveContext sekali dan whitelist konteks sesuai general/pattern, dengan budget provider context 64 KiB; verifikasi mock Prisma read-only menghitung panggilan, menolak semua write, mengecualikan identitas dan tidak mengirim jurnal untuk general; pengurangan contoh/referensi tidak mengubah agregasi wajib atau memalsukan sumber terkirim.
- [x] 3.4 Lengkapi struktur contextSummary/patternEvidence dan contoh sintetis di ASSISTANT_API.md serta FRD/architecture; verifikasi tujuh hari, provenance/knownCount/missingCount/complete dan recordedIntakeOnly cocok hasil tes, bukan klaim kecukupan diet.

## 4. Prompt dan service DeepSeek assistant

- [x] 4.1 Buat prompt assistant terpisah untuk general/pattern dan history sebagai data tidak tepercaya; verifikasi provider mock menerima satu payload teks tanpa image/tools/compare, profil allowlist, data pola terhitung, instruksi bahasa Indonesia awam serta larangan kalkulasi baru/diagnosis/angka tanpa sumber.
- [x] 4.2 Hubungkan requestVision tanpa refactor transport baru, max_tokens 2048 dan respons 64 KiB; verifikasi satu dispatch, timeout 45 detik, konfigurasi provider kosong, kegagalan upstream, JSON malformed/truncated/oversized tanpa retry atau repair lewat assistant.test.cjs.
- [x] 4.3 Validasi reply nonblank maksimal 4000 karakter, citationIds unik/allowlist dan bentuk sources/warnings/model/promptVersion dari server; verifikasi output salah/ID asing gagal 502, cold start/referensi kosong/data parsial diberi batas jelas, tidak mengembalikan raw prompt/history/profil dan tidak membuat fake reply ketika provider gagal.
- [x] 4.4 Lengkapi response schema/contoh general/pattern/error di assistant.openapi.ts dan ASSISTANT_API.md; verifikasi contoh dengan schema dan fixture terhitung, sources memakai metadata server, serta catat bahwa schema/prompt bukan jaminan semantik seluruh prosa.

## 5. Route HTTP dan handoff tim Flutter

- [x] 5.1 Buat assistant.controller.ts/assistant.routes.ts dan registrasi routes/index.ts dengan dummy owner serta scanSlot; verifikasi HTTP sukses/error, owner override/demo disabled, kapasitas total dua scanner/compare/assistant, release pada finally dan disconnect tidak melepaskan provider berjalan atau memicu retry.
- [x] 5.2 Daftarkan assistant.openapi.ts di config/openapi.ts dan perbarui openapi.test.cjs; verifikasi Swagger UI/assets, JSON OpenAPI, operationId unik, API_PREFIX khusus dan kontrak scanner/compare/profile/jurnal tetap tersedia.
- [x] 5.3 Lengkapi ASSISTANT_API.md dengan request curl/JSON, response/error, pemilihan history, mapping bubble/loading/retry manual dan shortcut pattern; verifikasi handoff tidak mengklaim Flutter terhubung, memori provider otomatis, TTS, conversationId, histori permanen atau mode compare.
- [x] 5.4 Selaraskan README backend, FRD, architecture, WORKSPACE, DECISIONS dan CHANGELOG dengan perilaku aktual; verifikasi tautan/file, penandaan sejarah compare yang digantikan dan tidak ada perubahan app/**, server/prisma/**, env, dependency atau kontrak lama.

## 6. Verifikasi integrasi akhir

- [x] 6.1 Jalankan pnpm test dan pnpm build setelah integrasi; verifikasi regresi scanner/compare/profile/jurnal/OpenAPI/logging lulus dan mock memeriksa zero writes pada sukses/gagal. Jika TEST_DATABASE_URL terisolasi tersedia, verifikasi data sebelum/sesudah request tetap sama; bila tidak, laporkan integration database dilewati.
- [x] 6.2 Jalankan smoke test service dengan pertanyaan dan konteks sintetis nonpribadi bila provider lokal siap; verifikasi satu dispatch teks, reply/citation tervalidasi dan tanpa write database. Bila key/provider tidak tersedia, laporkan belum live dan biarkan task ini belum selesai; jangan mengubah env pengguna atau memakai data privat untuk tes.
- [x] 6.3 Periksa diff dan jalankan openspec validate add-nutrition-assistant-backend --strict; verifikasi scope general/pattern tanpa tabel/frontend/compare handoff, semua dokumentasi sesuai hasil nyata dan checkbox hanya ditandai setelah implementasi serta pemeriksaannya selesai.

## Workflow follow-up

- Pengguna mereview proposal/design/spec/tasks sebelum meminta apply; pembuatan proposal ini tidak memulai implementasi.
- Histori chat permanen, foto/OCR assistant, TTS dan penghapusan tombol Flutter memerlukan scope terpisah.
- Jika diminta commit, pisahkan fitur API beserta kontrak/tes dari dokumentasi handoff; kerja di main sesuai aturan repository dan jangan push tanpa permintaan.
- Archive hanya setelah implementasi/verifikasi dan permintaan pengguna; jangan mengklaim planning complete sebagai task implementasi selesai.

## Hasil verifikasi - 8 November 2026

- `pnpm test`: 35 tes, 34 lulus, satu integration database dilewati karena TEST_DATABASE_URL terisolasi tidak tersedia. Sukses/gagal HTTP assistant memakai mock Prisma read-only yang menolak write. Ini bukan bukti HTTP/database/provider live bersama.
- `pnpm build`: lulus. Perubahan terakhir pada redaksi query log konsol diperiksa ulang dengan sembilan tes assistant dan build; semuanya lulus. Scanner, compare, profil, jurnal, seed, logger dan Swagger diperiksa pada full suite.
- Smoke test service analyzeAssistant menggunakan pertanyaan/konteks sintetis nonpribadi tanpa akses database. Provider konfigurasi ds/deepseek-v4-flash-vision-exp: general satu dispatch teks, 6030 ms; pattern satu dispatch teks, 2286 ms. Keduanya output/citation tervalidasi, sources kosong sesuai fixture tanpa referensi. Pattern menyebut total gula 6 g yang sudah dihitung backend dari 12 g x quantity 0.5, estimasi dan keterbatasan hari kosong. Bukan pengujian akurasi umum atau bukti seluruh prosa selalu benar.
- ASSISTANT_API.md dan OpenAPI menjelaskan request/response/error, tujuh tanggal, history sesi, privasi, sumber dan mapping Flutter. Tidak ada perubahan app/**, server/prisma/**, env, dependency, prompt scanner/compare atau write konsumsi.
- Tidak melakukan commit, push atau archive pada task apply ini. General/pattern memakai transport/model lama; compare-ke-assistant dikeluarkan sesuai instruksi pengguna.
