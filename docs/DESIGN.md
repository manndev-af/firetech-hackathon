# NutriLens AI — Rancangan UI/UX

> Status: panduan desain awal untuk MVP. Ini bukan spesifikasi visual final atau bukti bahwa layar sudah diimplementasikan.

Dokumen ini menerjemahkan sasaran produk menjadi arahan pengalaman pengguna. Kebutuhan perilaku tetap mengacu pada [FRD.md](FRD.md), sasaran produk pada [PRD.md](PRD.md), konteks brainstorming pada [SUMMARY.md](SUMMARY.md), dan batas persetujuan pada [DECISIONS.md](DECISIONS.md). Aturan implementasi/review UI ada di [rules/ui.md](../rules/ui.md).

## 1. Tujuan desain

UI harus membantu pengguna memahami nutrisi berdasarkan prioritasnya, sambil menunjukkan sumber dan keterbatasan data. Alur utama harus mudah diselesaikan dengan kamera, pilihan porsi, dan koreksi sederhana.

Prinsip yang disepakati dalam arah produk:

- Scan makanan menjadi tindakan utama.
- Pengguna dapat mengoreksi identitas makanan dan porsi sebelum analisis.
- Hasil menjelaskan trade-off sesuai prioritas, bukan memberi label universal “sehat/tidak sehat”.
- Sumber, basis sajian, ketidakpastian, dan nilai yang tidak tersedia terlihat.
- UI tidak menyiratkan model mengukur berat atau nutrisi dari gambar.

Warna merek, tipografi, ikon final, komposisi tab, dan token visual belum diputuskan. Material 3 dapat dipertimbangkan sebagai dasar komponen Flutter, tetapi penggunaannya sebagai keputusan final perlu dikonfirmasi tim.

## 2. Arsitektur informasi yang disarankan

Rancangan summary mengusulkan Home, Scan, History, dan Profile. Ini adalah usulan navigasi; belum ada keputusan bahwa seluruhnya harus menjadi tab permanen.

| Area | Konten utama | Status cakupan |
|---|---|---|
| Home | Prioritas yang dipilih, akses Scan, dan riwayat singkat bila tersedia | Home/Scan termasuk rancangan MVP; riwayat tambahan |
| Scan | Pilihan makanan tanpa kemasan atau makanan kemasan | Unpackaged menjadi alur demo utama; packaged P1 |
| Profile | Prioritas nutrisi dan Nutrition Profile | Prioritas nutrisi masuk MVP; field lain mengikuti status opsional di PRD/FRD |
| History | Hasil pemindaian sebelumnya | P1, bergantung keputusan penyimpanan |

## 3. Alur layar inti

### 3.1 Makanan tanpa kemasan

1. Home menonjolkan tombol **Scan makanan**.
2. Pengguna memilih makanan tanpa kemasan dan mengambil foto dengan panduan singkat.
3. Hasil klasifikasi menampilkan hingga tiga kandidat dan confidence, dengan tindakan pilih, koreksi/cari manual, atau foto ulang.
4. Pengguna mengonfirmasi porsi melalui kontrol sesuai kategori makanan.
5. Hasil menampilkan nutrisi untuk porsi tersebut, sumber/basis nilai, prioritas yang disorot, serta trade-off dan keterbatasan.

### 3.2 Makanan kemasan (P1)

Pengguna memilih barcode atau input label. Informasi hasil lookup/OCR ditampilkan untuk diperiksa dan dikoreksi sebelum jumlah sajian dianalisis. Jangan memberi tampilan seolah OCR atau database crowdsourced selalu benar.

### 3.3 Nutrition Profile

Profil memuat pilihan usia/rentang usia, preferensi makanan, dan prioritas nutrisi. Tinggi/berat serta alergi opsional; aktivitas fisik tahap berikutnya. Profil mengubah sorotan dan penjelasan, bukan kandungan nutrisi sumber. Jangan menampilkan formulir seperti pemeriksaan dokter atau meminta riwayat penyakit/obat.

## 4. Pola komponen dan informasi

### Kartu prediksi

- Tampilkan label makanan dan confidence dari model dengan format konsisten.
- Tandai hasil berkeyakinan rendah berdasarkan threshold evaluasi aktual.
- Sediakan cara memilih prediksi lain, mencari manual, atau mengambil ulang foto.
- Contoh angka dalam dokumen produk hanya ilustrasi dan tidak boleh dipakai sebagai hasil demo aktual.

