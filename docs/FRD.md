# Functional Requirements Document (FRD)

> Addendum scanner backend, 7 November 2026: POST scan valid langsung menyimpan konsumsi. Kedua mode menerima gambar; mode label wajib raw OCR. Request yang sama dideduplikasi per owner/idempotency key dan tidak mengulang provider setelah uncertain dispatch. Profil mengikuti seluruh field UI termasuk identity opsional, prioritas jamak, preferensi tunggal, pola makan, halal, alergi tiga status dan audio. Identity/audio dapat diperbarui tanpa prioritas; simpan personalisasi wajib minimal satu. Koreksi quantity mempertahankan null serta basis asli; daily summary memperlihatkan known/missing counts dan timezone. Respons menyertakan ttsSummary singkat pada panggilan yang sama. Estimasi foto dan label extraction dibedakan dari data terverifikasi. Bagian historis ONNX/konfirmasi-sebelum-jurnal di bawah tidak menjadi kontrak scanner baru; kontrak endpoint aktual ada di OpenAPI backend. Integrasi UI belum termasuk.

## NutriLens AI — Personalized Nutrition Decision Support

| Atribut | Nilai |
|---|---|
| Status | Draft untuk MVP hackathon |
| Versi | 1.0 |
| Tanggal | 1 November 2026 |
| Dokumen induk | [PRD.md](PRD.md) |

## 1. Tujuan

Pembaruan integrasi lokal (7 November 2026): pengguna mengonfirmasi Object Detection + Image Labeling untuk gate foto makanan/minuman, OCR mentah + foto terkompresi sebagai input backend, serta teks kesimpulan tersimpan untuk replay TTS lokal. Gate negatif/gagal tidak mengirim request; mode label tidak memakai gate objek. Profil/audio/draft/riwayat bertahan di storage lokal. Hasil backend disimpan otomatis; kesimpulan pendek dibacakan hanya ketika preferensi audio aktif, sedangkan replay merupakan tindakan manual. Foto yang dipindai tidak otomatis dianggap konsumsi. Kontrak, error, batas model, dan status backend belum tersedia tercatat di [SCAN_API](SCAN_API.md). Ini menggantikan status session-only dan hasil scan contoh pada catatan lama.

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

### Status implementasi UI dashboard — 7 November 2026

Dashboard menampilkan empty state selama belum diberi ringkasan catatan. Widget riwayat menerima `DailyNutritionSummary` yang sudah dihitung dari catatan terkonfirmasi; menampilkan jumlah catatan, gula/protein/energi, dan status data yang belum lengkap. Null tidak diganti nol, dan angka contoh prototipe tidak diisikan ke aplikasi. Adapter riwayat/scan belum tersedia, sehingga route Home saat ini tetap memakai state kosong. Tombol scan memberi pemberitahuan fitur belum tersedia; Buka Jelajah dan tab Jelajahi membuka halaman Jelajah. Perbandingan meminta dua gambar galeri sebelum menampilkan ringkasan, tetapi gambar belum diunggah atau dianalisis. Nilai ringkasan hanya ilustrasi dari desain; tidak ada lookup, kalkulasi atau catatan makanan terhubung. Pintasan pola catatan menampilkan percakapan contoh; Tanya soal makanan membuka Asisten tanpa chat. Tidak ada layanan chat/LLM yang terhubung. Empat tab shell adalah Beranda, Jelajahi, Riwayat, dan Profil; halaman detail tampil di luar shell. Fokus onboarding hanya diteruskan ke label kartu melalui route extra; belum merupakan profil tersimpan atau input engine. UI ringkasan bukan bukti FR-07/FR-13 atau kamera sudah selesai. Fokus harus berasal dari pilihan pengguna; akses langsung tanpa pilihan menampilkan Belum dipilih.

## 4. Alur Fungsional Utama (P0)

### Revisi interaksi Profil/Riwayat — 7 November 2026

Revisi Profil terbaru: pengguna dapat menyimpan informasi diri tanpa memilih prioritas nutrisi. Edit profil hanya mengubah nama/usia/tinggi/berat; personalisasi hanya mengubah prioritas/pilihan makanan/alergi. Lihat detail langsung menampilkan input editable inline, tanpa modal dan langkah edit kedua. Simpan menerapkan bagian aktif, Kembali membatalkan dengan konfirmasi bila draft berubah, lalu tampilan kembali ke ringkasan. Pengujian memastikan bagian lain tetap utuh dan form dapat digunakan pada 320 px dengan skala teks 2.

