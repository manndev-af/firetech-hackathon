# Product Requirements Document (PRD)

> Addendum scanner, 7 November 2026: pengguna menyetujui backend scanner konsumsi otomatis, satu panggilan DeepSeek Vision dengan gambar pada kedua mode dan OCR pada label, serta personalisasi berbasis retrieval SQL. Nilai foto berstatus estimasi model; label adalah ekstraksi belum terverifikasi. Quantity dapat dikoreksi deterministik dan konsumsi dapat dihapus. Ini menggantikan rencana ONNX/verified-only khusus jalur scanner yang dijelaskan di bagian historis berikutnya. Scope development memakai seed dummy tanpa login; frontend dan TTS playback dikerjakan terpisah. Lihat DECISIONS.md dan server/README.md untuk batas implementasi.

## NutriLens AI — Personalized Nutrition Decision Support

| Atribut | Nilai |
|---|---|
| Status | Draft untuk MVP hackathon |
| Versi | 1.0 |
| Tanggal | 1 November 2026 |
| Sumber kebutuhan | `SUMMARY.md` dan pedoman proyek |
| Nama produk | NutriLens AI (nama kerja, belum final) |

## 1. Ringkasan Produk

NutriLens AI adalah aplikasi mobile yang membantu pengguna memahami kandungan nutrisi makanan dan mengambil keputusan berdasarkan prioritas nutrisi yang mereka pilih. Aplikasi mengenali makanan dari foto atau membaca informasi produk kemasan, meminta pengguna memeriksa hasil pengenalan dan ukuran porsi, lalu menghitung nutrisi secara deterministik dan menjelaskan kelebihan, kekurangan, serta trade-off yang relevan.

Nilai utama produk adalah mengubah data nutrisi menjadi informasi yang mudah dipahami dan personal. Produk ini merupakan alat pendukung keputusan dan literasi nutrisi, bukan alat diagnosis, rekomendasi medis, atau pengganti ahli gizi.

## 2. Masalah dan Peluang

Angka pada label nutrisi sering sulit dipahami dan dibandingkan. Makanan siap santap tidak selalu memiliki informasi nutrisi yang mudah diakses. Sementara itu, kebutuhan pengguna berbeda-beda: sebagian lebih memperhatikan gula atau natrium, sebagian lain protein, energi, atau keseimbangan nutrisi. Hasil klasifikasi foto dan informasi database juga dapat keliru atau tidak lengkap.

NutriLens menjawab kebutuhan ini dengan menyatukan pengenalan makanan, verifikasi oleh pengguna, data nutrisi bersumber, kalkulasi berdasarkan porsi, dan insight sesuai prioritas pengguna.

## 3. Visi, Sasaran, dan Ukuran Keberhasilan

### Visi

Membantu pengguna membuat pilihan makanan yang lebih terinformasi dengan memahami konsekuensi nutrisi sesuai prioritas mereka.

### Sasaran MVP

1. Menyediakan satu alur mobile end-to-end dari foto makanan hingga insight nutrisi.
2. Memastikan pengguna dapat mengoreksi identitas makanan dan mengonfirmasi porsinya.
3. Menampilkan nilai nutrisi yang memiliki sumber dan basis sajian yang jelas.
4. Menghasilkan trade-off yang mengikuti prioritas pengguna tanpa skor “sehat” universal.
5. Menyampaikan ketidakpastian serta keterbatasan data secara jujur.

### Indikator keberhasilan MVP

- Pengguna uji dapat menyelesaikan alur foto → konfirmasi makanan → konfirmasi porsi → hasil nutrisi dan insight.
- Nilai kalkulasi untuk kasus uji sesuai dengan perhitungan deterministik yang diharapkan.
- Pengguna dapat memahami sumber/basis nilai, menemukan data yang tidak tersedia, serta memperbaiki prediksi atau porsi.
- Kinerja model dilaporkan dengan metrik evaluasi independen, termasuk top-1, top-3, precision, recall, F1 per kelas, dan confusion matrix. Target numerik ditetapkan setelah baseline diukur; PRD ini tidak mengasumsikan akurasi tertentu.

## 4. Pengguna Sasaran dan Kebutuhan

### Segmen awal

Mahasiswa dan dewasa muda Indonesia, khususnya yang sering membeli makanan siap santap, snack, minuman kemasan, atau makan di luar. Rentang 18–30 tahun dapat digunakan sebagai segmentasi awal, bukan batas medis.

