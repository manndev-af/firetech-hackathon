# Proposal

## Why

Scanner perlu backend yang mengubah foto makanan atau foto label beserta OCR dan deskripsi menjadi catatan konsumsi harian dengan insight personal. Backend saat ini baru menyediakan starter Express, OpenAPI, dan Prisma MySQL tanpa model domain atau integrasi scanner.

## What Changes

- Tambahkan schema, migration, dan seed idempotent di `server/prisma` untuk user dummy development, profil nutrisi, catatan konsumsi, referensi RAG, dan deduplikasi request scan.
- Selaraskan NutritionProfile dengan seluruh screen profil Flutter: name, age, heightCm, weightKg, preference, priorities, eatingPattern, prefersHalal, allergyStatus, allergies, otherAllergies; sertakan audioAnalysisEnabled dari switch audio yang saat ini terpisah dari model Dart. Timezone tetap metadata backend. Pertahankan validasi UI, field opsional, dan pemisahan update identitas/personalisasi/pengaturan.
- User dummy memiliki email dan password hash; backend memilih user dari konfigurasi development. Tidak ada endpoint login, registrasi, token, atau autentikasi produksi dalam change ini (pilihan pengguna).
- Tambahkan API versioned untuk profil, scan, daftar/detail konsumsi, koreksi jumlah porsi, penghapusan catatan, dan ringkasan harian. Setiap route memiliki kontrak OpenAPI di samping router.
- Scan menerima gambar pada kedua mode; mode label juga menerima raw OCR. Deskripsi tambahan bersifat opsional. Foto yang valid dan relevan diproses dengan paling banyak satu panggilan DeepSeek Vision untuk satu request scan unik.
- Retrieval SQL mengambil profil aktif, catatan konsumsi sebelumnya, dan referensi terkurasi sebelum request DeepSeek. Sertakan provenance dan kelengkapan data; tidak menambahkan vector database, embedding API, atau panggilan LLM kedua.
- Hasil valid langsung disimpan sebagai konsumsi. Koreksi jumlah porsi menghitung ulang deterministik dari basis tersimpan tanpa panggilan DeepSeek; scan gagal tidak masuk jurnal.
- Tambahkan `ttsSummary` berbahasa Indonesia untuk dibacakan frontend: ringkas, mudah dipahami, fokus pada insight utama dan trade-off. Dihasilkan dalam respons DeepSeek yang sama, disimpan bersama konsumsi, dan tidak memerlukan layanan audio backend atau request LLM tambahan.
- Tetapkan batas sumber data: angka dari foto adalah estimasi model; ekstraksi OCR/gambar belum otomatis terverifikasi. Nilai hilang tetap null. Personalisasi mengubah insight, bukan nilai sumber.
- Proposal ini meminta review perubahan arah DEC-004/005/006: DeepSeek untuk identifikasi/estimasi, saran satuan dari LLM dengan validasi backend, dan kalkulasi porsi tetap deterministik. Persetujuan implementasi harus mencakup perubahan arah ini; proposal bukan klaim bahwa keputusan lama telah diganti.

## Capabilities

### New Capabilities
- `development-nutrition-identity`: seed user/profil development dan resolusi pemilik tetap tanpa login.
- `personalized-scan-analysis`: validasi input, retrieval konteks, satu panggilan multimodal, dan validasi provenance hasil.
- `daily-consumption-journal`: penyimpanan otomatis, deduplikasi request, koreksi porsi, penghapusan, dan ringkasan konsumsi nullable.

### Modified Capabilities
Tidak ada spec OpenSpec yang sudah tersedia.

## Impact

- Implementasi yang diusulkan: `server/prisma`, `server/prisma.config.ts`, konfigurasi/backend services/controllers/routes/validation/types, OpenAPI assembler, package/lockfile, `.env.example`, dan tes backend.
- Dokumentasi implementasi: `server/README.md`, `docs/WORKSPACE.md`, `docs/architecture.md`, `docs/DECISIONS.md`, dokumen produk yang terdampak, dan `CHANGELOG.md`.
- Seluruh `app/` di luar scope; frontend dan ML Kit dikerjakan tim lain. Kontrak backend menjadi bahan handoff.
- Gunakan Express, AJV, Prisma/MySQL, Node test runner yang tersedia; tambahkan parsing multipart dan decoder gambar hanya bila diperlukan. DeepSeek memakai HTTP native. Tidak ada microservice, deployment, training model, atau penyimpanan gambar permanen dalam MVP ini.
- Tahap saat ini hanya menghasilkan artifacts OpenSpec. Schema/seed, dependency, database, dan kode runtime belum diubah sampai pengguna menyetujui tasks.
