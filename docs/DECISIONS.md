# NutriLens AI — Register Keputusan

> Status dokumen: working register, belum menjadi baseline rilis yang disetujui. Catatan ini memisahkan arahan yang ditegaskan pengguna dari rekomendasi dan hal yang masih terbuka.

Baca bersama [SUMMARY.md](SUMMARY.md), [PRD.md](PRD.md), [FRD.md](FRD.md), dan [architecture.md](architecture.md). Keputusan baru ditambahkan saat tim/pengguna menetapkan arahnya. Jangan menafsirkan keberadaan keputusan di sini sebagai bukti fitur telah diimplementasikan.

Catatan migrasi: isi register sebelumnya membahas proyek lain dan tidak dipindahkan karena tidak berlaku untuk NutriLens AI.

## Revisi setelah review pengguna — 7 November 2026

`CONFIRMED_DIRECTION`, integrasi lokal: Object Detection dibantu Image Labeling untuk minuman (persetujuan eksplisit pengguna). Tidak lolos deteksi menghentikan request; pesan menyebut belum terdeteksi, bukan kepastian bukan makanan. OCR dikirim mentah bersama foto yang diperkecil sebagai backup visual. Endpoint belum tersedia: adapter/kontrak disiapkan untuk penyambungan berikutnya. Audio disimpan sebagai teks kesimpulan dan dibacakan ulang oleh TTS lokal, sesuai pilihan pengguna; tidak menyimpan file suara. Semua data aplikasi terkait profil/scan/hasil disimpan lokal, tanpa backend untuk replay. Batas model, nilai awal threshold, dan kontrak ada di [SCAN_API](SCAN_API.md).

Arahan Profil terbaru (`CONFIRMED_DIRECTION`): Lengkapi/Edit profil hanya memuat informasi diri, sedangkan detail personalisasi langsung membuka form yang dapat diedit di halaman yang sama. Drawer/bottom sheet personalisasi dihapus. Form memiliki Simpan dan Kembali di bawah, tanpa langkah Edit tambahan. Implementasi mengelompokkan nama/usia/tinggi/berat sebagai informasi diri dan prioritas/pilihan makanan/alergi sebagai personalisasi.

`CONFIRMED_DIRECTION`: Profil menampilkan ringkasan personalisasi sebelum detail, audio analisis dapat diaktifkan/nonaktifkan, dan Riwayat menampilkan foto serta ringkasan singkat tanpa filter. Pengguna meminta preview tampilan asli tanpa teks demo/ilustrasi. Implementasi memakai build flag terpisah untuk fixture, bukan memasukkannya ke riwayat nyata. Preferensi audio tersedia dalam sesi; integrasi TTS belum selesai. Istilah sumber/basis disederhanakan di detail. Ukuran font disamakan untuk peran teks setara, dengan hierarki judul tetap dipertahankan.

## Konfirmasi perluasan Profil/Riwayat — 7 November 2026

`CONFIRMED_DIRECTION`: pengguna meminta personalisasi selengkap mungkin, termasuk field tambahan opsional, serta preview riwayat berisi. Implementasi UI mencakup tinggi/berat, pola makan/halal, dan pencatatan alergi; penyakit/obat tetap di luar MVP. Referensi gambar hanya digunakan untuk gaya, bukan palet. Scope desain tetap Profil/Riwayat.

Preview menggunakan fixture yang diberi label ilustrasi dan terpisah dari catatan pengguna. Implementasi tetap dalam memori; penyimpanan permanen, penerapan ke engine, dan pemeriksaan alergen tidak dianggap sudah disetujui/selesai melalui perubahan UI ini. Rincian dan bukti tersedia dalam [audit](PROFILE_HISTORY_AUDIT.md).

## Status keputusan

| Status | Makna |
|---|---|
| `CONFIRMED_DIRECTION` | Arah produk/teknis dinyatakan langsung oleh pengguna atau pembaruan konsep terbaru. Tidak otomatis menetapkan detail yang belum dibahas. |
| `DOCUMENTED_DIRECTION` | Arah yang tercatat konsisten di dokumen proyek, tetapi belum ada persetujuan formal atas seluruh rincian. |
| `RECOMMENDED` | Usulan dari brainstorming atau dokumen perencanaan; tim masih dapat memilih alternatif. |
| `OPEN` | Belum ada pilihan final; jangan membuat asumsi implementasi yang tidak dapat dibalik tanpa konfirmasi. |

## Arah yang ditegaskan pengguna

