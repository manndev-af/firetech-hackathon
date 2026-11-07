# Design: Flutter Backend Integration

## Context

Backend Node.js (`server/`) telah menyediakan 8 endpoint REST di `/api/v1` lengkap dengan Swagger/OpenAPI, middleware `demoOwner`, dan integrasi DeepSeek Vision. Panduan integrasi operasional tercantum di `server/SCANNER_API.md`.

Frontend Flutter (`app/`) saat ini masih mengandalkan rute `/api/v1/analysis` fiktif, serialisasi base64 JSON, serta logika tampilan sintetis untuk nutrisi dan pros/cons.

Perubahan ini merestrukturisasi service dan mapper frontend Flutter agar sepenuhnya terhubung ke service endpoint backend yang tersedia, dengan menjaga integritas 71 unit/widget test Flutter yang sudah ada serta ketahanan offline perangkat.

## Goals / Non-Goals

**Goals:**
- Menghubungkan scanner Flutter ke `POST /api/v1/scans` menggunakan multipart/form-data dan Idempotency-Key.
- Memperluas model `ScanHistoryEntry` untuk memetakan seluruh 8 nutrisi snake_case, `pros`, `cons`, dan `ttsSummary`.
- Mengganti teks sintetis hardcode di `AnalysisContent` dengan data analisis riil dari backend.
- Mengintegrasikan koreksi porsi ke `PATCH /api/v1/food-entries/:id/quantity`.
- Mengintegrasikan sinkronisasi profil dan preferensi audio ke `GET`/`PATCH /api/v1/profile`.
- Mengintegrasikan pembacaan riwayat dan ringkasan harian dari `GET /api/v1/food-entries` dan `GET /api/v1/nutrition/daily`.
- Mempertahankan fungsionalitas offline (`LocalStorage`) sebagai fallback saat server tidak terjangkau.

**Non-Goals:**
- Mengubah endpoint atau kode backend (`server/`).
- Menambahkan sistem autentikasi / login multi-user baru (backend menggunakan dummy demo owner terkonfigurasi).
- Menghilangkan local storage / cache offline di Flutter.

## Architecture & Decisions

### 1. Konfigurasi Base URL & Network Foundation

- `ApiEndpoints`:
  ```dart
  abstract final class ApiEndpoints {
    static const apiPrefix = '/api/v1';
    static const health = '/api/health';
    static const scans = '$apiPrefix/scans';
    static const profile = '$apiPrefix/profile';
    static const foodEntries = '$apiPrefix/food-entries';
    static const dailyNutrition = '$apiPrefix/nutrition/daily';
  }
  ```
- Base URL didukung melalui konstanta lingkungan `API_BASE_URL` (atau fallback `ANALYSIS_BASE_URL`) dengan nilai default ramah emulator Android `http://10.0.2.2:3000` (atau `http://localhost:3000` saat debug desktop/test).
- `ApiClient` diperluas dengan method:
  - `patch(String path, {Object? body, Map<String, String> headers})`
  - `delete(String path, {Map<String, String> headers})`
  - `postMultipart(String path, {required File file, required String fileField, required Map<String, String> fields, required Map<String, String> headers})`
  - Menangani ekstraksi amplop backend: `{ success: true, message: "...", data: ..., timestamp: "..." }`
  - Mengonversi status `4xx`/`5xx` dengan JSON `{ success: false, data: { code: "..." }, message: "..." }` menjadi `ApiException(code, message)`.

### 2. Model Data & Pemetaan Nutrisi (`ScanHistoryEntry`)

Model `ScanHistoryEntry` diperluas dengan field:
- `double? totalFatG` (dari `total_fat_g`)
- `double? saturatedFatG` (dari `saturated_fat_g`)
- `double? carbohydratesG` (dari `carbohydrates_g`)
- `double? fiberG` (dari `fiber_g`)
- `List<String> pros` (dari `data.pros` atau `analysis.advantages`)
- `List<String> cons` (dari `data.cons` atau `analysis.tradeoffs`)
- `double quantity` (default 1.0)
- `double? baseQuantity` (default 1.0)
- `String? provenance` ('model_estimate' | 'label_extracted_unverified')
- `String? ttsSummarySource` ('model' | 'template')

