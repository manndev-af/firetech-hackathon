# Functional Requirements Document (FRD)

## NutriLens AI — Personalized Nutrition Decision Support

| Atribut | Nilai |
|---|---|
| Status | Draft untuk MVP hackathon |
| Versi | 1.0 |
| Tanggal | 1 November 2026 |
| Dokumen induk | [PRD.md](PRD.md) |

## 1. Tujuan

Dokumen ini merinci kebutuhan fungsional NutriLens AI, prioritas implementasi, serta kriteria penerimaan untuk membantu tim membangun dan memvalidasi MVP. PRD menjelaskan konteks dan sasaran produk; FRD ini merinci perilaku yang harus disediakan produk.

## 2. Ruang Lingkup Fungsional

### P0 — MVP inti

- Pengguna memilih prioritas nutrisi.
- Pengguna memotret makanan tanpa kemasan dan menerima kandidat klasifikasi.
- Pengguna dapat mengonfirmasi atau mengoreksi jenis makanan.
- Pengguna memilih dan mengonfirmasi porsi.
- Sistem mengambil data nutrisi terpetakan dan menghitung total sesuai porsi.
- Sistem menampilkan insight sesuai prioritas dengan sumber, basis, dan ketidakpastian yang relevan.

### P1 — bila waktu memungkinkan

- Lookup makanan kemasan dengan barcode.
- OCR label nutrisi dengan verifikasi dan koreksi pengguna.
- TTS hasil analisis.
- Riwayat atau perbandingan makanan.

## 3. Kebutuhan Fungsional

| ID | Kebutuhan | Prioritas | Kriteria penerimaan |
|---|---|---|---|
| FR-01 | Pengguna memilih prioritas nutrisi | P0 | Minimal satu prioritas dapat dipilih; pilihan mengubah penekanan insight, bukan nilai nutrisi sumber. |
| FR-02 | Aplikasi menerima foto makanan untuk klasifikasi | P0 | Gambar yang tidak valid atau gagal diproses menghasilkan pesan yang dapat dimengerti. |
| FR-03 | Hasil klasifikasi menunjukkan kandidat dan confidence | P0 | Hasil menampilkan hingga tiga kandidat; prediksi berkeyakinan rendah ditandai sebagai tidak pasti sesuai threshold hasil evaluasi. |
| FR-04 | Pengguna dapat mengoreksi identitas makanan | P0 | Pengguna dapat memilih kandidat lain, mencari makanan manual, atau mengulang foto. |
| FR-05 | Pengguna mengonfirmasi porsi | P0 | Porsi dan satuannya terlihat serta dapat diubah sebelum kalkulasi. Sistem tidak mengklaim mengukur berat otomatis dari foto. |
| FR-06 | Sistem mengambil data nutrisi yang terpetakan | P0 | Data menyertakan sumber dan basis (misalnya per 100 g atau per sajian); jika tidak ditemukan, sistem menyatakan data tidak tersedia. |
| FR-07 | Sistem menghitung total nutrisi secara deterministik | P0 | Kalkulasi mengikuti konversi satuan dan porsi; nilai hilang tetap null/tidak tersedia, bukan nol. |
| FR-08 | Sistem menyusun insight personal | P0 | Insight mengidentifikasi aspek yang mendukung atau tidak mendukung prioritas berdasarkan aturan transparan, tanpa skor universal. |
| FR-09 | Hasil menunjukkan ketidakpastian dan batasan | P0 | Hasil memisahkan prediksi, data referensi, porsi pilihan, serta informasi yang tidak diketahui. |
| FR-10 | Lookup produk kemasan dengan barcode | P1 | Produk yang ditemukan menampilkan sumber dan informasi yang tersedia untuk diverifikasi pengguna. |
| FR-11 | OCR label nutrisi | P1 | Nilai hasil OCR dapat ditinjau dan dikoreksi; basis per sajian/per 100 g dipertahankan. |
| FR-12 | TTS membacakan hasil | P1 | Pengguna dapat memulai dan menghentikan pembacaan hasil yang terlihat. |
| FR-13 | Riwayat atau perbandingan makanan | P1 | Fitur ditambahkan jika alur inti P0 stabil dan waktu tersedia. |
| FR-14 | Pengguna mengatur Nutrition Profile | P0 | Profil menyediakan usia/rentang usia, preferensi makanan, dan beberapa prioritas nutrisi; field opsional dapat dilewati. |
| FR-15 | Pengguna dapat mengisi tinggi/berat badan opsional | P0 | Input bersifat sukarela, kegunaannya dijelaskan, dan kosong tidak menghalangi alur scan; data ini tidak memicu diagnosis atau klaim klinis. |
| FR-16 | Pengguna dapat mencatat alergi secara opsional | P0 | Sistem hanya menandai bahan yang cocok dengan informasi alergen yang tersedia; data tidak lengkap ditandai dan tidak diklaim sebagai pemeriksaan menyeluruh. |

