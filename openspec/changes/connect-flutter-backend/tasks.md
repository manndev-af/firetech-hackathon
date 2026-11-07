# Tasks: Integrasi Service Flutter ke Backend API Server

Daftar tugas implementasi terstruktur untuk menghubungkan frontend Flutter (`app/`) ke endpoint backend Node.js (`server/`) yang telah tersedia.

## 1. Core Network Foundation & Endpoints
- [x] 1.1 Perbarui `app/lib/core/network/api_endpoints.dart` dengan path endpoint riil backend: `/api/health`, `/api/v1/scans`, `/api/v1/profile`, `/api/v1/food-entries`, `/api/v1/food-entries/:id`, `/api/v1/food-entries/:id/quantity`, dan `/api/v1/nutrition/daily`.
- [x] 1.2 Perluas `app/lib/core/network/api_client.dart` untuk mendukung:
  - Request `PATCH` dengan JSON payload.
  - Request `DELETE` dengan penanganan status `204 No Content`.
  - Request `postMultipart` untuk mengunggah file biner foto (`image`) beserta metadata text fields (`mode`, `rawOcrText`, `description`, `quantity`) dan header `Idempotency-Key`.
  - Ekstraksi amplop respons standar backend `{ success, message, data, timestamp }` dan parsing domain error `{ success: false, data: { code }, message }` menjadi `ApiException`.

## 2. Model Data & Pemetaan Nutrisi (`ScanHistoryEntry`)
- [x] 2.1 Perluas model `app/lib/models/scan_history_entry.dart` dengan field tambahan:
  - Nutrisi lengkap 8 metrik: `totalFatG`, `saturatedFatG`, `carbohydratesG`, `fiberG` (di samping `energyKcal`, `proteinG`, `sugarG`, `sodiumMg`).
  - Insight kualitatif: `pros` (List<String>) dan `cons` (List<String>).
  - Porsi & kuantitas: `quantity` (double, default 1.0) dan `baseQuantity` (double?, default 1.0).
  - Metadata backend: `provenance` ('model_estimate' | 'label_extracted_unverified') dan `ttsSummarySource` ('model' | 'template').
- [x] 2.2 Perbarui method `toJson()` dan `fromJson()` pada `ScanHistoryEntry` agar mendukung seluruh field baru dan tetap menjaga kompatibilitas mundur dengan snapshot lokal yang sudah ada.
- [x] 2.3 Buat mapper respons `parseBackendEntry(Map<String, dynamic> data, {String? localPhotoPath})` untuk mengonversi skema `entrySchema` backend (key snake_case `calories_kcal`, `protein_g`, dll.) ke dalam instance `ScanHistoryEntry` secara bersih dan aman terhadap nilai `null`.

## 3. Integrasi Layanan Scanner Multimodal (`AnalysisApi` & `ScanPipeline`)
- [x] 3.1 Refaktor `app/lib/services/analysis_api.dart`:
  - Ubah target URL dari `/api/v1/analysis` menjadi `/api/v1/scans`.
  - Ganti pengiriman JSON base64 dengan pengiriman `multipart/form-data` biner file JPEG dari `draft.photoPath`.
  - Sertakan header `Idempotency-Key` (UUID dari `draft.id`).
  - Kirim field multipart: `mode` ('food' / 'label'), `rawOcrText` (bila label), `description` (user note opsional), dan `quantity` ('1').
  - Terima status `201 Created` (scan baru) dan `200 OK` (replay).
  - Petakan respons `data` menggunakan mapper `parseBackendEntry`.
- [x] 3.2 Pertahankan alur fallback offline: jika perangkat offline atau backend tidak terkonfigurasi/gagal dijangkau, simpan draft lokal agar pengguna dapat mencoba ulang dari Riwayat tanpa kehilangan foto dan catatan.

