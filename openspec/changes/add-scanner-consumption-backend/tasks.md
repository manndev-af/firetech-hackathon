# Tasks

Status: pengguna menyetujui apply beserta revisi seed setelahnya. Implementasi backend dan tes mock/database terisolasi selesai; migration serta seed telah diterapkan pada database lokal pengguna. Password dummy 5–128 karakter dan profil fixture lengkap tanpa null sudah diverifikasi. Live smoke test 8.2 telah dijalankan setelah pengguna mengonfigurasi 9Router dan mengizinkan uji: kedua mode lolos validasi service dengan satu dispatch backend per mode. Tidak ada perubahan `app/`; login tidak termasuk. Progres 28/28; batas uji tercatat di bagian terakhir.

## 1. Kontrak dan keputusan produk

- [x] 1.1 Setelah scope disetujui, catat penggantian arah DEC-004/005/006 serta batas estimasi, satu panggilan DeepSeek, dan scanner sebagai konsumsi di DECISIONS/architecture/PRD/FRD yang relevan; verifikasi tidak ada klaim angka model sebagai data terverifikasi dan arah historis tetap dapat ditelusuri.
- [x] 1.2 Tulis kontrak OpenAPI per route untuk delapan endpoint pada design.md, termasuk multipart, idempotency, source flags, JSON response/error, pagination dan nullable summary; tambahkan mapping seluruh field profil bagian 1a, nilai opsi Flutter, tiga kelompok PATCH dan contoh clear/null; verifikasi contoh valid terhadap schema dan API_PREFIX kustom tetap benar.

## 2. Prisma, migration, dan seed development

- [x] 2.1 Tambahkan User, NutritionProfile, FoodEntry, KnowledgeChunk, ScanRequest beserta FK, unique constraints, Decimal/null fields, dan index owner/time di server/prisma/schema.prisma; NutritionProfile wajib sesuai tabel bagian 1a design.md termasuk identity opsional, pilihan UI, enum AllergyStatus, audio, dan timezone, dengan nama hanya di profile; verifikasi prisma validate, db:generate, serta round-trip semua field dan default berhasil.
- [x] 2.2 Buat migration pertama tanpa reset/destructive SQL; verifikasi migration pada database MySQL development/test terisolasi dan constraint menolak duplicate email serta owner/idempotency key.
- [x] 2.3 Tambahkan server/prisma/seed.ts, wiring prisma.config.ts dan db:seed untuk user email/password hash dari environment (password dummy 5–128 karakter), profil fixture development lengkap dengan 13 field tanpa null sesuai revisi pengguna setelah apply, dan referensi reviewed; verifikasi batas password, seed dua kali tidak menggandakan atau menimpa profil/audio/jurnal, password tidak plaintext, dan production/missing credentials ditolak.
- [x] 2.4 Dokumentasikan environment contoh tanpa rahasia, langkah migrate/generate/seed, batas dummy user, dan struktur baru di server/README.md serta docs/WORKSPACE.md; verifikasi perintah yang didokumentasikan pada database test.

## 3. Pemilik development dan profil

- [x] 3.1 Buat resolver dummy owner dari konfigurasi server dengan guard development/test; verifikasi request gagal saat flag mati, user tidak ada, atau payload/header mencoba mengganti owner, tanpa memanggil provider.
- [x] 3.2 Buat GET/PATCH profile beserta validation/controller/service dengan key dan vocabulary Flutter dari bagian 1a; verifikasi round-trip seluruh field, clear dengan null/empty string, trim dan batas nama 60/usia 1..120/tinggi (0,300]/berat (0,700]/bahan lain 120, enum/array unik, boolean dan timezone invalid, serta larangan mass assignment; sinkronkan profile.openapi.ts dan README.
- [x] 3.3 Implementasikan merge PATCH atomik per field: identity/settings tanpa wajib prioritas, personalization minimal satu prioritas, allergy listed wajib bahan, dan status non-listed membersihkan bahan lama; verifikasi omitted fields utuh, explicit contradictory details ditolak, clear/null bukan nol, serta audio-only update bertahan setelah restart tanpa mengubah profil lain.
- [x] 3.4 Tambahkan tes kontrak backend yang mencerminkan skenario profil Flutter yang sudah ada, termasuk pilihan keseharian berbeda dari pola makan, semua lima prioritas dan delapan alergi, serta kebebasan simpan identity sebelum personalisasi; verifikasi data fixture tetap kompatibel dengan model Dart tanpa mengubah file app/.

