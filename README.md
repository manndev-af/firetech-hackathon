# NutriSee

**Pahami isi makananmu, pilih sesuai prioritasmu.**

NutriSee adalah aplikasi pendukung keputusan nutrisi personal. Pengguna dapat memindai makanan atau label kemasan, melihat kelebihan dan kekurangannya sesuai profil nutrisi, mencatat konsumsi, membandingkan dua makanan, dan bertanya kepada asisten.

Personalisasi menyoroti trade-off sesuai prioritas gula, natrium, protein, kalori, dan keseimbangan. Nilai nutrisi yang belum diketahui tetap ditampilkan sebagai belum tersedia. NutriSee mendukung pemahaman makanan, bukan diagnosis atau pengganti tenaga kesehatan.

## Fitur dan batas implementasi

| Fitur | Perilaku |
|---|---|
| Scanner makanan dan label | Backend menerima gambar, mengambil konteks profil/riwayat/referensi, lalu meminta satu analisis vision. Scan berhasil langsung mencatat konsumsi. |
| Profil nutrisi dan jurnal | Profil tersimpan di MySQL; jurnal mendukung daftar/detail, perubahan jumlah konsumsi, penghapusan, dan ringkasan harian. Perhitungan jumlah memakai fungsi deterministik. |
| Bandingkan makanan | Dua gambar dianalisis bersama. Hasil perbandingan tidak mencatat konsumsi atau disimpan sebagai percakapan. |
| Asisten nutrisi | Mode general memakai preferensi dan referensi; mode pattern menambahkan agregasi catatan tujuh tanggal lokal. Percakapan tidak disimpan di database backend. |
| Audio | Flutter menyediakan TTS untuk ringkasan hasil; backend menyediakan teks, bukan file audio. |

Angka dari foto berstatus estimasi model, sedangkan label merupakan ekstraksi belum terverifikasi. Keduanya bukan pengukuran laboratorium. Referensi edukasi FDA dan Kemenkes membantu penjelasan; referensi tersebut bukan database komposisi setiap makanan.

Backend MVP memakai satu user dummy development, tanpa endpoint login. Jalur domain hanya aktif pada development/test dengan konfigurasi demo. Halaman login Flutter tidak membuktikan autentikasi sudah tersedia. Kontrak API sudah tersedia; keberhasilan demo end-to-end pada perangkat tetap perlu diuji dengan environment yang digunakan.

## Struktur dan teknologi

| Lokasi | Isi |
|---|---|
| [app/](app/README.md) | Aplikasi Flutter/Dart: UI, kamera, ML Kit, penyimpanan lokal, HTTP, dan TTS. |
| [server/](server/README.md) | Backend Node.js/TypeScript, Express, Prisma/MySQL, integrasi DeepSeek atau gateway yang kompatibel, dan retrieval SQL/tag/teks. |
| [docs/](docs/WORKSPACE.md) | Konteks produk, keputusan, arsitektur, dan panduan workspace. |
| [rules/](rules/documentation.md) | Aturan dokumentasi dan UI. |

Rencana ONNX/MobileNet dalam dokumen historis belum menjadi jalur scanner backend saat ini. Rujuk [register keputusan](docs/DECISIONS.md) untuk arah yang berlaku.

## Mulai development

1. Baca [aturan proyek](AGENTS.md) dan [panduan workspace](docs/WORKSPACE.md).
2. Siapkan MySQL dan ikuti [setup backend](server/README.md#prisma--mysql). Simpan konfigurasi di server/.env; jangan commit file tersebut.
3. Ikuti [setup Flutter](app/README.md#menjalankan-aplikasi), lalu arahkan API_BASE_URL ke backend yang digunakan.
4. Periksa Swagger pada /api/docs/ dan JSON OpenAPI pada /api/openapi.json. Host, port, dan prefix mengikuti konfigurasi backend.

## Kontrak integrasi Flutter

- [Scanner, profil, dan jurnal](server/SCANNER_API.md).
- [Perbandingan dua makanan](server/COMPARE_API.md).
- [Asisten nutrisi](server/ASSISTANT_API.md).

OpenAPI backend merupakan kontrak endpoint yang diimplementasikan. [SCAN_API konseptual](docs/SCAN_API.md) menyimpan konteks kontrak frontend terdahulu; gunakan kontrak backend untuk integrasi saat ini.

## Dokumentasi proyek

| Dokumen | Kegunaan |
|---|---|
| [AGENTS.md](AGENTS.md) | Aturan kerja, batas MVP, keamanan, dan git. |
| [CHANGELOG.md](CHANGELOG.md) | Perubahan yang sudah dibuat. |
| [SUMMARY](docs/SUMMARY.md) | Brainstorming dan addendum produk; sebagian isi historis. |
| [PRD](docs/PRD.md) | Tujuan dan ruang lingkup produk. |
| [FRD](docs/FRD.md) | Kebutuhan fungsional dan kriteria penerimaan. |
| [DESIGN](docs/DESIGN.md) | Arahan UI/UX dan riwayat desain. |
| [DECISIONS](docs/DECISIONS.md) | Keputusan aktif, penggantian arah, dan hal terbuka. |
| [Arsitektur](docs/architecture.md) | Tanggung jawab komponen dan alur data. |
| [WORKSPACE](docs/WORKSPACE.md) | Struktur repository dan alur kerja. |
| [Aturan dokumentasi](rules/documentation.md) | Pemeliharaan dokumen dan changelog. |
| [Aturan UI](rules/ui.md) | Panduan implementasi dan review antarmuka. |

Dokumen perencanaan bukan bukti implementasi atau akurasi model. Untuk perilaku aktual, gunakan kode, kontrak API, dan hasil verifikasi yang dicatat.
