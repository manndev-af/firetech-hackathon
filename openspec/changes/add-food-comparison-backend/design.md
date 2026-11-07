# Design

Status: disetujui dan diimplementasikan pada 8 November 2026. Design mencatat pemisahan scanner, transport provider, logging dan registrasi route; hasil verifikasi aktual ada di tasks.md.

## Context

Lihat proposal.md untuk tujuan. CompareScreen saat ini menyimpan dua path foto lokal dan menampilkan ilustrasi; tombol asisten hanya membawa string compare. readScanInput menggabungkan validasi metadata scanner, UUID, satu file dan decoding. callDeepSeek menerima satu gambar dengan prompt scanner. createScan menulis ScanRequest dan FoodEntry. totals memakai Decimal tetapi tipenya masih terkait FoodEntry. Retrieval yang ada sudah menyediakan profil terbatas, subtotal hari ini, maksimal lima riwayat dan tiga referensi dalam konteks terbatas. getProfile dan demoOwner hanya membaca database.

## Goals / Non-Goals

**Goals:** reuse konkret tanpa mengubah kontrak scanner; dua gambar dalam satu dispatch; hasil sesi yang dapat dipahami tim Flutter; perhitungan pasti dengan evidence tetap berstatus belum diverifikasi.

**Non-Goals:** perubahan frontend, chat API, simpan pilihan sebagai konsumsi, database/migration/seed, durable idempotency, cache hasil, model training, dependency atau environment baru.

## Decisions

### 1. Endpoint terpisah dan input eksplisit

POST `{API_PREFIX}/v1/comparisons`, menggunakan dummy owner dan envelope domain yang sudah ada. Sukses HTTP 200, bukan 201 karena tidak membuat resource persisten. Metadata JSON dipilih agar pasangan A/B tidak tertukar dan tidak membutuhkan banyak field datar. Mode eksplisit dipilih daripada menebak tipe input; frontend nanti perlu mengisi mode tiap pilihan.

Multipart: tepat `imageA`, `imageB`, `metadata`. Metadata berisi `a` dan `b`, masing-masing `{mode, description?, rawOcrText?, quantity?}`, serta `basis?`. mode wajib food|label; quantity default 1, positif 0.000001-10000 dengan maksimal enam desimal; description maksimal 1000, rawOcrText maksimal 20000 karakter. basis default per_serving, pilihan per_100g/per_100ml. Tidak menerima owner, consumedAt, nilai nutrisi klien atau URL gambar.

Kedua gambar masing-masing JPEG/PNG maksimal 5 MiB/20 MP, total multipart maksimal 11 MiB, metadata maksimal 256 KiB UTF-8 agar dua OCR multibyte muat; tepat tiga parts, satu field teks, dua file. Pemeriksaan batas tetap berlaku untuk transfer tanpa Content-Length. Decoder memakai kebijakan scanner saat ini: rotasi, JPEG 1600 x 1600, rasio asli, padding putih. Tidak menyimpan file ke disk.

Status kontrak: 200 hasil valid (termasuk basis unavailable dengan penjelasan), 400 metadata/field/OCR wajib tidak valid, 404 demo disabled sesuai middleware, 413 batas upload, 415 content type/MIME/decoder gagal, 422 RESCAN_REQUIRED per pilihan, 429 SCAN_BUSY untuk kapasitas bersama, 502 output/provider gagal, 503 konfigurasi/profile/database tidak tersedia, 504 timeout provider. Semua error memakai envelope domain dan tidak membocorkan stack/provider raw response. OpenAPI saat apply wajib menjelaskan batas dan contoh sukses/null/error serta metadata JSON sebagai string multipart.

### 2. Reuse dengan pemisahan kecil

