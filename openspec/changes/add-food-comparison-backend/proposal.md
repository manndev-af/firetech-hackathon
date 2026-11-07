# Proposal

Status: disetujui pengguna melalui openspec-apply-change dan diimplementasikan pada 8 November 2026. Verifikasi aktual tercatat di tasks.md; frontend dan API asisten tetap di luar scope.

## Why

CompareScreen saat ini menerima dua foto tetapi menampilkan angka dan ringkasan ilustrasi. Backend scanner sudah mampu memvalidasi gambar, membaca nutrisi dengan vision dan mengambil konteks personal, tetapi createScan otomatis mencatat konsumsi sehingga tidak cocok untuk eksplorasi pilihan makanan.

## What Changes

- Tambahkan POST /api/v1/comparisons: dua gambar, metadata per pilihan, satu dispatch DeepSeek vision, respons perbandingan personal tanpa menyimpan hasil.
- Gunakan ulang decoding/preprocessing gambar, transport provider, validasi nutrisi/evidence, profil/retrieval dan aritmetika Decimal melalui pemisahan fungsi minimum. Pertahankan kontrak serta perilaku scanner.
- Hitung normalisasi basis dan selisih delapan nutrisi di backend. Nilai tidak diketahui tetap null; basis berbeda ditampilkan eksplisit tanpa mengarang konversi g/ml.
- Hasil memuat pilihan A/B, basis, selisih, sorotan prioritas, ringkasan kualitatif, keterbatasan dan ttsSummary. Narasi model tidak menjadi sumber angka selisih atau pemenang mutlak.
- Baca profil, riwayat dan referensi RAG satu kali; tidak menulis FoodEntry, ScanRequest, profil, atau total harian. Tidak ada tabel, migration, seed atau cache hasil compare.
- Sediakan OpenAPI serta handoff Flutter untuk hasil sementara dan konteks "Bahas pilihan ini". Implementasi frontend dan API percakapan asisten tidak termasuk change ini.
- Tidak menambah autentikasi, dependency, API riwayat compare, retry provider otomatis atau endpoint simpan konsumsi dari hasil compare.

## Capabilities

### New Capabilities

- `personalized-food-comparison`: analisis dua gambar tanpa persistensi, perbandingan berbasis nutrisi nullable dan konteks personal, serta handoff hasil sesi.

### Modified Capabilities

Tidak ada. Inventori durable specs saat proposal dibuat masih kosong; change scanner yang sudah ada menjadi rujukan kompatibilitas, bukan target perubahan perilaku.

## Impact

- Baru: controller, route/OpenAPI, middleware upload, service dan tes compare. Daftar file pasti dan batas refactor ada di design.md.
- Diubah seperlunya: fungsi bersama di scanUpload.ts dan deepseek.service.ts, perhitungan reusable di journal.service.ts, route registry, OpenAPI assembler dan tes regresi.
- Dokumentasi saat apply: server/COMPARE_API.md, README backend, FRD, architecture, WORKSPACE dan CHANGELOG. Dokumen tersebut belum diubah dalam tahap proposal.
- Tanpa perubahan app/**, server/prisma/**, kontrak HTTP scanner, environment baru atau kredensial provider. Konfigurasi DeepSeek dan dummy owner yang sudah ada tetap digunakan.