## 4. Input scan dan deduplikasi

- [x] 4.1 Tambahkan parsing multipart dan decoder gambar minimum yang diperlukan, validasi byte/pixel/format/metadata, orientation/resize, serta cleanup; verifikasi file valid kedua mode, spoofed MIME, image corrupt, oversized input, field berulang, OCR kosong, dan URL input melalui tes.
- [x] 4.2 Implementasikan fingerprint dan atomic ScanRequest claim/state/tombstone, serta batas concurrency scan; verifikasi concurrency/replay, key berbeda payload, restart setelah dispatch, dan replay setelah delete tidak menghasilkan panggilan provider tambahan atau catatan ganda.
- [x] 4.3 Dokumentasikan limit upload dan perilaku retry/unknown dispatch di scan.openapi.ts dan server/README.md; verifikasi error response cocok dengan contoh OpenAPI dan input invalid menghasilkan nol panggilan provider.

## 5. Retrieval personalisasi

- [x] 5.1 Kurasi koleksi kecil KnowledgeChunk dengan source/version/topik dan izin penggunaan tercatat; verifikasi setiap seed aktif punya sumber yang diperiksa, materi belum ditinjau tidak ikut retrieval, dan tidak ada nilai nutrisi atau referensi yang dibuat-buat.
- [x] 5.2 Buat retrieval profil, ringkasan sebelum konsumsi, maksimal lima entri relevan tujuh hari terakhir, serta maksimal tiga referensi dengan batas konteks; gunakan allowlist priorities/preference/eatingPattern/prefersHalal/allergyStatus/allergies/otherAllergies; verifikasi owner isolation, backdated scan, ranking deterministik, no-match/cold-start, null counts, context truncation, dan tidak terkirimnya nama/usia/tinggi/berat/audio/email/password melalui tes.
- [x] 5.3 Dokumentasikan metode SQL/tag/text retrieval dan trace source IDs tanpa klaim vector search; verifikasi contoh konteks memisahkan fakta profil, riwayat estimasi, referensi reviewed, dan data yang tidak tersedia.

## 6. Satu panggilan DeepSeek dan validasi analisis

- [x] 6.1 Tambahkan HTTP DeepSeek native dengan model vision/environment, timeout, response limit, tanpa retry/tool loop; verifikasi mock transport menerima image pada kedua mode, OCR pada label, dan memanggil provider paling banyak sekali per operasi.
- [x] 6.2 Tulis system prompt food/label dan schema output untuk relevance, identity, portion basis, nutrients nullable, source/uncertainty dan qualitative insight; verifikasi fixtures nonfood, konflik OCR, unit tidak didukung, angka negatif/nonfinite, JSON invalid, citation palsu, dan prompt injection ditolak/ditangani sesuai spec.
- [x] 6.3 Implementasikan validasi semantik label basis dan pemisahan model_estimate/label_extracted_unverified; verifikasi missing value tidak diganti nol, profil tidak mengubah base nutrient, serta konversi botol/serving tanpa rasio ditolak.
- [x] 6.4 Hubungkan POST scan dengan retrieval, provider, dan transaksi simpan FoodEntry/ScanRequest; verifikasi sukses langsung masuk jurnal, timeout/nonfood/output invalid/DB failure tidak membuat konsumsi palsu atau panggilan ulang; sinkronkan OpenAPI dan CHANGELOG sesuai perilaku yang benar-benar selesai.

