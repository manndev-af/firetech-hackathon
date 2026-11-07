# Tasks

Status: apply disetujui pengguna; task ditandai berdasarkan implementasi dan verifikasi aktual. Frontend dan schema database tetap di luar scope.

## 1. Reuse fungsi scanner tanpa perubahan perilaku

- [x] 1.1 Ekspor decoder/normalisasi gambar dari scanUpload.ts dan tetap gunakan pada readScanInput; verifikasi scanUpload.test.cjs mencakup JPEG/PNG, MIME, file rusak, dimensi dan porsi lama tanpa perubahan kontrak.
- [x] 1.2 Pisahkan transport JSON vision minimum di deepseek.service.ts untuk satu atau dua gambar sambil mempertahankan wrapper scanner; verifikasi nutrition.test.cjs untuk timeout, response limit, malformed/truncated JSON, tidak retry dan satu dispatch scanner.
- [x] 1.3 Sesuaikan tipe input fungsi totals agar menerima struktur angka/Decimal tanpa FoodEntry palsu; verifikasi hasil Decimal, pecahan, nol, null dan basis scanner tetap sama lewat nutrition.test.cjs.
- [x] 1.4 Catat reuse kompatibel pada CHANGELOG saat benar-benar diterapkan; verifikasi pnpm test dan pnpm build, serta jangan klaim integration database berjalan jika dilewati tanpa TEST_DATABASE_URL.

## 2. Upload compare, kontrak dan privasi log

- [x] 2.1 Buat compareUpload.ts dengan imageA/imageB/metadata, mode per pilihan, basis/quantity default dan batas karakter/byte; verifikasi compare.test.cjs menolak file/field hilang/berlebih/berulang, metadata salah, owner override dan nilai di luar batas sebelum dispatch.
- [x] 2.2 Terapkan batas 5 MiB/20 MP per gambar, 11 MiB multipart dan 256 KiB metadata termasuk request tanpa Content-Length; verifikasi tes upload melebihi batas, MIME palsu dan decoding gagal tanpa provider call.
- [x] 2.3 Tandai request compare sebagai payload privat sebelum parsing serta hilangkan body request/response compare dari requestLogger; verifikasi requestLogger.test.cjs untuk sukses dan error upload, OCR/gambar/context/hasil tidak tertulis, sementara logger route lama tetap bekerja.
- [x] 2.4 Tulis compare.openapi.ts dan bagian request/status/privacy server/COMPARE_API.md sebelum route diaktifkan; verifikasi kontrak mencakup tiga field multipart, metadata bersarang, batas, semua status dan contoh null; perbarui FRD/architecture/WORKSPACE/CHANGELOG untuk bagian yang sudah diterapkan.

## 3. Analisis pasangan dan konteks personal

- [x] 3.1 Buat compare.service.ts dengan pembacaan owner/profile/retrieval sekali dan tanpa createScan/write Prisma; verifikasi mock compare.test.cjs menghitung pemanggilan retrieval dan menjadikan setiap percobaan write database sebagai kegagalan tes.
- [x] 3.2 Buat prompt/schema pasangan A/B, dua gambar berpenanda dalam satu dispatch, citation terbatas dan flag raw OCR yang sama; verifikasi provider mock untuk food-food, label-label, food-label, OCR on/off, tidak menukar pasangan dan tanpa nama/email/password pada payload.
- [x] 3.3 Jalankan validasi per item dengan provenance, evidence dan nilai nullable yang sudah ada; verifikasi konflik OCR, koreksi origin image, nutrient null versus nol, status nonfood/uncertain per pilihan dan malformed schema tanpa panggilan repair.
- [x] 3.4 Dokumentasikan provenance, batas satu dispatch dan tidak adanya idempotency/replay/cache di COMPARE_API.md serta CHANGELOG; verifikasi contoh payload/hasil sesuai schema yang digunakan service.

## 4. Normalisasi, selisih dan ringkasan personal

- [x] 4.1 Hitung basis per_serving/per_100g/per_100ml dengan Decimal dan reference yang valid; verifikasi compare.test.cjs untuk porsi berbeda, quantity pecahan, referensi berat/volume, larangan konversi g-ke-ml dan per-100 tidak berubah oleh quantity.
- [x] 4.2 Bentuk comparisonBasis, comparedNutrients dan differences B-minus-A; verifikasi fixture gula A=12/B=6 menghasilkan -6, operand null menghasilkan null, basis unavailable mengosongkan perbandingan dan data asal tetap ada.
- [x] 4.3 Bentuk prioritySignals berdasarkan angka tervalidasi tanpa overall score/winner; verifikasi prioritas gula/protein berlawanan, equal/unknown dan Keseimbangan tanpa bobot atau ranking tersembunyi.
- [x] 4.4 Validasi summary/ttsSummary dan gunakan template lokal saat evidence ditolak, basis unavailable atau audio tidak valid; verifikasi bahasa sederhana, batas 2-3 kalimat/60 kata/450 karakter, tanpa klaim medis/selisih angka dalam narasi dan tanpa call tambahan.
- [x] 4.5 Lengkapi response schema/contoh di compare.openapi.ts dan COMPARE_API.md serta FRD/CHANGELOG sesuai kalkulasi aktual; verifikasi delapan key/unit nullable sama dengan scanner dan contoh angka dihitung oleh tes, bukan klaim akurasi makanan.

