# Proposal

Status: scope disetujui pengguna dan backend sudah diimplementasikan. Revisi seed setelah apply juga telah disetujui: password dummy minimal 5 karakter dan profil demo lengkap tanpa null. Frontend tetap di luar scope. Verifikasi menggunakan provider mock; live smoke test DeepSeek masih tertunda.

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
- Tetapkan batas sumber data: angka dari foto adalah estimasi model; ekstraksi OCR/gambar belum otomatis terverifikasi. Nilai hilang tetap null. Personalisasi mengubah insight, bukan nilai sumber.
- Pengguna telah menyetujui perubahan arah DEC-004/005/006 untuk jalur scanner: DeepSeek untuk identifikasi/estimasi, saran satuan dari LLM dengan validasi backend, dan kalkulasi porsi tetap deterministik. Keputusan lama dipertahankan sebagai riwayat di DECISIONS.md.

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
- Status verifikasi rinci dicatat pada tasks setelah pemeriksaan akhir. Live DeepSeek, integrasi frontend, serta archive tidak dianggap selesai.