### Kebutuhan pengguna

- Mengenali makanan atau menemukan produknya dengan cepat.
- Memahami kandungan nutrisi dalam bahasa sederhana.
- Mengetahui pengaruh jumlah porsi terhadap total nutrisi.
- Membandingkan makanan berdasarkan prioritas pribadi.
- Memeriksa dan memperbaiki informasi yang diekstrak atau diprediksi.
- Mendengarkan hasil melalui suara bila fitur TTS tersedia.

## 5. Ruang Lingkup Produk

### P0 — MVP inti

- Onboarding ringan atau profil demo.
- Pilihan satu atau lebih prioritas: gula, natrium, energi/kalori, protein, atau keseimbangan nutrisi.
- Nutrition Profile dapat memuat usia/rentang usia dan preferensi makanan; tinggi badan, berat badan, serta informasi alergi bersifat opsional.
- Personalisasi profil memengaruhi fokus penjelasan, perbandingan, dan alternatif, bukan nilai nutrisi sumber.
- Home dengan akses utama untuk memindai makanan.
- Jalur makanan tanpa kemasan: foto, prediksi top-3, confidence, konfirmasi/koreksi, dan opsi cari manual atau foto ulang.
- Konfirmasi porsi oleh pengguna dengan satuan yang sesuai dan nilai default yang dapat diubah.
- Pemetaan makanan ke subset data nutrisi yang sumber dan basisnya ditinjau.
- Perhitungan nutrisi per porsi secara deterministik.
- Insight yang menghubungkan kelebihan, kekurangan, serta trade-off dengan prioritas pengguna.
- Penjelasan sumber data, basis sajian, data yang hilang, dan batasan estimasi.

### P1 — bila waktu memungkinkan

- Makanan kemasan melalui barcode dan lookup Open Food Facts.
- OCR label nutrisi sebagai jalur cadangan, dengan formulir verifikasi dan koreksi pengguna.
- Text-to-Speech untuk membacakan hasil.
- Perbandingan dua makanan.
- Riwayat pemindaian sederhana.

### Di luar ruang lingkup MVP

- Diagnosis atau rekomendasi diet medis, penyesuaian obat, dan klaim hasil kesehatan.
- Estimasi berat/porsi otomatis dari satu foto.
- Riwayat penyakit, obat, konsultasi dokter, dan rekomendasi pengobatan.
- Aktivitas fisik (pengembangan berikutnya) dan interpretasi klinis terhadap tinggi/berat.
- Sinkronisasi cloud, akun kompleks, analitik konsumsi jangka panjang, dan rekomendasi klinis.
- Menganggap klasifikasi gambar sebagai pengukuran kalori atau kandungan nutrisi.

## 6. Alur Pengguna Utama

1. Pengguna membuka aplikasi dan memilih prioritas nutrisi yang ingin diperhatikan.
2. Pengguna memilih **Unpackaged Food** dan mengambil foto makanan.
3. Sistem menampilkan sampai tiga prediksi beserta confidence.
4. Pengguna memilih prediksi yang benar, melakukan pencarian manual, atau mengambil foto ulang.
5. Pengguna memilih atau mengubah ukuran porsi. Sistem tidak menyimpulkan berat dari foto.
6. Backend mencari referensi nutrisi yang dipetakan ke makanan dan menampilkan sumber serta basis datanya.
7. Sistem menghitung nilai untuk porsi terpilih dan membandingkannya dengan prioritas pengguna.
8. Aplikasi menampilkan hasil, trade-off, data yang tidak tersedia, serta opsi TTS/riwayat jika tersedia.

Jalur makanan kemasan (P1) menggunakan barcode atau OCR label, kemudian meminta pengguna memverifikasi produk, nilai, serving size, dan jumlah sajian sebelum kalkulasi.

## 7. Kebutuhan Fungsional

Rincian kebutuhan fungsional, prioritas, dan kriteria penerimaan tersedia di [FRD.md](FRD.md). PRD ini menjadi referensi konteks dan sasaran produk; implementasi fitur mengacu pada FRD.

## 8. Kebutuhan Data dan Perhitungan Nutrisi