## 5. Route HTTP dan handoff frontend

- [x] 5.1 Buat compare.controller.ts dan compare.routes.ts, daftarkan di routes/index.ts dan config/openapi.ts dengan dummy owner serta slot inference bersama; verifikasi compare.test.cjs mencakup HTTP 200/error, kapasitas dua operasi total, slot dilepas setelah provider selesai dan koneksi putus tidak memicu retry.
- [x] 5.2 Perbarui openapi.test.cjs untuk route compare, operationId unik dan API_PREFIX khusus; verifikasi Swagger UI, JSON OpenAPI, respons HTTP aktual serta kontrak scanner tetap tersedia.
- [x] 5.3 Lengkapi COMPARE_API.md dengan contoh multipart/response/error, default basis, null, mapping CompareScreen dan snapshot sesi menuju "Bahas pilihan ini"; verifikasi dokumen tidak mengklaim adanya comparisonId tersimpan, chat API, frontend terhubung atau write konsumsi.
- [x] 5.4 Selaraskan README backend, FRD, architecture, WORKSPACE dan CHANGELOG dengan route final; verifikasi tautan lokal, daftar file dan pemisahan rencana versus implementasi. Jangan mengubah app/** atau server/prisma/**.

## 6. Verifikasi integrasi akhir

- [x] 6.1 Jalankan pnpm test dan pnpm build sesudah integrasi; verifikasi regresi scanner/profile/jurnal/logging/OpenAPI lulus serta laporkan tes database yang dilewati secara eksplisit. Jika TEST_DATABASE_URL terisolasi tersedia, verifikasi compare sukses/gagal tidak mengubah profil, FoodEntry atau ScanRequest di sana.
- [x] 6.2 Lakukan smoke test service memakai dua gambar fixture nonpribadi jika provider lokal siap; verifikasi satu dispatch menerima dua gambar, pasangan/hasil tervalidasi dan tidak menulis database. Bila key/provider belum tersedia, catat belum diuji live dan jangan menandai task ini selesai.
- [x] 6.3 Periksa diff dan validasi OpenSpec strict; verifikasi tidak ada perubahan frontend, Prisma, env, dependency, konsumsi lama atau hasil compare yang tersimpan, lalu update status task berdasarkan hasil nyata.

## Workflow follow-up

- Minta pengguna mereview proposal/design/spec/tasks sebelum apply; jawaban atas pertanyaan desain bukan izin implementasi.
- Jika diminta commit saat apply, pisahkan reuse kompatibel, fitur compare dengan tes/OpenAPI, dan handoff dokumentasi agar rollback jelas; jangan push tanpa permintaan.
- Implementasi Flutter, API asisten, penyimpanan histori compare atau konsumsi dari pilihan memerlukan scope baru.

## Hasil verifikasi - 8 November 2026

- `pnpm test`: 26 tes, 25 lulus, 1 integration database dilewati karena `TEST_DATABASE_URL` terisolasi tidak tersedia. Mock Prisma read-only memeriksa sukses/gagal compare tanpa write; ini bukan bukti integrasi database nyata.
- `pnpm build`: lulus. Swagger UI/assets, JSON OpenAPI dengan API_PREFIX khusus, route HTTP, scanner, profil, jurnal dan logger tercakup suite.
- Smoke test `analyzeComparison` memakai dua gambar label sintetis nonpribadi yang dibuat di memori, tanpa database atau file gambar tersimpan. Provider lokal `ds/deepseek-v4-flash-vision-exp`: satu dispatch, dua gambar, 11.900 ms, status common_basis pada per_100g. Gula A=12/B=6 menghasilkan -6; protein A=4/B=2 menghasilkan -2; data lain yang tidak tersedia tetap null. Ini bukti kompatibilitas satu sampel, bukan metrik akurasi umum.
- Pada smoke test, provider mengembalikan basis sumber 100 g: quantity=1 berarti 1 g untuk field items.nutrients/references; comparedNutrients tetap per 100 g sesuai requested. Frontend wajib membaca unitCode/quantity dan comparisonBasis, bukan menebak porsi dari displayLabel.
- Narasi pasangan yang tidak lolos validasi memakai template lokal; tidak ada retry atau repair call. Tes concurrency memeriksa scanner dan compare berbagi dua slot dan disconnect tidak melepaskan provider yang masih berjalan.
- Tidak ada perubahan app/**, server/prisma/**, env atau dependency. Tidak ada commit/push/archive pada task apply ini.