| ID | Keputusan | Dampak dan batas | Status |
|---|---|---|---|
| DEC-001 | NutriLens AI berfokus pada dukungan keputusan dan pemahaman nutrisi personal, bukan diagnosis atau konsultasi medis. | Jangan membuat rekomendasi pengobatan atau perubahan dosis obat. Fitur klinis memerlukan validasi tenaga kesehatan dan perlindungan data yang sesuai. | `CONFIRMED_DIRECTION` |
| DEC-002 | Nutrition Profile memuat usia/rentang usia, preferensi makanan, dan prioritas jamak: Sugar Awareness, Sodium Awareness, Protein Intake, Calorie Awareness, dan Balanced Nutrition. | Tinggi dan berat opsional; alergi opsional untuk menandai bahan berdasarkan data yang tersedia; aktivitas fisik pengembangan berikutnya; penyakit dan obat bukan bagian MVP. | `CONFIRMED_DIRECTION` |
| DEC-003 | Personalisasi memengaruhi fokus penjelasan, perbandingan, dan alternatif, bukan nilai nutrisi asli makanan. | Alergi yang tidak tercatat tidak membuktikan makanan bebas alergen. | `CONFIRMED_DIRECTION` |
| DEC-004 | Nutrition Engine menghitung secara deterministik dari data bersumber; LLM hanya menjelaskan hasil terstruktur. | LLM bukan kalkulator nutrisi atau otoritas medis. Nilai yang tidak tersedia tetap tidak diketahui, bukan nol. | `CONFIRMED_DIRECTION` |
| DEC-005 | Model yang dituju adalah MobileNetV3-Large, training/fine-tuning memakai PyTorch, dengan subset MM-Food-100K. | Model menghasilkan kelas/top-k/confidence saja; tidak mengukur berat, jumlah, porsi, kalori, atau nutrisi secara langsung. | `CONFIRMED_DIRECTION` |
| DEC-006 | Setelah klasifikasi, pengguna mengonfirmasi makanan dan porsinya. | Unit mengikuti kategori makanan dan definisi/konversi berasal dari konfigurasi terstruktur, bukan ditentukan bebas oleh LLM. | `CONFIRMED_DIRECTION` |
| DEC-007 | Sumber nutrisi yang direncanakan: TKPI untuk pangan Indonesia, Open Food Facts untuk produk kemasan, USDA FoodData Central sebagai tambahan bila perlu. | Setiap nilai harus bisa ditelusuri beserta sumber, basis, dan satuannya; kecocokan record tetap perlu diverifikasi. | `CONFIRMED_DIRECTION` |

## Arah yang terdokumentasi atau direkomendasikan

| ID | Arah | Batas status |
|---|---|---|
| DEC-008 | Jalur unpackaged menjadi alur demo utama; packaged food melalui barcode/OCR sebagai tambahan. | Tercermin di PRD P0/P1 saat ini, tetapi penambahan fitur P1 ke demo tetap bergantung waktu dan keputusan tim. |
| DEC-009 | Onboarding sederhana, tombol Scan menonjol, dan navigasi yang dapat mencakup Home, Scan, History, Profile. | Rekomendasi UI/UX dari summary; bentuk navigasi final belum ditetapkan. |
| DEC-010 | Target awal dapat berfokus pada mahasiswa/dewasa muda Indonesia, contoh rentang 18–30. | Segmentasi usulan, bukan batas klinis atau keputusan final. |
| DEC-011 | Eksperimen classifier dapat dimulai kecil dan diperluas setelah baseline; satu usulan terbaru menyebut sekitar 20 kelas/36K gambar. | Ukuran dan pembagian 28K/5K/3K belum disetujui dan harus menunggu audit dataset. |
| DEC-012 | TTS, perbandingan, riwayat, LLM explanation, barcode dan OCR merupakan kandidat fitur tambahan setelah jalur inti stabil. | Provider LLM, urutan, dan inclusion final belum diputuskan. |

## Keputusan terbuka

1. Nama/branding final dan token visual UI.
2. Daftar kelas makanan, ukuran dataset, split, preprocessing final, threshold confidence, dan hasil evaluasi independen.
3. Pemetaan label kelas ke record TKPI yang cocok dan nilai nutrisi yang benar-benar diverifikasi.
4. Satuan, default, rentang, step, serta faktor konversi porsi per makanan.
5. Kegunaan setiap field profil opsional, persetujuan pengguna, penyimpanan, retensi, serta mekanisme menandai alergi yang tidak diketahui.
6. Navigasi dan screen flow akhir, serta fitur P1 yang akan masuk demo.
7. Pemilihan LLM/TTS dan cara menyajikan fallback ketika layanan eksternal gagal.
8. Kontrak API dan penyimpanan data final saat fitur implementasi terkait dimulai.

## Perbedaan versi brainstorming

Summary awal menyebut tinggi/berat bukan syarat MVP; pembaruan konsep terbaru menetapkannya sebagai field opsional, dengan alergi opsional dan tanpa penyakit/obat. Register ini mengikuti pembaruan terbaru sebagai arah konsep, namun kebutuhan, privasi, dan retensi field opsional masih `OPEN`.

Ukuran dataset pernah dibahas sebagai eksperimen 2K/5K, 10K–20K, serta usulan 36K. Semua angka tersebut adalah alternatif/rekomendasi; belum ada pilihan final atau hasil audit yang mengesahkannya.

## Cara memperbarui register

- Tambahkan keputusan baru dengan ID berikutnya, tanggal, pemilik keputusan, alasan, dampak, dan status.
- Jika keputusan berubah, pertahankan riwayat dan catat keputusan pengganti beserta dasar perubahan.
- Rujuk requirement di PRD/FRD dan konsekuensi sistem di architecture; jangan menggandakan seluruh spesifikasi.
- Sinkronkan dokumen yang terdampak sesuai [aturan dokumentasi](../rules/documentation.md).