### Status implementasi UI onboarding — 7 November 2026

Alur demo Flutter yang diminta pengguna kini menyediakan dua langkah dan layar selesai: satu fokus Gula/Protein/Natrium/Keseimbangan, preferensi makanan opsional, dan ringkasan pilihan aktual sebelum beranda. Pengguna dapat kembali tanpa kehilangan pilihan dalam alur, atau melewati preferensi sehingga nilainya tidak dipilih. Default visual mengikuti referensi (Gula dan Masakan rumahan). Pilihan belum disimpan atau diterapkan pada engine/dashboard dan kembali ke default ketika alur dibuat ulang. Tombol Google membuka demo ini tanpa autentikasi. Implementasi UI ini belum memenuhi seluruh FR-01/FR-14: Nutrition Profile lengkap, prioritas jamak, Calorie Awareness, penyimpanan, serta pengaruh terhadap insight tetap pekerjaan berikutnya; kebutuhan produk di atas tetap berlaku.

## 4. Alur Fungsional Utama (P0)

1. Pengguna membuka aplikasi dan memilih satu atau lebih prioritas nutrisi: gula, natrium, energi/kalori, protein, atau keseimbangan nutrisi.
2. Pengguna memilih jalur makanan tanpa kemasan dan mengambil foto.
3. Sistem memvalidasi gambar dan mengirimkannya ke backend klasifikasi.
4. Sistem menampilkan hingga tiga kandidat beserta confidence. Jika tidak ada hasil yang layak, pengguna diberi pilihan mengambil foto ulang atau mencari makanan manual.
5. Pengguna memilih atau mengoreksi identitas makanan.
6. Sistem meminta pengguna memilih jumlah/ukuran porsi beserta satuannya. Pengguna dapat mengubah nilai sebelum analisis.
7. Sistem mencari referensi nutrisi untuk makanan yang dikonfirmasi dan menyertakan sumber serta basis nilai.
8. Sistem menghitung nutrisi berdasarkan porsi dengan aturan deterministik.
9. Sistem membandingkan hasil dengan prioritas pengguna dan menampilkan kelebihan, kekurangan, trade-off, serta data yang tidak tersedia.

## 5. Perilaku dan Aturan Sistem

### 5.0 Nutrition Profile

- Profil dapat mencakup usia/rentang usia, preferensi makanan, dan pilihan jamak: Sugar Awareness, Sodium Awareness, Protein Intake, Calorie Awareness, serta Balanced Nutrition.
- Tinggi dan berat badan bersifat opsional. Alergi makanan dapat diisi secara opsional untuk menandai bahan yang perlu diperhatikan. Aktivitas fisik merupakan pengembangan berikutnya.
- Pengguna dapat melewati field opsional dan tetap menggunakan alur scan.
- Profil hanya mengubah fokus penjelasan, perbandingan, dan alternatif yang ditampilkan. Profil tidak mengubah nilai nutrisi asli ataupun kalkulasi sumber.
- Jika bahan atau informasi alergen tidak tersedia, sistem menyatakannya; ketiadaan catatan alergen bukan bukti bahwa makanan bebas alergen.
- Jangan mengumpulkan riwayat penyakit atau obat pada MVP. Tidak ada diagnosis, konsultasi dokter, rekomendasi pengobatan, atau perubahan dosis obat.
- Bila data profil disimpan, tujuan penggunaan, persetujuan, akses, serta retensinya harus dijelaskan dan dibatasi sesuai kebutuhan.

### 5.1 Klasifikasi makanan

- Model mengklasifikasikan jenis makanan saja; tidak mengukur berat, volume, kalori, atau kandungan nutrisi dari gambar.
- Tampilkan maksimum tiga kandidat dan confidence yang dihasilkan model.
- Threshold untuk menandai prediksi berkeyakinan rendah ditetapkan berdasarkan evaluasi model, bukan angka arbitrer.
- Sediakan koreksi manual atau pengambilan gambar ulang ketika hasil tidak sesuai.

### 5.2 Konfirmasi porsi

- Porsi wajib dikonfirmasi pengguna sebelum kalkulasi.
- Satuan harus jelas dan cocok dengan pemetaan yang tersedia, misalnya gram, ml, buah, butir, lembar, atau sajian.
- Konversi satuan hanya dilakukan jika faktor konversinya tersedia dan terdokumentasi.
- Bila konversi tidak diketahui, minta pengguna memilih unit yang dapat dihitung atau nyatakan bahwa kalkulasi tidak tersedia.

