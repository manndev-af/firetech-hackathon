# NutriSee — Aplikasi Flutter

Aplikasi mobile NutriSee menangani kamera, OCR lokal, tampilan hasil, profil, riwayat, perbandingan makanan, percakapan asisten, dan TTS. Ringkasan produk ada di [README utama](../README.md); aturan pengembangan ada di [AGENTS.md](../AGENTS.md).

## Menjalankan aplikasi

Jalankan dari folder `app/` dengan Flutter dan perangkat Android yang sudah dikonfigurasi:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Alamat tersebut ditujukan untuk emulator Android yang mengakses backend pada komputer host. Untuk perangkat fisik, gunakan alamat backend yang dapat dijangkau perangkat. Port mengikuti konfigurasi backend.

Konfigurasi terpusat ada di `lib/core/network/api_endpoints.dart`. Urutan pemilihan URL: argumen eksplisit service, `API_BASE_URL`, alias `ANALYSIS_BASE_URL`, lalu `ApiEndpoints.defaultBaseUrl`. Default saat dokumentasi diperbarui adalah `https://nutrisee.manndev.web.id`; ini bukan klaim ketersediaan atau hasil uji layanan tersebut. Gunakan origin backend tanpa menambahkan `/api/v1`, karena path endpoint sudah memuat prefix itu.

API key LLM dan kredensial database hanya berada di backend. Setup MySQL, seed dummy, dan flag demo dijelaskan di [README backend](../server/README.md#scanner-konsumsi-development). Login Google pada UI masih alur demo, bukan autentikasi backend.

## Scanner dan OCR

`ScannerScreen` menangani foto kamera atau galeri, mode Makanan/Label produk, dan deskripsi tambahan. Mode makanan memakai ML Kit sebagai gate lokal; hasil gate bukan pengukuran nutrisi atau bukti akurasi klasifikasi. Kamera tidak merekam audio dan membutuhkan izin perangkat.

Foto dikirim ke `POST /api/v1/scans` melalui multipart dengan UUID pada `Idempotency-Key`. Backend memvalidasi input, mengambil konteks personalisasi, melakukan satu dispatch vision, lalu menyimpan konsumsi jika analisis berhasil. Nilai foto berstatus estimasi model; hasil label adalah ekstraksi belum terverifikasi. Nilai yang tidak terbaca tetap null.

Default `SCANNER_USE_RAW_OCR=false` membuat kegagalan OCR lokal tidak menghalangi pengiriman gambar label. Jika backend diatur menggunakan raw OCR, selaraskan flag Flutter:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=SCANNER_USE_RAW_OCR=true
```

Flag Flutter mengatur kewajiban OCR lokal; flag backend mengatur penggunaan OCR dalam analisis. Saat aktif, OCR gagal/kosong/tanpa kata kunci ditolak sebelum pengiriman. `extractLabel()` hanya parser saran lokal, bukan sumber nilai nutrisi hasil API.

Perubahan quantity memakai PATCH backend dan kalkulasi deterministik tanpa panggilan LLM tambahan. Jangan membuat key scan baru otomatis saat timeout karena dapat mencatat konsumsi lagi. Detail request, respons, error, dan TTS tersedia di [SCANNER_API.md](../server/SCANNER_API.md).

## Profil, jurnal, dan audio

`ProfileApi` menyediakan akses profil; `JournalApi` menyediakan daftar/detail konsumsi, koreksi jumlah, penghapusan, dan ringkasan nutrisi harian. Profil mengatur fokus penjelasan, bukan mengubah nilai nutrisi sumber. Backend MVP memakai satu owner dummy, bukan akun pengguna yang terautentikasi.

Penyimpanan lokal menangani profil, preferensi audio, foto, OCR, draft, dan hasil pada perangkat. Backup cloud Android dinonaktifkan; uninstall atau hapus data aplikasi menghilangkan data lokal. Penyimpanan lokal dan jurnal backend memiliki mekanisme berbeda; ketersediaan endpoint tidak membuktikan seluruh data tersinkron.

TTS memakai suara Indonesia pada perangkat untuk membacakan ringkasan singkat hasil. Backend menyediakan `ttsSummary`; replay audio tidak memerlukan panggilan LLM baru. Ketersediaan suara dan perilaku kamera/OCR perlu diuji pada Android fisik.

## Jelajahi, compare, dan assistant

- Jelajahi membuka pilihan perbandingan dan asisten.
- `CompareScreen` mengirim dua gambar melalui `CompareApi` ke `/api/v1/comparisons`, lalu menampilkan hasil. Perbandingan tidak mencatat konsumsi. Lihat [COMPARE_API.md](../server/COMPARE_API.md).
- `AssistantScreen` memakai `AssistantApi` ke `/api/v1/assistant/messages`. Mode `general` untuk pertanyaan makanan; mode `pattern` untuk pola catatan tujuh tanggal lokal. Riwayat percakapan dikirim client dan tidak dipersistenkan backend. Lihat [ASSISTANT_API.md](../server/ASSISTANT_API.md).

Service dan pemanggilan UI tersedia di repository; verifikasi end-to-end tetap diperlukan pada backend dan perangkat yang digunakan untuk demo.

## Routing dan struktur

Konfigurasi navigasi ada di `lib/core/router/app_router.dart`; path dan nama route ada di `route_paths.dart`. `/home`, `/explore`, `/history`, dan `/profile` berada dalam shell navigasi bawah. `/scan`, `/comparison`, dan `/assistant` membuka alur detail di luar shell. Login dan onboarding merupakan alur terpisah.

| Lokasi | Isi |
|---|---|
| `lib/features/` | Halaman per domain dan widget khusus halaman. |
| `lib/core/network/` | Client HTTP, endpoint, dan konfigurasi base URL. |
| `lib/core/router/` | Konfigurasi navigasi. |
| `lib/core/theme/` | Warna, tipografi, dan tema. |
| `lib/models/`, `lib/services/`, `lib/repositories/`, `lib/providers/` | Data dan logika lintas fitur sesuai struktur yang tersedia. |
| `assets/` | Gambar, ikon, dan font statis. |

Font Inter dibundel di `assets/fonts/` dengan bobot 400/500/600/700 dan lisensi `assets/fonts/OFL.txt`. Gunakan tema global, bukan menetapkan font berulang pada setiap widget. Panduan aset ada di [WORKSPACE](../docs/WORKSPACE.md#aset-statis-flutter).

## Verifikasi dan referensi

```bash
flutter analyze
flutter test
```

Perintah tersebut merupakan panduan pemeriksaan, bukan klaim sudah dijalankan pada pembaruan dokumentasi ini. Tes mock tidak menggantikan pengujian kamera, OCR, TTS, dan koneksi API pada perangkat.

Riwayat desain dan revisi UI ada di [DESIGN](../docs/DESIGN.md) dan [audit Profil/Riwayat](../docs/PROFILE_HISTORY_AUDIT.md). Sasaran produk dan kriteria fitur ada di [PRD](../docs/PRD.md) dan [FRD](../docs/FRD.md). Kontrak frontend terdahulu di [SCAN_API](../docs/SCAN_API.md) merupakan konteks historis; gunakan kontrak backend untuk integrasi aktif.