### Konfirmasi porsi

- Gunakan unit sesuai konfigurasi makanan: buah, butir, potong, gram/porsi, atau volume/jumlah kemasan.
- Nilai default, rentang, langkah, dan konversi ditetapkan dalam konfigurasi terstruktur yang ditinjau.
- Tampilkan unit dengan jelas dan beri kontrol increment/decrement atau slider yang sesuai.
- Jika faktor konversi atau basis data tidak tersedia, jelaskan dan jangan membuat angka pengganti.

### Hasil nutrisi dan insight

- Bedakan nilai per porsi dengan per 100 g/ml.
- Tampilkan sumber data dan porsi yang dipilih dekat dengan nilai terkait.
- Sorot prioritas pengguna, tetapi tetap sediakan konteks komponen nutrisi lain yang tersedia.
- Bandingkan makanan hanya pada basis setara, atau jelaskan perbedaan basisnya.
- Nilai null ditampilkan sebagai tidak tersedia, bukan nol.

## 5. Hirarki visual dan konten

- Gunakan judul yang menyebut konteks layar, informasi utama, tindakan utama, lalu detail.
- Kelompokkan informasi hanya jika membantu pengguna; hindari kartu, badge, dan dekorasi berulang tanpa fungsi.
- Gunakan bahasa Indonesia yang lugas dan tidak menghakimi.
- Jelaskan “berdasarkan data yang tersedia”; pisahkan confidence klasifikasi dari ketepatan referensi nutrisi.
- Jangan menambahkan skor kesehatan universal, klaim medis, statistik demo yang seolah nyata, atau badge “AI” tanpa makna.
- Gunakan label tindakan yang menjelaskan hasilnya, seperti “Pilih makanan ini”, “Ubah porsi”, “Coba foto lagi”, dan “Bandingkan”.

## 6. State, kegagalan, dan pemulihan

Setiap layar yang memuat data perlu menangani state yang relevan:

- **Loading:** jelaskan proses yang sedang berjalan tanpa menampilkan nilai rekaan.
- **Kosong/tidak ditemukan:** jelaskan apa yang tidak tersedia dan beri opsi input manual atau kembali bila memungkinkan.
- **Confidence rendah:** minta konfirmasi lebih lanjut atau foto ulang; jangan lanjut seolah hasil pasti.
- **Data nutrisi tidak tersedia:** tampilkan ketiadaan data dan sumber yang sudah dicoba jika relevan.
- **Kegagalan kamera, lookup, OCR, atau API:** gunakan pesan yang hanya menyebut penyebab yang diketahui dan sediakan langkah pemulihan.
- **TTS/LLM gagal:** hasil deterministik tetap dapat dibaca; jangan menghilangkan angka atau mengganti hasil dengan klaim generatif.

## 7. Aksesibilitas dan tata letak

- Jangan menjadikan warna satu-satunya penanda status; sertakan teks, ikon bermakna, atau nilai yang relevan.
- Beri nama aksesibel pada tombol ikon dan kontrol porsi; hindari pembacaan ganda oleh screen reader.
- Dukung pembesaran teks, kontras yang terbaca, fokus yang terlihat, dan navigasi keyboard jika platform mendukungnya.
- Pastikan kontrol utama mudah disentuh dan tidak memerlukan ketepatan kecil.
- Uji teks panjang, layar sempit, state kosong/error, dan orientasi yang didukung sebelum menyatakan UX terverifikasi.
- TTS merupakan peningkatan P1; jangan menganggap TTS menggantikan label aksesibel atau teks visual.

## 8. Batas dan pertanyaan desain terbuka

- Nama dan identitas visual final.
- Warna, tipografi, ikon, radius, spacing, dan token tema.
- Bentuk navigasi akhir: tab, tombol Scan khusus, atau kombinasi.
- Desain detail Profile untuk field opsional serta cara persetujuan/penyimpanan.
- Interaksi pencarian manual, penanganan makanan campuran, dan alur perbandingan.
- Apakah barcode/OCR, riwayat, TTS, dan LLM masuk build demo.

Putuskan hal-hal ini melalui review desain/produk; jangan menganggap rekomendasi visual dalam dokumen sebagai persetujuan final.