## 4. Pembaruan Layanan Hasil Analisis & Koreksi Porsi (`AnalysisContent`)
- [x] 4.1 Hapus formula estimasi sintetis hardcode (`_baseFat`, `_baseCarbs`, `_baseFiber`) pada `app/lib/features/scanner/widgets/analysis_content.dart` dan ganti dengan nilai nutrisi riil `entry.totalFatG`, `entry.carbohydratesG`, `entry.fiberG`.
- [x] 4.2 Hapus teks kelebihan/kekurangan hardcode (`_kelebihanText`, `_kekuranganText`) dan ganti dengan rendering dinamis dari `entry.pros.join('\n')` dan `entry.cons.join('\n')` yang dipersonalisasi oleh backend.
- [x] 4.3 Tambahkan integrasi koreksi porsi ke endpoint `PATCH /api/v1/food-entries/:id/quantity`:
  - Saat stepper/chip kuantitas diubah, panggil backend untuk menghitung ulang nutrisi deterministik dari `baseNutrients`.
  - Perbarui tampilan nutrisi secara reaktif berdasarkan entri terbaru yang dikembalikan server.

## 5. Sinkronisasi Dua Arah Profil & Preferensi Audio (`ProfileService`)
- [x] 5.1 Buat service `app/lib/services/profile_api.dart` untuk menangani:
  - `getProfile()`: memanggil `GET /api/v1/profile` untuk mengambil profil aktif dan status `audioAnalysisEnabled`.
  - `patchProfile(Map<String, dynamic> delta)`: memanggil `PATCH /api/v1/profile` untuk memperbarui sebagian field profil (identitas, personalisasi, atau pengaturan audio).
- [x] 5.2 Hubungkan `initializeLocalState` di `app/lib/providers/local_app_state.dart` agar melakukan fetch profil backend saat aplikasi dijalankan, memperbarui `profileSession` dan `analysisAudioSession`, dengan tetap mempertahankan cache offline lokal.
- [x] 5.3 Hubungkan perubahan profil di `NutritionProfileScreen` dan toggle sakelar audio di `ProfileScreen` agar memanggil `patchProfile` ke backend secara asinkron.

## 6. Sinkronisasi Jurnal Riwayat & Ringkasan Harian
- [x] 6.1 Buat service `app/lib/services/journal_api.dart` untuk menangani:
  - `listEntries({String? date, int page, int limit})`: memanggil `GET /api/v1/food-entries`.
  - `deleteEntry(String id)`: memanggil `DELETE /api/v1/food-entries/:id`.
  - `getDailyNutrition({String? date})`: memanggil `GET /api/v1/nutrition/daily`.
- [x] 6.2 Hubungkan `HistoryScreen` agar memuat daftar konsumsi dari backend jika tersedia, dengan opsi sinkronisasi dan fallback ke `historySession` lokal.
- [x] 6.3 Hubungkan penghapusan catatan riwayat di kartu riwayat (`HistoryEntryCard`) agar menghapus dari backend via `DELETE` dan memperbarui state lokal.
- [x] 6.4 Hubungkan Beranda (`DashboardScreen`) agar mengambil akumulasi asupan `DailyNutritionSummary` dari `GET /api/v1/nutrition/daily`.

## 7. Verifikasi & Pengujian Regresi Penuh
- [x] 7.1 Perbarui unit test pada `app/test/local_scan_test.dart` dan `app/test/scanner_screen_test.dart` untuk memverifikasi request multipart `/api/v1/scans`, penanganan status 201/200, dan pemetaan 8 nutrisi serta pros/cons.
- [x] 7.2 Tambahkan unit test untuk `ProfileService` (`GET`/`PATCH /api/v1/profile`) dan `JournalService` (`GET`/`PATCH quantity`/`DELETE /api/v1/food-entries` dan `/api/v1/nutrition/daily`).
- [x] 7.3 Jalankan seluruh suite tes Flutter (`flutter test`) dan pastikan seluruh 71+ pengujian lulus 100% tanpa regresi.