### 5.3 Data dan kalkulasi nutrisi

- Setiap data nutrisi harus mempertahankan sumber, basis nilai, ukuran sajian, dan satuan.
- Nilai yang hilang disimpan dan ditampilkan sebagai null/tidak tersedia, bukan nol.
- Kalkulasi harus mempertahankan konsistensi unit dan tidak boleh dilakukan oleh LLM.
- Jika record referensi tidak ditemukan atau hanya cocok sebagian, jelaskan keterbatasannya dan jangan membuat nilai pengganti.

### 5.4 Insight personal

- Insight menyoroti nilai yang relevan dengan prioritas terpilih.
- Aturan harus dapat dijelaskan dan tidak menghasilkan skor universal yang mengabaikan preferensi.
- Insight tidak boleh berupa diagnosis, klaim pencegahan/penyembuhan penyakit, atau instruksi pengobatan.
- Jika LLM digunakan, ia hanya menerima data dan hasil analisis terstruktur; fallback berbasis aturan harus tetap berfungsi.

## 6. Kebutuhan Produk Kemasan (P1)

1. Pengguna memindai barcode produk.
2. Sistem mencari produk melalui sumber seperti Open Food Facts.
3. Sistem menampilkan identitas produk, nilai nutrisi, sumber, dan basis yang tersedia.
4. Pengguna memeriksa informasi dan jumlah sajian sebelum kalkulasi.
5. Jika barcode tidak ditemukan atau data tidak lengkap, aplikasi dapat menawarkan input label melalui OCR atau input manual.
6. Hasil OCR ditampilkan dalam formulir yang bisa dikoreksi pengguna. OCR tidak dianggap sebagai verifikasi otomatis.

## 7. Kebutuhan Hasil dan Kesalahan

- Hasil analisis harus memisahkan identitas makanan yang dipilih, porsi pengguna, nutrisi referensi, nutrisi hasil kalkulasi, prioritas yang dipakai, dan sumber data.
- Nilai atau komponen yang tidak tersedia harus ditandai secara eksplisit.
- Kegagalan kamera, validasi gambar, klasifikasi, pencarian nutrisi, atau OCR harus menghasilkan pesan yang jelas serta tindakan pemulihan yang sesuai.
- Kegagalan layanan LLM tidak boleh menghentikan hasil kalkulasi atau menghapus penjelasan deterministik.
- Aplikasi tidak boleh menampilkan prediksi contoh/demo sebagai hasil model aktual.

## 8. TTS, Riwayat, dan Perbandingan (P1)

- TTS membacakan informasi hasil yang terlihat dan menyediakan kontrol mulai/henti.
- Jika riwayat dibuat, simpan hanya informasi yang diperlukan dan sesuai kebijakan privasi produk.
- Perbandingan dua makanan harus menggunakan basis sajian yang sebanding atau secara eksplisit menampilkan perbedaan basisnya.
- Prioritas nutrisi pengguna memengaruhi sorotan perbandingan, bukan mengubah nilai sumber.

## 9. Kriteria Verifikasi Fungsional

Tim perlu memverifikasi sekurang-kurangnya bahwa:

- Foto yang tidak dapat diproses ditolak dengan pesan yang dapat dipahami.
- Prediksi top-3 dan confidence disampaikan tanpa klaim kepastian yang tidak didukung.
- Koreksi makanan dan perubahan porsi memengaruhi record dan kalkulasi yang digunakan.
- Nilai per 100 g/per sajian dikonversi ke porsi dengan benar.
- Data hilang tidak diperlakukan sebagai nol.
- Sumber, basis, unit, prioritas, dan keterbatasan tampak pada hasil.
- Layanan penjelasan opsional dapat gagal tanpa merusak kalkulasi deterministik.

## 10. Di Luar Ruang Lingkup Fungsional MVP

- Penentuan porsi atau berat otomatis dari satu gambar.
- Diagnosis, resep diet klinis, rekomendasi obat, atau analisis kondisi kesehatan.
- Pengumpulan riwayat penyakit dan obat, konsultasi dokter, atau fitur klinis.
- Interpretasi klinis atas tinggi/berat badan; kedua field hanya opsional dan belum mengubah analisis pada MVP.
- Klaim dampak kesehatan jangka panjang berdasarkan penggunaan aplikasi.
- Autentikasi kompleks, sinkronisasi cloud, atau analitik konsumsi jangka panjang.