Pembaruan setelah permintaan contoh: route Riwayat menampilkan fixture secara default agar pengguna dapat langsung meninjau foto, ringkasan, dan detail. Flag `UI_PREVIEW=false` mematikan contoh; state kosong dan pengecualian fixture dari riwayat nyata tetap tersedia. Ini menggantikan kebutuhan aktivasi manual pada catatan berikut.

Arahan pengguna terbaru: Profil menyajikan sebagian personalisasi, detail lengkap melalui tombol, serta sakelar audio. Preferensi audio bertahan lintas tab dalam sesi; TTS belum terhubung. Riwayat tidak lagi memiliki filter; foto lokal/thumbnail dan ringkasan menjadi konten utama. Sumber/basis tetap tersedia di detail dengan label Asal data/Acuan perhitungan. Preview desain tidak memiliki banner demo, diaktifkan hanya melalui `UI_PREVIEW=true`, dan tidak mengisi data pengguna. Status integrasi kamera/penyimpanan/engine tidak berubah. Catatan perilaku lama di bawah bersifat historis.

### Perluasan Profil/Riwayat — 7 November 2026

Status terbaru menggantikan catatan implementasi awal berikut: field tinggi/berat opsional, pola makan, preferensi halal, dan pencatatan alergi tersedia dalam sesi. FR-15 tersedia pada tingkat form opsional, tanpa kalkulasi target tubuh. FR-16 hanya terpenuhi untuk pencatatan: status belum diisi dibedakan dari tidak ada alergi yang diketahui; pencocokan alergen belum diimplementasikan. Nama/usia/pilihan tambahan dapat dikosongkan, minimal satu prioritas tetap wajib. Batal/Kembali memberi konfirmasi jika draft berubah. Perubahan onboarding mempertahankan field tambahan.

Riwayat menerima snapshot tampilan dengan nilai nullable, sumber, basis, porsi, waktu, dan prioritas saat dicatat. Preview berisi tersedia secara eksplisit, terpisah dari data pengguna dan berlabel ilustrasi. Filter jenis/tanggal serta detail bekerja; penyimpanan hasil nyata dan API riwayat belum tersedia. Lihat [audit dan verifikasi](PROFILE_HISTORY_AUDIT.md).

### Pembaruan implementasi Profil/Riwayat awal — 7 November 2026

UI `/profile` dan `/profile/nutrition` menyediakan nama (maksimal 60 karakter), usia opsional (bilangan bulat 1–120 untuk validasi input, bukan batas medis/segmentasi), minimal satu dari lima prioritas nutrisi, serta preferensi makanan opsional. Simpan menerapkan draft ke state sesi; Batal membuang perubahan draft. Pilihan onboarding mengisi profil sesi dan label fokus Home mengikuti prioritas yang disimpan. Profil tidak dikirim ke server, tidak bertahan setelah restart, dan belum memengaruhi engine/insight. FR-15/16 tetap belum diimplementasikan.

UI `/history` memiliki filter Semua/Tanpa kemasan/Kemasan, satu tanggal, dan reset. Tanpa sumber riwayat, layar selalu menampilkan empty state yang sesuai filter; tidak mengklaim ada penyimpanan analisis. Kamera/TTS/Insight masih ditandai belum tersedia. Ini implementasi UI parsial FR-13/14, bukan bukti pipeline atau persistensi sudah selesai. Ketentuan produk di atas tetap berlaku; status historis onboarding/dashboard diperbarui sebatas state sesi dan navigasi ini.

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


### Koreksi basis label - 8 November 2026

Scan label baru dengan basis per sajian dalam gram/ml dinormalisasi menjadi satu porsi dengan massa/volume referensi tetap tersimpan; entri lama dan basis per-100 tidak diubah. Validasi evidence membedakan energi total dari energi lemak/AKG; konflik nyata mengosongkan nilai dan membatalkan insight/TTS terkait. Kontrak dan batasannya ada di [SCANNER_API.md](../server/SCANNER_API.md).

Fallback label: OCR perangkat bersifat opsional secara default; kegagalan OCR tidak memblokir pengiriman gambar ke satu dispatch LLM awal. Build Flutter SCANNER_USE_RAW_OCR=true mempertahankan OCR wajib dan harus diselaraskan dengan flag backend. Validasi gambar, batas OCR 20.000 karakter dan kalkulasi quantity backend tetap berlaku.