- [x] 6.5 Tambahkan instruksi system prompt ttsSummary untuk dua mode dalam request DeepSeek yang sama; simpan summary/source pada insight FoodEntry dan dokumentasikan pada OpenAPI scan/detail/quantity. Verifikasi 2-3 kalimat, maksimal 60 kata/450 karakter, plain text, tetap tersedia saat audio off, uncertainty penting tidak hilang, dan tanpa angka total porsi/klaim medis baru; uji fallback template saat hanya summary tidak valid tanpa membatalkan analisis valid atau memanggil provider lagi.

## 7. Jurnal dan kalkulasi porsi

- [x] 7.1 Buat daftar/detail konsumsi dengan pagination, filter owner/date, dan provenance; verifikasi batas halaman, entri pemilik lain, serta serialisasi Decimal dan null, lalu sinkronkan food-entry.openapi.ts.
- [x] 7.2 Buat PATCH quantity memakai baseValue * quantity / baseQuantity dan validasi quantity/unit; verifikasi jumlah pecahan, null, round-trip 1 ke 2 ke 1 tanpa rounding kumulatif, nol/negatif ditolak, serta tidak ada panggilan DeepSeek.
- [x] 7.3 Buat DELETE entry dan tombstone scan; verifikasi summary/retrieval tidak lagi menggunakan konsumsi terhapus dan replay tidak membuat ulang entry; dokumentasikan efek pada insight snapshot lama.
- [x] 7.4 Buat daily summary dengan batas hari timezone IANA, known subtotal/missing count/provenance; verifikasi midnight, DST, empty day, nilai nol versus null, serta koreksi/hapus tercermin; sinkronkan nutrition.openapi.ts dan panduan backend.

## 8. Integrasi dan handoff backend

- [x] 8.1 Jalankan pnpm test, pnpm build, pnpm lint serta tes integrasi MySQL terisolasi dengan provider mock; verifikasi scan food/label, deduplikasi, jumlah porsi, summary, production guard, dan route starter/OpenAPI tetap bekerja.
- [x] 8.2 Setelah akses provider dan pengiriman fixture nonpribadi diizinkan, jalankan smoke test satu request per mode menggunakan model vision yang tersedia; catat model, status, latensi, batas observasi, dan tidak melakukan retry otomatis. Jika akses belum tersedia, laporkan blocker tanpa mengklaim integrasi live lolos.
- [x] 8.3 Serahkan OpenAPI dan contoh request/response food/label/quantity/daily serta profile identity/personalization/audio beserta cara memakai dummy seed kepada tim frontend; sertakan mapping ValueNotifier audio ke audioAnalysisEnabled, kewajiban PATCH hanya field kelompok yang diedit, dan kebutuhan memperbarui copy privasi session-only sebelum integrasi; verifikasi seluruh kontrak tersedia, git diff pekerjaan ini tidak mengubah app/, dan seluruh dokumentasi menjelaskan batas estimasi serta scope development.

## Workflow follow-up

- Handoff frontend juga mencakup penggunaan ttsSummary untuk text-to-speech pada scan_result_screen.dart, bukan membacakan seluruh kelebihan/kekurangan. Implementasi playback tetap pekerjaan tim frontend; backend tidak menghasilkan audio. Review memastikan summary tersedia pada respons koreksi porsi tanpa panggilan LLM baru.

- Pengguna mereview proposal/design/specs/tasks dan dapat menyetujui, mengurangi, atau mengubah scope sebelum apply.
- Setelah implementasi dan pemeriksaan diterima, archive melalui workflow OpenSpec bila diminta. Tidak commit/push otomatis.

## Bukti verifikasi apply awal — 7 November 2026