- Ekspor fungsi decoding/normalisasi gambar dari scanUpload.ts; readScanInput tetap memanggilnya dengan aturan scanner lama. compareUpload.ts menangani dua file dan metadata sendiri. Tidak memakai readScanInput untuk memalsukan UUID scan.
- Ekspor transport JSON vision minimum dari deepseek.service.ts yang menerima messages/payload dan batas keluaran; callDeepSeek scanner tetap menjadi wrapper dengan prompt, budget respons dan validasi lama. Compare memakai timeout 45 detik dan batas respons 256 KiB/8192 max tokens dalam kode, tanpa konfigurasi baru.
- compare.service.ts memiliki prompt/schema pasangan dan menjalankan validateAnalysis per pilihan, menggunakan aturan evidence yang sudah ada. Schema pasangan memuat a/b sesuai analysisSchema, summary kualitatif, ttsSummary dan citationIds; field tambahan ditolak. Tidak mengirim dua callDeepSeek untuk A/B.
- Longgarkan input totals di journal.service.ts menjadi struktur angka/Decimal nullable minimum agar compare bisa menghitung tanpa membuat FoodEntry palsu. Rumus Decimal dan perilaku jurnal tidak berubah. Konversi per-100 serta selisih tinggal di compare.service.ts; tidak membuat engine/factory baru.
- Baca getProfile dan retrieveContext sekali per request dengan waktu sekarang, gabungkan deskripsi serta OCR yang diizinkan. Referensi berbasis teks gambar saja mungkin terbatas; jangan menambah panggilan untuk mengenali makanan sebelum retrieval.
- Pakai slot concurrency scanner yang sama (dua operasi aktif total per proses). Controller compare memakai penanda operasi berjalan dan melepas slot pada finally seperti scanner agar koneksi putus tidak membebaskan operasi provider yang masih berjalan.

Alternatif dua endpoint scanner ditolak karena mencatat konsumsi dan memakai dua dispatch. Menyalin seluruh implementasi transport ditolak karena menduplikasi timeout, batas respons dan validasi error.

### 3. Basis dan output deterministik

Rancangan data respons:

| Field | Isi |
|---|---|
| items.a / items.b | title, mode, quantity, portion, baseNutrients, nutrients, evidence, provenance, pros, cons, warnings |
| comparisonBasis | requested, status common_basis/as_portioned/unavailable, reference per opsi dan alasan keterbatasan |
| comparedNutrients | delapan key/unit yang sama dengan scanner, nullable per opsi, pada basis diminta |
| differences | delapan nilai B-minus-A; null bila operand/basis tidak tersedia |
| prioritySignals | prioritas profil dan arah lower/higher/equal/unknown berdasarkan angka; bukan skor sehat |
| summary / ttsSummary / ttsSummarySource | penjelasan kualitatif dan audio ringkas model/template |
| warnings / model / promptVersion | keterbatasan dan metadata provider; tidak ada ID lookup atau gambar |

Untuk per_serving: gunakan rumus baseNutrient * quantity / baseQuantity. Status common_basis hanya jika massa atau volume sajian aktual kedua opsi sama dan diketahui; jika berbeda/tidak diketahui gunakan as_portioned dengan kedua porsi jelas. Selisih as_portioned tetap per porsi terpilih, bukan per berat sama. Untuk per_100g/ml: normalisasi dari baseQuantity dalam g/ml atau referenceWeightG/referenceVolumeMl yang sesuai; quantity tidak memengaruhi angka per-100. Jangan menghitung kepadatan. Jika salah satu konversi tidak ada, status unavailable dan seluruh comparedNutrients/differences null; data asal tetap tersedia.

Gula/natrium/kalori menyorot arah lebih rendah; protein arah lebih tinggi, tanpa menyatakan lebih rendah/tinggi selalu baik. Keseimbangan tidak diberi ranking numerik atau bobot tersembunyi. Tidak ada persentase otomatis, ambang klinis atau overall winner. Label tetap label_extracted_unverified; foto tetap model_estimate.

### 4. Satu call dan penjelasan

Prompt pasangan memakai penanda A/B sebelum masing-masing gambar dan satu konteks retrieval. Deskripsi/OCR/gambar/referensi tetap data tidak tepercaya. Minta pro/cons serta ringkasan bersifat kualitatif tanpa selisih angka, persentase atau total konsumsi; backend menambahkan angka selisih pada field terstruktur setelah validasi. Koreksi dari gambar harus origin image, bukan kutipan OCR yang direkonstruksi. Citation hanya dari referensi yang disediakan.

Jika nutrisi ditolak atau basis unavailable, ganti narasi pasangan dan audio dengan template keterbatasan; jangan menyatakan pemenang. Summary/audio yang cacat saja tidak menggagalkan hasil valid dan tidak memicu repair call. Jika salah satu identitas/basis inti tidak jelas atau bukan makanan/label, kembalikan 422 RESCAN_REQUIRED dengan penanda A/B; jangan memberikan perbandingan palsu. TTS memakai batas 2-3 kalimat, 60 kata/450 karakter dan bahasa sehari-hari yang sudah berlaku.