Data nutrisi disimpan atau diambil dalam struktur yang mempertahankan nama makanan, sumber, ukuran dan satuan sajian, serta nilai nutrisi. Nutrisi yang diprioritaskan mencakup energi, protein, lemak total, lemak jenuh, karbohidrat, gula, natrium, dan serat bila tersedia.

- Gunakan referensi yang dapat ditelusuri seperti TKPI atau sumber lain yang sesuai; cantumkan sumber dan basis setiap record.
- Untuk makanan kemasan, Open Food Facts dapat digunakan dengan catatan bahwa kelengkapan data produk bervariasi.
- Normalisasi unit dan serving sebelum perbandingan.
- Nilai yang tidak tersedia tetap tidak diketahui; jangan mengubahnya menjadi nol atau membuat nilai pengganti.
- Jelaskan jika pemetaan hidangan tidak sepenuhnya mewakili resep, bahan, atau metode masak yang sebenarnya.
- Aritmetika dilakukan oleh fungsi TypeScript deterministik. LLM, jika digunakan, hanya menerima hasil terstruktur untuk membantu menjelaskan.

## 9. Kebutuhan Nonfungsional

- **Kegunaan:** alur pemindaian sederhana, kontrol porsi mudah dipakai, dan kesalahan dapat dipulihkan.
- **Keandalan:** kegagalan model, lookup, atau layanan penjelasan tidak boleh menghasilkan angka nutrisi yang dibuat-buat. Insight berbasis aturan menjadi fallback.
- **Kinerja:** respons klasifikasi dan kalkulasi cukup cepat untuk demo; ukur latensi pada perangkat dan lingkungan yang tersedia sebelum menetapkan target.
- **Aksesibilitas:** teks hasil mudah dibaca; TTS menjadi peningkatan bila dapat dikerjakan.
- **Keamanan:** validasi file, tipe MIME, ukuran permintaan, serta input API. Jangan mengekspos secret atau stack trace.
- **Privasi:** kumpulkan profil sesedikit mungkin. Foto tidak disimpan lebih lama dari kebutuhan pemrosesan tanpa alasan dan pemberitahuan yang jelas.
- **Keterlacakan:** model, preprocessing, pemetaan makanan, sumber nutrisi, dan aturan kalkulasi harus dapat diidentifikasi.

## 10. Prinsip UX dan Konten

- Gunakan bahasa Indonesia yang lugas dan tidak menghakimi.
- Nyatakan “berdasarkan data yang tersedia” dan sebutkan sumber/basis nilai.
- Pisahkan confidence klasifikasi dari kepastian data nutrisi.
- Jangan menyebut makanan secara mutlak “sehat” atau “tidak sehat”; jelaskan trade-off sesuai prioritas.
- Jangan menyamakan confidence model dengan peluang akurasi dunia nyata tanpa evaluasi dan kalibrasi.
- Jangan menyatakan angka kalori/nutrisi berasal dari foto. Angka berasal dari data referensi dan porsi yang dikonfirmasi.
- Tampilkan pengingat bahwa aplikasi bukan pengganti saran tenaga kesehatan jika konteks hasil berpotensi ditafsirkan secara klinis.

## 11. Teknologi dan Batas Arsitektur

- **Mobile:** Flutter/Dart untuk UI, kamera, barcode, OCR, konfirmasi pengguna, serta TTS.
- **Backend:** satu API Node.js + TypeScript + Express untuk validasi, inference, lookup, kalkulasi, dan insight.
- **Klasifikasi:** MobileNetV3-Large hasil fine-tuning pada subset MM-Food-100K; Python/PyTorch untuk training dan evaluasi, ONNX Runtime untuk inference bila model siap.
- **Data:** subset referensi nutrisi sederhana (misalnya JSON/CSV) cukup untuk MVP; tidak perlu infrastruktur database kompleks sebelum dibutuhkan.
- **Integrasi opsional:** Open Food Facts untuk produk kemasan; LLM hanya untuk parafrasa hasil terstruktur, dengan fallback deterministik.

Sistem mengikuti prinsip satu backend sederhana. Jangan menambahkan microservices, autentikasi, atau infrastruktur yang tidak diperlukan untuk alur MVP.

## 12. Batasan, Asumsi, dan Keputusan Terbuka

### Asumsi sementara