- `pnpm test` dengan `TEST_DATABASE_URL`: 16 tes lolos, nol gagal/skip. Provider memakai transport mock; gambar/angka fixture sintetis.
- `pnpm build`, `prisma validate`, `pnpm db:generate`, `pnpm db:deploy`, dan OpenSpec strict lolos. `pnpm lint` exit 0: 12 warning, tanpa error.
- Migration/seed/integrasi memakai database MariaDB 10.4.32 terisolasi pada port lokal 3307 melalui provider Prisma MySQL. Oracle MySQL 8 belum diuji. Proses database tes dihentikan sesudah pengujian; database aplikasi tidak disentuh.
- `git diff --check` bersih; tidak ada perubahan tracked/untracked dalam `app/`. Handoff tersedia di `server/SCANNER_API.md`; environment, setup, workspace, keputusan dan changelog diperbarui.
- Task 8.2 tetap terbuka sesuai jawaban pengguna: API key belum tersedia; tidak ada request live DeepSeek, klaim akses vision, latensi atau kualitas analisis nyata. Tidak commit/push/archive otomatis.

## Pemeriksaan akhir sebelum commit revisi — 7 November 2026

- Proposal diperbarui dari status pra-implementasi menjadi scope yang sudah disetujui/diimplementasikan; batas retrieval, sifat referensi FDA, revisi seed dan ide lanjutan yang belum dibangun dijelaskan. Design/specs diselaraskan sebelum checklist ini diperbarui.
- `pnpm test` dengan `TEST_DATABASE_URL`: 18 tes lolos, tanpa gagal/skip, termasuk batas password 5/128, penolakan 4/129, profil fixture lengkap dan integrasi scan dengan provider mock. `pnpm build` lolos; `pnpm lint` exit 0 dengan 12 warning dan tanpa error.
- Migration `202611070001_scanner_consumption` diterapkan pada database lokal yang dikonfigurasi pengguna. Setelah audit memastikan tidak ada konsumsi/request scan, satu user dummy, satu profil dan tiga referensi seed lama dihapus secara terbatas lalu dibuat ulang. Tidak ada reset database menyeluruh atau konsumsi fiktif.
- Verifikasi database lokal: satu user, satu profil dengan 13 field terisi dan nol field null, tiga referensi reviewed. Seed kedua mempertahankan ID, password hash, profil dan jumlah record. `.env` tetap diabaikan Git dan tidak diubah.
- Integrasi terakhir memakai database MariaDB 10.4.32 terisolasi melalui provider Prisma MySQL; proses database tes dihentikan setelah selesai. Oracle MySQL 8 belum diuji.
- Task 8.2 tetap belum dicentang; tidak ada request live DeepSeek. Progres 27/28. Commit diizinkan pengguna dan dipisah menurut fitur; tidak push atau archive.

## Live smoke test setelah konfigurasi 9Router — 7 November 2026

- Pengguna mengizinkan uji live. Endpoint `/v1/models` pada 9Router lokal merespons 200, model konfigurasi `ds/deepseek-v4-flash-vision-exp` terdaftar dengan vision=true. Request generation ke `http://localhost:20128/v1/chat/completions`; kedua response melaporkan model `deepseek-flash` dan finish_reason=stop.
- Food: crop foto nasi/ayam dari aset repo tanpa identitas pribadi, satu dispatch backend, HTTP 200, 7.066 ms, validasi core lolos dan TTS fallback template. Nilai foto tetap estimasi, bukan hasil pengukuran.
- Label: gambar sintetis nonproduk dan raw OCR identik, satu dispatch backend, HTTP 200, 3.330 ms, validasi core lolos; delapan nutrient sesuai angka fixture, TTS dari model.
- Retrieval database aktual berjalan sebelum request: profil allowlist dan tiga referensi tersedia, riwayat nol. Nama/usia/ukuran tubuh/audio/email/password tidak dikirim. Tidak menambah FoodEntry/ScanRequest; konsumsi pengguna tidak diubah.
- Batas observasi: uji live pada service dan retrieval, bukan HTTP multipart/persistensi live, kualitas OCR produk nyata, akurasi nutrisi foto, atau audit retry/fallback internal 9Router. HTTP/persistensi memiliki tes provider mock terpisah. Backend tidak melakukan retry/repair call.
- Task 8.2 kini selesai, progres 28/28. Bagian verifikasi sebelumnya dipertahankan sebagai riwayat. Tidak commit/push/archive otomatis.

## Klarifikasi pro/cons consumer setelah live test