### 5. Tanpa persistensi dan batas jaminan

Tidak memanggil createScan atau melakukan write Prisma. Tidak ada ID persisten, GET hasil, replay, idempotency-key wajib atau cache memory. Satu request berarti paling banyak satu dispatch; pengiriman HTTP baru oleh pengguna dapat memicu biaya baru. Tidak menjanjikan exactly-once lintas request/proses. Timeout dan koneksi putus tidak memicu retry otomatis.

Logger saat ini merekam body respons; route compare harus menandai payload privat sebelum parsing upload. requestLogger menghilangkan request/response body compare (termasuk error), menyimpan hanya metadata operasional seperti waktu, method, path, status dan durasi dengan redaksi header yang sudah ada. Jangan log metadata JSON, gambar, context, hasil LLM atau pro/cons compare. Perilaku logger route lain dipertahankan.

Flutter kelak menyimpan respons dalam state sesi dan meneruskannya ke asisten, bukan melakukan lookup comparisonId. Handoff menjelaskan snapshot dari klien tidak otomatis terverifikasi; API asisten belum dibuat dalam change ini. Retensi data oleh provider eksternal mengikuti pengaturannya, bukan jaminan backend tidak menyimpan database.

### 6. File implementasi yang direncanakan

**Baru:**
- server/src/routes/compare.routes.ts
- server/src/routes/compare.openapi.ts
- server/src/controllers/compare.controller.ts
- server/src/middleware/compareUpload.ts
- server/src/services/compare.service.ts
- server/test/compare.test.cjs (input, provider mock, kalkulasi dan HTTP dalam satu file)
- server/COMPARE_API.md (kontrak dan handoff tim Flutter)

**Diubah:**
- server/src/middleware/scanUpload.ts (ekspor decoder; slot dan kontrak scanner tetap)
- server/src/services/deepseek.service.ts (transport bersama; wrapper scanner tetap)
- server/src/services/journal.service.ts (tipe input kalkulasi minimum)
- server/src/middleware/requestLogger.ts (payload compare dihilangkan)
- server/src/routes/index.ts dan server/src/config/openapi.ts (registrasi)
- server/test/nutrition.test.cjs, scanUpload.test.cjs, scanner.integration.test.cjs, openapi.test.cjs, requestLogger.test.cjs (regresi terdampak saja)
- server/README.md, docs/FRD.md, docs/architecture.md, docs/WORKSPACE.md, CHANGELOG.md (perilaku yang sudah diterapkan saat apply)

Tidak mengubah app/**, server/prisma/**, .env/.env.example atau dependency. File baru di luar daftar ini membutuhkan alasan kebutuhan nyata saat review, bukan scaffolding masa depan.

## Risks / Trade-offs

- [Dua gambar menaikkan token/latensi] Batasi upload, output dan concurrency; ukur saat smoke test, tanpa menjanjikan harga/latensi sebelum diuji.
- [LLM salah baca atau menukar A/B] Penanda gambar eksplisit, validasi per item, evidence, null dan fixture dua label berbeda; keberhasilan satu sampel bukan jaminan akurasi umum.
- [Narasi tidak sesuai hitungan akhir] Larang angka selisih dalam narasi, gunakan angka backend dan template saat evidence/basis berubah. Validasi struktural bukan pembuktian seluruh makna narasi.
- [Data sesi hilang setelah aplikasi ditutup] Diterima untuk MVP tanpa penyimpanan; tambah histori hanya lewat scope baru.
- [Refactor memengaruhi scanner] Tes regresi sebelum/sesudah, wrapper lama dan commit terpisah antara reuse, compare dan dokumentasi.
- [Provider tidak mendukung dua gambar] Mock tidak membuktikan kompatibilitas; smoke test dua gambar nonpribadi diperlukan sebelum klaim live.

## Migration Plan

Tidak ada migration database. Setelah approval, pisahkan commit reuse kompatibel, fitur compare beserta tes/OpenAPI, dan handoff dokumentasi. Verifikasi scanner serta Swagger/JSON sebelum mengaktifkan integrasi frontend. Rollback dengan revert commit fitur; data konsumsi lama tidak disentuh. Review lebih lanjut diperlukan sebelum menambah penyimpanan atau chat API.