Nilai null nutrisi dipertahankan sebagai `null` (ditampilkan sebagai "Belum diketahui" di UI) dan tidak diubah menjadi nol palsu.

### 3. Pemrosesan Scanner (`AnalysisApi`)

Alur pengiriman scan:
1. Flutter mengambil foto dan memvalidasi via ML Kit gate lokal (makanan terdeteksi atau kata kunci OCR ada).
2. `AnalysisApi.analyze()` membuat request multipart ke `POST /api/v1/scans`:
   - Header: `Idempotency-Key: <UUID draft.id>`
   - Field `image`: file JPEG dari `draft.photoPath`.
   - Field `mode`: `draft.label ? 'label' : 'food'`.
   - Field `rawOcrText`: `draft.rawOcrText` (hanya dikirim jika mode label).
   - Field `description`: `draft.note` (jika diisi pengguna).
   - Field `quantity`: `'1'`.
3. Membaca respons dengan status `201 Created` atau `200 OK`.
4. Memetakan respons `data` ke `ScanHistoryEntry` lengkap.
5. Menyimpan hasil ke `localStorage` sebagai cache lokal.

### 4. Tampilan Hasil & Koreksi Porsi (`AnalysisContent`)

- Hapus rumus hardcode perkiraan (`_baseFat`, `_baseCarbs`, `_baseFiber`) dan gunakan nilai nutrisi `entry.totalFatG`, `entry.carbohydratesG`, dan `entry.fiberG`.
- Hapus hardcode `_kelebihanText` dan `_kekuranganText`:
  - Gunakan `entry.pros.isNotEmpty ? entry.pros.join('\n') : ...`
  - Gunakan `entry.cons.isNotEmpty ? entry.cons.join('\n') : ...`
- Stepper kuantitas porsi:
  - Saat porsi diubah, panggil `JournalService.updateQuantity(entry.id, newQuantity)` (`PATCH /api/v1/food-entries/:id/quantity`).
  - Perbarui state entri dengan data hasil kalkulasi deterministik backend.

### 5. Sinkronisasi Profil & Preferensi Audio (`ProfileService`)

- Saat aplikasi diinisialisasi (`initializeLocalState`):
  - Ambil `GET /api/v1/profile` jika backend tersedia.
  - Perbarui `profileSession.value` dan `analysisAudioSession.value` (`data.audioAnalysisEnabled`).
- Saat pengguna menyimpan profil:
  - Kirim `PATCH /api/v1/profile` dengan JSON field kelompok yang diedit:
    - Identitas: `{"name": ..., "age": ..., "heightCm": ..., "weightKg": ...}`
    - Personalisasi: `{"preference": ..., "priorities": [...], "eatingPattern": ..., "prefersHalal": ..., "allergyStatus": ..., "allergies": [...], "otherAllergies": ...}`
    - Audio: `{"audioAnalysisEnabled": true/false}`
  - Tetap simpan salinan ke `LocalStorage` agar aplikasi berfungsi saat offline.

### 6. Sinkronisasi Riwayat Konsumsi & Ringkasan Harian

- Riwayat:
  - Ambil `GET /api/v1/food-entries?date=...` untuk menyinkronkan daftar riwayat.
  - Aksi hapus memanggil `DELETE /api/v1/food-entries/:id` (204 No Content) dan menghapus entri dari `historySession`.
- Dashboard:
  - Ambil `GET /api/v1/nutrition/daily?date=YYYY-MM-DD` untuk menampilkan ringkasan asupan tercatat hari ini dengan metrik kelengkapan.
