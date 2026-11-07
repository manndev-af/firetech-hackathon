# Proposal: Integrasi Service Flutter ke Backend API Server

## Why

Backend Node.js (`server/`) telah mengimplementasikan 8 endpoint REST domain di `/api/v1` (scanner multimodal DeepSeek, profil nutrisi, jurnal konsumsi, dan akumulasi nutrisi harian) yang telah diuji dan didokumentasikan di OpenAPI serta `server/SCANNER_API.md`.

Namun, frontend Flutter (`app/`) saat ini masih bekerja dengan asumsi kontrak fiktif/lokal:
1. Memanggil endpoint yang tidak ada di server (`/api/v1/analysis` dan daftar di `ApiEndpoints`).
2. Mengirim format JSON base64 alih-alih `multipart/form-data` dengan header `Idempotency-Key` untuk pemindaian foto.
3. Hanya mengharapkan kode status HTTP 200, sehingga gagal mengenali `201 Created` dari backend.
4. Memetakan key camelCase (`foodName`, `energyKcal`, dll.) alih-alih snake_case dan skema terstruktur (`title`, `calories_kcal`, `pros`, `cons`, `ttsSummary`).
5. Menggunakan rumus tiruan dan string matching ("yogurt", "nasi", dll.) di `AnalysisContent` untuk lemak, karbohidrat, serat, serta kelebihan/kekurangan, padahal backend sudah menyediakan data 8 nutrisi riil dan personalized pros/cons.
6. Belum menghubungkan sinkronisasi profil, koreksi porsi, penghapusan catatan, dan ringkasan harian ke backend.

Perubahan ini bertujuan menghubungkan Flutter ke backend server secara penuh di mana **Flutter beradaptasi mengikuti kontrak endpoint backend yang sudah ada**.

## What Changes

- **Pembaruan Core Network (`ApiClient` & `ApiEndpoints`)**:
  - Daftarkan endpoint riil backend di `ApiEndpoints`: `/api/v1/scans`, `/api/v1/profile`, `/api/v1/food-entries`, `/api/v1/food-entries/:id`, `/api/v1/food-entries/:id/quantity`, `/api/v1/nutrition/daily`.
  - Lengkapi `ApiClient` dengan dukungan `multipart/form-data` (upload biner file foto), method `PATCH`, `DELETE`, penanganan kode status 201/204, serta ekstraksi amplop `{ success, message, data, timestamp }` dan domain error `{ success: false, data: { code }, message }`.
- **Ekspansi Model `ScanHistoryEntry` & Pemetaan Nutrisi**:
  - Tambahkan field model untuk mendukung 8 nutrisi backend: `totalFatG`, `saturatedFatG`, `carbohydratesG`, `fiberG` di samping `energyKcal`, `proteinG`, `sugarG`, `sodiumMg`.
  - Tambahkan field `pros` (List<String>), `cons` (List<String>), `quantity`, `baseQuantity`, `provenance`, dan `ttsSummarySource`.
  - Tangani nilai null nutrisi secara eksplisit tanpa mengonversinya menjadi nol palsu.
- **Integrasi Scanner Multimodal (`AnalysisApi` & `ScanPipeline`)**:
  - Kirim request pemindaian ke `POST /api/v1/scans` sebagai `multipart/form-data` dengan header `Idempotency-Key` (UUID).
  - Field multipart: `image` (biner JPEG), `mode` (`food` / `label`), `rawOcrText` (wajib di label), `description` (user note opsional), `quantity` (default 1).
  - Terima status `201 Created` (scan baru) dan `200 OK` (replay idempotency).
  - Petakan respons `data` dari backend ke `ScanHistoryEntry`.
- **Pembersihan dan Pembaruan Tampilan Hasil Analisis (`AnalysisContent`)**:
  - Hapus rumus hardcode perkiraan (`_baseFat`, `_baseCarbs`, `_baseFiber`) dan gunakan 8 nutrisi riil dari backend.
  - Hapus teks kelebihan/kekurangan hardcode (`_kelebihanText`, `_kekuranganText`) dan gunakan `pros.join('\n')` serta `cons.join('\n')` dari backend.
  - Hubungkan penyesuaian porsi/quantity ke `PATCH /api/v1/food-entries/:id/quantity` untuk perhitungan ulang deterministik.
- **Sinkronisasi Profil Nutrisi (`ProfileService` & State)**:
  - Hubungkan `GET /api/v1/profile` saat startup untuk menyinkronkan profil dan preferensi audio.
  - Hubungkan `PATCH /api/v1/profile` saat pengguna menyimpan identitas, personalisasi, atau toggle audio `audioAnalysisEnabled`, dengan tetap mempertahankan penyimpanan offline lokal sebagai cache.
- **Sinkronisasi Jurnal Riwayat & Ringkasan Harian**:
  - Hubungkan daftar riwayat ke `GET /api/v1/food-entries?date=...` dengan fallback cache lokal.
  - Hubungkan aksi hapus entri riwayat ke `DELETE /api/v1/food-entries/:id`.
  - Hubungkan ringkasan nutrisi dashboard ke `GET /api/v1/nutrition/daily?date=...`.

## Capabilities

### Modified Capabilities
- `personalized-scan-analysis`: Frontend Flutter kini mengirim request multipart valid dan memetakan respons analisis DeepSeek Vision beserta 8 nutrisi dan insight pros/cons.
- `daily-consumption-journal`: Frontend Flutter menyinkronkan daftar entri konsumsi, koreksi porsi, penghapusan catatan, dan ringkasan harian dengan backend.
- `development-nutrition-identity`: Frontend Flutter menyinkronkan profil pengguna dan preferensi audio dengan backend server.

## Impact

- **Target Proyek**: `app/` (Flutter mobile application).
- **Backend (`server/`)**: Tidak ada perubahan endpoint atau kontrak backend. Backend menjadi acuan tetap (*source of truth*).
- **Kompatibilitas Offline**: Penyimpanan lokal (`LocalStorage`) tetap dipertahankan sebagai mekanisme ketahanan offline dan caching; data tidak hilang saat perangkat offline.
- **Pengujian**: Seluruh unit dan widget test yang ada di `app/test/` disesuaikan agar memverifikasi kontrak endpoint backend riil.