- `data.pros`/`data.cons` diekspos sebagai alias dari analysis.advantages/tradeoffs pada scan/list/detail/quantity. Data lama tidak dimigrasi atau dikirim ulang ke LLM. Frontend tetap memakai preview lokal dan tidak diubah; mapping untuk kartu Kelebihan/Kekurangan dijelaskan di SCANNER_API.md.
- Prompt `scanner-2026-11-v2` memperjelas personalisasi pro/cons berdasarkan profil dan riwayat yang tersedia; summary merangkum satu pro, satu con dan ketidakpastian. Jika model summary invalid, fallback mencoba kalimat insight lengkap sebelum template umum. Hanya satu panggilan provider.
- Tes terbaru: `pnpm test` 10 lolos, satu integrasi dilewati karena TEST_DATABASE_URL tidak diisi; test directory database terisolasi lama tidak tersedia. Mapping respons, fallback yang mengandung fokus/pro/cons, batas summary dan preservasi quantity diuji unit; assertion integrasi alias juga ditambahkan namun tidak diklaim dijalankan pada putaran ini. `pnpm build` lolos; lint exit 0 dengan 12 warning tanpa error. OpenSpec strict dan diff check lolos.
- Service live v2 food HTTP 200/7.811 ms, label HTTP 200/3.038 ms; satu dispatch backend per mode, kedua summary bersumber model dan pro/cons terisi. Tidak menambah jurnal fixture; retry internal 9Router dan akurasi nutrisi tidak diaudit. Bukti lama tetap historis; tidak commit/push/archive otomatis.

## Revisi bahasa TTS untuk orang awam

- Prompt v3 meminta bahasa obrolan sopan dengan sapaan kamu, kata sehari-hari, kalimat pendek dan tanpa jargon/bahasa laporan. Pro/cons juga diarahkan sederhana. Template fallback dipermudah; tidak ada request tambahan atau perubahan frontend.
- OpenAPI, panduan consumer dan design/specs diselaraskan. `pnpm test`: 10 lolos, satu integrasi dilewati tanpa TEST_DATABASE_URL; `pnpm build` lolos. Live test sebelumnya menguji v2, bukan bukti keterbacaan output v3; tidak memanggil provider lagi untuk perubahan kata ini. Record lama tidak diubah.

## Revisi resolusi gambar scanner

- Atas permintaan pengguna, normalisasi food/label menjadi JPEG tepat 544 x 544 dengan contain dan padding putih, orientasi dikoreksi tanpa crop. Raw OCR dan batas upload tetap berlaku. Detail kecil pada label dapat berkurang; penghematan token aktual bergantung pada provider.
- Tes preprocessing menguji kedua mode, downscale/upscale, rasio, padding, JPEG, buffer asli dan OCR. Verifikasi: `pnpm test` 11 lolos, satu integrasi dilewati tanpa TEST_DATABASE_URL; `pnpm build`, OpenSpec strict dan diff check lolos. Tidak ada live provider test baru. OpenAPI, design, handoff dan changelog diperbarui.

## Rekonsiliasi proposal dan handoff Flutter

- Proposal kini secara eksplisit mencatat konfigurasi base URL/9Router, normalisasi 544 × 544, gaya TTS v3 dan mapping consumer, dengan tautan ke SCANNER_API.md. Design/specs diselaraskan untuk base URL dan dimensi gambar yang sudah diterapkan.
- Handoff diperjelas: urutan integrasi, field multipart, mapping screen, delapan key/unit nutrisi nullable, quantity/baseQuantity, daftar entries, snapshot pro/cons/TTS, respons 204/non-JSON serta idempotency/error recovery. Skor/tags/komposisi/favorit dan edit nilai OCR tidak diklaim tersedia.
- Ini pembaruan dokumentasi atas implementasi yang sudah ada, tanpa task backend baru atau perubahan app. Verifikasi dokumentasi: OpenSpec strict, tautan lokal yang disentuh dan diff check; tidak mengulang tes runtime atau live provider. Hasil runtime sebelumnya tetap historis; integrasi Flutter belum dilaksanakan.
