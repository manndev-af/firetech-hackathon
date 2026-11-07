# Proposal: Integrasi Fitur Jelajahi Flutter ke Backend API Server

## Why

Backend Node.js (`server/`) telah menyediakan endpoint perbandingan makanan `POST /api/v1/comparisons` (`server/COMPARE_API.md`) dan percakapan nutrisi asisten AI `POST /api/v1/assistant/messages` (`server/ASSISTANT_API.md`) yang telah diuji, tervalidasi skemanya, dan didokumentasikan di OpenAPI.

Namun pada aplikasi Flutter (`app/lib/features/explore/`), kedua alur utama fitur Jelajahi masih menggunakan data lokal sintetis tiruan:
1. `CompareScreen` saat ini hanya memvalidasi makanan di lokal lalu menampilkan ringkasan data nutrisi statis hardcode tanpa memanggil endpoint `POST /api/v1/comparisons`.
2. `AssistantScreen` saat ini menggunakan dummy generator lokal `_generateReply` berbasis string matching sederhana tanpa memanggil endpoint `POST /api/v1/assistant/messages`.

Perubahan ini bertujuan menghubungkan fitur Jelajahi Flutter ke backend server secara penuh di mana **Flutter beradaptasi mengikuti kontrak endpoint backend yang sudah ada** tanpa mengubah server.

## What Changes

- **Pembaruan Endpoint Jaringan (`ApiEndpoints`)**:
  - Tambahkan path endpoint `ApiEndpoints.comparisons = '$apiPrefix/comparisons'` dan `ApiEndpoints.assistantMessages = '$apiPrefix/assistant/messages'`.
- **Service API Integrasi Jelajahi**:
  - `CompareApi`: Mengirim request `POST /api/v1/comparisons` menggunakan multipart form data berisi tepat satu `imageA`, satu `imageB`, dan JSON string `metadata` (`a`, `b`, `basis: "per_serving"`). Memetakan respons sukses HTTP 200 (`items.a/b`, `comparisonBasis`, `comparedNutrients`, `differences`, `prioritySignals`, `summary`, `ttsSummary`) dan menangani kode status error (400, 413, 422 `RESCAN_REQUIRED`, 429, 502, 504).
  - `AssistantApi`: Mengirim request `POST /api/v1/assistant/messages` menggunakan JSON body berisi `mode` (`general` atau `pattern`), `message` (teks non-kosong, maks 2000 karakter), dan `history` (maksimal 5 pasang pesan user/assistant terakhir yang valid, total teks <= 12000 karakter). Memetakan balasan `reply`, `sources`, `warnings`, dan `contextSummary`.
- **Integrasi Antarmuka Perbandingan (`CompareScreen`)**:
  - Mengirim kedua foto terverifikasi ke `CompareApi` saat pengguna mengetuk *"Lihat ringkasan"*.
  - Menampilkan loading progress state yang informatif selama proses inferensi berlangsung (timeout 45 detik).
  - Menampilkan hasil nutrisi riil dari backend (8 nutrisi komparatif, selisih B-minus-A, sinyal prioritas personal, ringkasan trade-off, dan tombol TTS audio bila tersedia).
  - Menangani error jaringan atau penolakan foto dengan dialog yang jelas dan opsi mencoba ulang.
- **Integrasi Antarmuka Asisten Nutrisi (`AssistantScreen`)**:
  - Menghubungkan pengiriman pesan pengguna ke `AssistantApi.sendMessage()`.
  - Mendukung inisialisasi mode `general` (konsultasi nutrisi dengan referensi resmi) dan `pattern` (analisis kebiasaan makan 7 hari terakhir dari jurnal riil).
  - Menampilkan bubble chat dinamis, indikator loading mengetik/berpikir, penanganan error jaringan tanpa menghilangkan draf pengguna, dan pencegahan pengiriman ganda selama request aktif.
- **Pengujian Terpadu**:
  - Unit test terisolasi untuk `CompareApi` dan `AssistantApi` menggunakan mock HTTP client.
  - Widget test untuk alur interaksi `CompareScreen` dan `AssistantScreen` yang memvalidasi integrasi API, loading state, dan error handling.

## Capabilities

### New Capabilities
- `flutter-explore-integration`: Frontend Flutter menghubungkan antarmuka Jelajahi (`CompareScreen` dan `AssistantScreen`) ke endpoint REST backend server (`POST /api/v1/comparisons` dan `POST /api/v1/assistant/messages`) dengan mengikuti kontrak schema backend `server/` secara ketat.

## Impact

- **Target Proyek**: `app/` (Flutter mobile application).
- **Backend (`server/`)**: Tidak ada perubahan endpoint atau kontrak backend (backend adalah *source of truth*).
- **Ketahanan Jaringan**: Penanganan timeout 45 detik, loading state interaktif, dan dialog peringatan saat server sibuk (429) atau koneksi terputus.
- **Pengujian**: Seluruh suite tes unit dan widget Flutter di `app/test/` dipastikan tetap 100% lulus tanpa regresi.