- Nama NutriLens AI dan positioning masih nama kerja.
- Jalur makanan tanpa kemasan adalah jalur demo utama.
- Pengguna mengonfirmasi identitas makanan dan porsi.
- Model hanya mengklasifikasikan kategori makanan; bukan menghitung nutrisi atau porsi.
- Pemetaan nutrisi awal mencakup subset kelas yang benar-benar memiliki referensi layak.
- Profil dapat mencakup usia/rentang usia dan preferensi makanan; tinggi/berat serta alergi bersifat opsional mengikuti addendum terbaru pada [SUMMARY.md](SUMMARY.md).
- Riwayat penyakit dan obat tidak termasuk MVP; personalisasi tidak memberikan diagnosis atau saran medis.

### Keputusan yang perlu difinalisasi tim

1. Nama dan branding final.
2. Daftar kelas makanan dan ukuran subset yang realistis setelah audit kualitas dataset.
3. Split train/validation/test dan threshold confidence berdasarkan hasil evaluasi.
4. Referensi nutrisi yang dipakai dan record per kelas yang telah ditinjau.
5. Pemetaan satuan porsi per kelas.
6. Apakah barcode/OCR, LLM, TTS, riwayat, dan perbandingan masuk build demo.
7. Kebijakan penyimpanan foto dan profil.
8. Apakah field opsional tinggi badan, berat badan, dan alergi dibutuhkan untuk demonstrasi; bagaimana persetujuan, penggunaan, dan retensinya.

## 13. Risiko dan Penanganan

| Risiko | Dampak | Penanganan |
|---|---|---|
| Prediksi gambar keliru | Data nutrisi yang dibuka tidak sesuai makanan | Tampilkan kandidat, confidence, koreksi, foto ulang, dan pencarian manual. |
| Porsi tidak mewakili konsumsi | Total nutrisi meleset | Minta konfirmasi porsi dan jelaskan unit/konversi yang digunakan. |
| Data nutrisi tidak cocok dengan resep | Insight tidak representatif | Tampilkan sumber/basis serta keterbatasan pemetaan; jangan mengklaim presisi berlebih. |
| Dataset tidak seimbang atau gambar gagal diunduh | Model bias atau pipeline tertunda | Audit data, deduplikasi, subset kelas yang cukup, evaluasi per kelas, fallback manual yang transparan. |
| OCR salah membaca angka | Hasil produk kemasan keliru | Wajibkan review dan edit oleh pengguna sebelum analisis. |
| LLM menghasilkan klaim/angka keliru | Informasi menyesatkan | Jangan gunakan LLM untuk angka; batasi ke hasil terstruktur dan sediakan penjelasan berbasis aturan. |
| Scope terlalu luas untuk hackathon | Alur inti tidak selesai | Kunci P0 lebih dahulu; pindahkan fitur tambahan ke P1/P2. |
| Profil mengumpulkan data berlebihan | Beban onboarding dan risiko privasi | Prioritas nutrisi cukup untuk personalisasi MVP; hindari data medis. |

## 14. Rencana Rilis dan Evaluasi

1. **Fondasi:** audit repository dan dataset, finalisasi subset kelas serta peta nutrisi.
2. **Baseline:** latih/evaluasi classifier dengan split independen; validasi konsistensi preprocessing jika mengekspor ONNX.
3. **Vertikal slice:** bangun foto → prediksi → konfirmasi → porsi → kalkulasi → insight.
4. **Validasi:** uji kalkulasi untuk konversi satuan, nilai hilang, dan porsi; uji alur pada foto/perangkat yang bervariasi.
5. **Peningkatan:** tambahkan barcode/OCR, TTS, perbandingan, atau riwayat hanya bila alur inti stabil.

Evaluasi awal dengan pengguna dapat mengukur keberhasilan menyelesaikan tugas, pemahaman informasi, waktu memahami hasil, kepercayaan terhadap prediksi, serta kemudahan koreksi. Evaluasi kecil hanya mengukur usability/pemahaman awal dan tidak membuktikan perubahan kesehatan jangka panjang.

## 15. Definisi Selesai untuk MVP

MVP siap didemonstrasikan ketika pengguna dapat menyelesaikan jalur makanan tanpa kemasan dari foto sampai insight personal; dapat mengoreksi identitas dan porsinya; nilai nutrisi memiliki sumber dan basis yang jelas; kalkulasi menangani nilai hilang dengan benar; prediksi tidak pasti ditandai; dan tim dapat menjelaskan batasan model serta data tanpa mengklaim kemampuan yang belum divalidasi.
