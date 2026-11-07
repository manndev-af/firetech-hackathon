# Design: Integrasi Fitur Jelajahi Flutter ke Backend API Server

## Context

Lihat `proposal.md` untuk motivasi. Backend `server/` memiliki kontrak route aktif:
- `POST /api/v1/comparisons`: Menerima tepat satu `imageA`, satu `imageB`, dan satu JSON string `metadata` (`a`, `b`, `basis`), mengembalikan objek data perbandingan 8 nutrisi, basis sajian, selisih B-minus-A, sinyal prioritas, dan ringkasan kualitatif personal.
- `POST /api/v1/assistant/messages`: Menerima JSON body `{ mode, message, history }` di mana `mode` bernilai `general` atau `pattern`. Mengembalikan teks jawaban `reply`, `sources`, `warnings`, dan `contextSummary`.

Kedua endpoint ini beroperasi secara *read-only* dari sisi database aplikasi dan bersifat *stateless*.

## Goals / Non-Goals

**Goals:**
- Membuat service `CompareApi` (`app/lib/services/compare_api.dart`) untuk komunikasi multipart dengan `POST /api/v1/comparisons`.
- Membuat service `AssistantApi` (`app/lib/services/assistant_api.dart`) untuk komunikasi JSON dengan `POST /api/v1/assistant/messages`.
- Menghubungkan `CompareScreen` agar memanggil `CompareApi`, menampilkan indikator loading saat inferensi berlangsung, dan merender data komparasi riil backend.
- Menghubungkan `AssistantScreen` agar memanggil `AssistantApi` untuk mode `general` dan `pattern`, mengelola history percakapan sesi (maksimal 5 pasang pesan), dan menangani error tanpa menghilangkan input pengguna.
- Menjaga keandalan dengan pengujian unit dan widget test terisolasi.

**Non-Goals:**
- Tidak mengubah kode backend di `server/` (backend adalah *source of truth*).
- Tidak menyimpan percakapan asisten ke basis data persisten karena backend dan spesifikasi mensyaratkan percakapan hanya hidup di sesi aktif klien.
- Tidak mengusik fitur scanner kamera, jurnal konsumsi harian, atau profil pengguna.

## Decisions

### Decision 1: Penanganan Multipart Multi-File pada CompareApi
- **Keputusan**: Gunakan `http.MultipartRequest` melalui `ApiClient.postMultipart` dengan mendaftarkan file `imageA`, `imageB`, dan form-field string `metadata`:
  ```json
  {
    "a": { "mode": "food", "quantity": 1 },
    "b": { "mode": "food", "quantity": 1 },
    "basis": "per_serving"
  }
  ```
- **Rasional**: Sesuai dengan middleware `compareUpload.ts` pada server yang membaca field biner `imageA` dan `imageB` secara spesifik serta mem-parsing field string `metadata`.

### Decision 2: Model DTO dan Null-Safety Nutrisi
- **Keputusan**: Buat model DTO representasi respons komparasi (`ComparisonResult`, `ComparedNutrientItem`, `ComparisonBasis`) dan respons asisten (`AssistantResponse`, `CitationSource`).
- **Rasional**: Memastikan 8 nutrisi komparatif, selisih B-minus-A, dan status basis di-deserialize dengan aman tanpa mengonversi nilai `null` menjadi angka nol palsu.

### Decision 3: Pengelolaan Sesi Percakapan Asisten
- **Keputusan**: `AssistantScreen` mengelola riwayat chat lokal dalam state widget. Saat mengirim pesan ke server, `history` dibentuk dari maksimal 5 pasang user/assistant yang telah selesai (maksimal 10 bubble, total karakter <= 12000). Mode `pattern` dan `general` dipisahkan sesuai parameter navigasi.
- **Rasional**: Memenuhi batasan schema `server/ASSISTANT_API.md` (maksimal 10 item history, format bergantian user/assistant, validasi code points).

## Risks / Trade-offs

- **[Risk: Latensi inferensi provider AI eksternal (DeepSeek Vision/Chat) hingga 30-45 detik]**
  → *Mitigasi*: Sediakan timeout eksplisit 45 detik, tombol batalkan/coba lagi, dan indikator progres visual informatif ("AI sedang membandingkan kedua pilihan makanan..." atau "Asisten sedang menganalisis...") agar pengguna tidak mengira aplikasi macet.
- **[Risk: Server mengembalikan HTTP 429 SCAN_BUSY akibat kapasitas inference bersama]**
  → *Mitigasi*: Tangkap kode error `SCAN_BUSY` dan tampilkan pesan ramah: *"Server AI sedang memproses analisis lain. Silakan tunggu beberapa detik dan coba lagi."*
- **[Risk: Penolakan foto makanan tidak jelas (HTTP 422 RESCAN_REQUIRED)]**
  → *Mitigasi*: Tangkap pesan error spesifik dari backend dan tampilkan dialog peringatan foto ulang tanpa menghilangkan pilihan yang sudah benar.
