# NutriLens AI — Rancangan UI/UX

Penyempurnaan 7 November 2026: detail Riwayat tanpa ikon silang; tutup melalui gestur geser, area luar panel, atau kembali sistem. Kartu Ringkasan menampilkan catatan dan fokus saat dicatat tanpa penilaian kesehatan baru. Preview Personalisasi menampilkan seluruh prioritas, preferensi, pola makan, halal, dan status/bahan alergi. Input Profil memakai latar mint, border radius 16, label tetap terlihat, satuan, dan teks input 16 px; font Inter serta palet yang ada dipertahankan.

## Revisi ringkasan Profil dan foto Riwayat — 7 November 2026

Revisi Profil berikutnya: informasi diri dipisahkan dari personalisasi. Edit profil membuka nama/usia/tinggi/berat; Lihat detail Personalisasi langsung membuka form lengkap prioritas/pilihan makanan/alergi secara inline. Semua bagian form dapat digulir pada halaman yang sama, dengan Simpan dan Kembali di akhir. Tidak memakai drawer/bottom sheet. Pengaturan audio tampil pada ringkasan, dan kembali terlihat setelah editor ditutup. Posisi scroll kembali ke ringkasan saat selesai. Riwayat tidak berubah pada revisi ini.

Pembaruan akses contoh: tab Riwayat sekarang langsung membuka tiga catatan contoh saat `flutter run`, tanpa banner atau tombol tambahan. Susunan visual tidak berubah. `UI_PREVIEW=false` tersedia untuk memeriksa state kosong; fixture tetap tidak menjadi data tersimpan.

Arahan terbaru pengguna menggantikan rincian UI di bawah: tampilkan sebagian personalisasi pada Profil, buka seluruhnya melalui Lihat detail, dan sediakan sakelar Audio analisis. Riwayat berupa foto, nama, waktu/porsi, dan summary singkat tanpa filter. Detail menyimpan angka serta informasi Asal data/Acuan perhitungan dalam bagian yang dapat dibuka. Label demo/ilustrasi tidak ditampilkan pada preview desain; fixture diaktifkan melalui build flag dan tetap terpisah dari catatan nyata. Inter konsisten dengan skala 24/18/16/14 sesuai peran. Dokumentasi bukti, foto, dan keterbatasan ada di [audit terbaru](PROFILE_HISTORY_AUDIT.md#revisi-setelah-review-pengguna).

## Audit dan perluasan personalisasi — 7 November 2026

Pembaruan ini menggantikan batas UI pada catatan implementasi awal di bawah. Profil kini memiliki lima bagian: prioritas jamak, pilihan makanan/pola makan/halal, alergi, nama/usia, dan tinggi/berat opsional. Ringkasan memakai satu kartu identitas mint, deskripsi prioritas, latar putih, token teks/primary dari tema aplikasi, serta Inter. Form menyediakan validasi dekat input, konfirmasi membuang draft, dan footer adaptif terhadap keyboard/layar pendek.

Riwayat menyediakan preview terpisah dengan label DATA ILUSTRASI, filter yang bekerja, kelompok tanggal, dan detail sumber/basis/porsi/prioritas saat dicatat. Nilai null tetap Belum tersedia. Referensi sushi/ice cream memengaruhi hierarki dan ruang kosong saja; palet tetap teal/mint. Figcraft dan navigasi global tidak diubah. Bukti, batas aksesibilitas, isi field, dan cara ekspor PNG ada di [audit Profil/Riwayat](PROFILE_HISTORY_AUDIT.md).

## Jelajahi Flutter — 7 November 2026

Halaman Jelajahi, Bandingkan, dan Asisten dibuat mengikuti layer `11 Jelajah`, `16 Bandingkan`, dan `12 Percakapan` pada `canvas.figcraft`. Tab Jelajahi dan kartu Buka Jelajah di Home membuka layar Jelajah; aksi Bandingkan membuka halaman detail. Bandingkan meminta dua gambar dari galeri, lalu membuka ringkasan setelah keduanya dipilih dan pengguna menekan Lihat ringkasan. Pengguna dapat mengganti gambar sebelum membuka ringkasan. Gambar hanya dibaca lokal, belum diunggah atau dianalisis; nilai ringkasan masih ilustrasi. Pintasan pola catatan membuka Asisten dengan tampilan percakapan contoh, sedangkan Tanya soal makanan membuka Asisten tanpa chat. Bandingkan dan Asisten ditampilkan di atas shell agar tidak menampilkan bottom navigation, sesuai artboard. Belum ada riwayat makanan, lookup nutrisi, kalkulasi, atau integrasi chat/LLM. File FigCraft menjadi referensi baca saja.

## Profil dan Riwayat Flutter awal — 7 November 2026

Implementasi mengikuti struktur artboard `09 History`, `10 Profile & Settings`, dan `07 Nutrition Profile` pada `nutrilens-base.figcraft`, dengan palet dari `palet_warna_ui_aplikasi_nutrisi.md` yang diberikan pengguna. File Figcraft tidak diubah. Layar baru memakai primary `#0D6E6B`, latar `#F3F9F8`, permukaan `#E6F4F3`, chip `#D8EFEF`, teks `#142625`/`#5E7170`, garis `#E4ECEB`, kartu radius 24 px, serta jarak berbasis 8 px. Token layar lama dan bentuk navigasi bawah dipertahankan.

- Profil menampilkan identitas aktual atau “Profil kamu”, prioritas, preferensi, dan pengaturan informasi. Editor menyediakan nama/usia opsional, lima prioritas jamak, preferensi opsional, Simpan dan Batal. Tidak memakai nama contoh Naya sebagai data awal.
- State profil hanya hidup selama sesi aplikasi; pilihan onboarding diteruskan ke profil dan perubahan prioritas memperbarui label Home. Informasi privasi menjelaskan batas ini. Audio hasil analisis ditandai belum tersedia, bukan toggle seolah TTS sudah berfungsi.
- Riwayat menampilkan filter jenis/tanggal, reset filter, dan empty state. Belum ada penyimpanan atau daftar hasil nyata. Mulai pindai memberi pemberitahuan kamera belum tersedia.
- Tab Home, Jelajahi, History, dan Profile terhubung ke branch yang benar. Halaman perbandingan/asisten tampil di atas shell. Tombol kamera tidak lagi menuju route contoh `/create-order`.
- Tinggi/berat, alergi, penyimpanan permanen, dan integrasi mesin nutrisi tetap belum diimplementasikan. Catatan historis di bawah yang menyebut Profil/Riwayat belum dibuat digantikan oleh pembaruan ini untuk cakupan UI tersebut.

## Pembaruan FigCraft — 4 November 2026

Redesign pada `nutrilens-base.figcraft` dikerjakan melalui MCP FigCraft. Seluruh 14 artboard tetap dipertahankan. Perubahan struktur terbesar ada pada Home, Food Scanner, Food Recognition, dan Splash; layar lainnya menerima perapian tipografi, kartu, atau alignment sesuai kebutuhan.

- Referensi pertama diterapkan sebagai komposisi foto editorial dan hierarki konten, bukan dashboard target kalori. Referensi kedua diterapkan sebagai foto kamera dominan dengan bingkai pengambilan gambar dan panel tindakan putih.
- Palet semantik teal/mint tetap dipakai. Bayangan kartu dikurangi, status tab aktif diperbaiki, serta aksen batas pemberitahuan diselaraskan ke mint.
- Ringkasan nutrisi memakai enam kartu Auto Layout; label data kosong tidak keluar dari kartu. Tidak ada angka nutrisi atau target harian baru.
- Foto makanan adalah ilustrasi visual, bukan foto pengguna, bukti identifikasi, atau referensi nutrisi. Foto tertanam di file FigCraft; sumber aset: `https://images.unsplash.com/photo-1512058564366-18510be2db19`. Tulisan ilustrasi tetap tampak pada layar yang memakainya.
- Jalur kamera utama mempertahankan konfirmasi identitas dan porsi. Barcode/label tetap ditandai sebagai tambahan P1, bukan fitur yang sudah berfungsi. Login/Daftar tetap eksplorasi UI.
- Verifikasi dilakukan dengan screenshot seluruh artboard dan inspeksi struktur kartu nutrisi; ini bukan pengujian kamera, inferensi, Flutter, aksesibilitas, atau alur runtime. Layout layar secara keseluruhan belum seluruhnya memakai Auto Layout.

PRD dan FRD tidak diubah karena cakupan produk dan aturan kalkulasi tetap sama. Bagian historis berikut dipertahankan; arah navigasi lima tab pada bagian 10 menggantikan uraian empat tab sebelumnya.

> Status: panduan desain dan inventaris prototipe FigCraft. Prototipe adalah rancangan interaktif, bukan bukti bahwa fitur telah diimplementasikan di aplikasi Flutter.

Dokumen ini menerjemahkan sasaran produk menjadi arahan pengalaman pengguna dan mencatat layar yang tersedia di `nutrilens-base.figcraft`. Kebutuhan perilaku tetap mengacu pada [FRD.md](FRD.md), sasaran produk pada [PRD.md](PRD.md), konteks produk pada [SUMMARY.md](SUMMARY.md), status keputusan pada [DECISIONS.md](DECISIONS.md), dan aturan implementasi/review UI pada [rules/ui.md](../rules/ui.md).

## 1. Tujuan dan prinsip desain

Pembaruan tipografi Flutter — 7 November 2026: atas permintaan pengguna, semua halaman memakai family Inter melalui tema global (`ThemeData.fontFamily` dan `TextTheme`). Bobot Regular 400, Medium 500, SemiBold 600, dan Bold 700 dibundel lokal di `app/assets/fonts/`, dengan mapping pada `pubspec.yaml` dan lisensi SIL Open Font License. Ukuran, bobot, dan warna per layar tetap mengikuti pengaturan yang ada; tidak ada perubahan layout atau bottom navigation. Inter tersedia tanpa pengambilan font saat runtime. Bundle font baru perlu dimuat melalui stop/run ulang.

Pembaruan Dashboard Flutter — 7 November 2026: referensi pengguna `Group-18.png` (kosong) dan `Group-17.png` (berisi) menggantikan dashboard contoh toko. Home memakai latar putih, sapaan sesuai waktu lokal, judul 32 px, kartu scan radius 28 px, label fokus onboarding, ilustrasi makanan, dan tombol Foto makanan. Token `heroBackground` (`#0D6E6B`) ditambahkan sesuai latar ilustrasi referensi; token teal/mint lainnya tetap dipakai. Bagian Hari ini dibuat sebagai `widgets/dashboard_history.dart`: tanpa ringkasan menampilkan empty state dan Catat makanan pertama; dengan ringkasan menampilkan jumlah catatan dan total gula/protein/energi yang diberikan. Angka ilustratif pada referensi tidak menjadi data aplikasi. Nilai tidak tersedia tetap unknown; data parsial diberi catatan. Kartu Buka Jelajah muncul pada state berisi. Navigasi bawah dikembalikan ke desain sebelum pengerjaan dashboard sesuai koreksi pengguna: latar berlekuk dan kamera hijau mengambang. Label Beranda/Jelajahi/Riwayat/Profil yang sudah ada dipertahankan. Perubahan dashboard tidak mengganti komponen atau callback navigasi lama. Fokus hanya diteruskan ke label dashboard, belum digunakan untuk kalkulasi atau disimpan. Ilustrasi berasal dari ekspor pengguna; seluruh kontrol dibuat native dengan scroll dan penyesuaian teks besar. Backend riwayat, kamera, dan analisis nutrisi belum dihubungkan.

Pembaruan Onboarding Flutter — 7 November 2026: referensi pengguna `Group-12.png`, `Group-14.png`, dan `Group-16.png` diterapkan sebagai dua langkah pilihan dan satu layar selesai. Tampilan memakai latar putih, judul 30 px, kartu radius 20 px dengan penanda centang/warna mint saat terpilih, indikator 01/02 dan 02/02, tombol utama teal, serta SafeArea dan scroll untuk layar sempit/teks besar. Langkah 1 memilih satu dari Gula/Protein/Natrium/Keseimbangan (default Gula); langkah 2 memilih preferensi opsional dengan default Masakan rumahan dan opsi Lewati dulu. Ringkasan selesai mengikuti pilihan aktual. Tombol Google pada login membuka alur demo tanpa autentikasi; Ke beranda menuju dashboard yang sudah ada. Kembali antar-langkah mempertahankan pilihan; keluar dari alur mereset state UI. Data belum disimpan atau dipakai engine. Ilustrasi selesai berasal dari ekspor pengguna dan tetap merupakan ilustrasi. Catatan login sebelumnya yang menyebut tombol hanya memberi pemberitahuan digantikan alur demo ini; OAuth belum tersedia.

Pembaruan Login Flutter — 7 November 2026: referensi `Group-11.png` dari pengguna menggantikan tampilan form login sebelumnya. Layar kini berlatar putih dengan wordmark nutrilens, ilustrasi makanan bersudut 32 px, judul “Kenali isi piringmu.” (32 px), deskripsi, dan satu tombol “Lanjutkan dengan Google”. Teks persetujuan serta status “Prototipe · login belum terhubung” mengikuti referensi; dokumen kebijakan belum ditautkan. Token warna teal/teks tetap memakai tema aplikasi. Ilustrasi dirender dari area gambar pada ekspor desain yang disimpan sebagai `assets/images/login_reference.png`; teks dan kontrol dibuat sebagai widget responsif dengan SafeArea dan scroll. Tombol memberi pemberitahuan integrasi belum tersedia tanpa membuat sesi akun. Form email/kata sandi dan validasinya dihapus; uraian login sebelumnya di bawah merupakan riwayat implementasi. Implementasi ini belum menambahkan OAuth Google atau backend autentikasi.

Pembaruan Flutter — 7 November 2026: atas permintaan pengguna, halaman Register, route `/register`, serta tautan Daftar pada login dan navigasi placeholder telah dihapus. Rancangan Daftar pada inventaris prototipe di bawah tetap merupakan catatan desain historis, bukan fitur Flutter yang tersedia.

Implementasi Flutter — 7 November 2026: layar Login telah dibuat mengikuti referensi pengguna dengan header kembali/NutriLens, judul sambutan, input email dan kata sandi, tombol Masuk, kartu insight mint, dan catatan batas layanan. Layar `/login` berada di luar shell navigasi bawah, menggunakan token tema yang tersedia, dan dapat digulir saat keyboard terbuka atau teks diperbesar. Form memvalidasi input dan menyediakan kontrol visibilitas kata sandi; Masuk memberi pemberitahuan autentikasi belum tersedia. Implementasi ini hanya UI dan tidak mengubah scope autentikasi MVP.

UI membantu pengguna memahami nutrisi berdasarkan prioritasnya sambil menunjukkan sumber dan keterbatasan data. Alur utama harus dapat diselesaikan dengan mengambil gambar, mengonfirmasi identitas makanan, memilih porsi, lalu membaca analisis.

- Scan makanan menjadi tindakan utama.
- Pengguna dapat mengoreksi identitas makanan dan porsi sebelum analisis.
- Hasil menjelaskan trade-off sesuai prioritas, bukan memberi label universal “sehat/tidak sehat”.
- Sumber data, basis sajian, ketidakpastian, dan nilai yang tidak tersedia terlihat jelas.
- UI tidak menyiratkan model mengukur berat atau nutrisi dari gambar.
- Personalisasi mengubah fokus penjelasan, perbandingan, dan alternatif; tidak mengubah nilai nutrisi sumber.
- Hindari diagnosis, konsultasi dokter, rekomendasi pengobatan, atau saran perubahan dosis.

## 2. Sistem visual dan token

Prototipe menggunakan gaya modern dengan sudut membulat, ruang kosong yang konsisten, dan teal/cyan sebagai warna aksi utama. Token global pada FigCraft menjadi acuan saat desain diteruskan ke Flutter.

| Token/aturan | Nilai atau penggunaan |
|---|---|
| `color-primary` | `#0C7D7E`, teal untuk aksi utama dan keadaan aktif; teks di atas warna primer harus tetap memiliki kontras yang terbaca. |
| `radius-card` | `16px` untuk kartu. |
| `spacing-base` | `8px`; jarak berikutnya memakai kelipatan 8, misalnya `16px`. |
| Judul layar | `24px`, Bold. |
| Teks sekunder/body | `14px`, Regular sebagai ukuran dasar informasi sekunder. |
| Warna tab | Ikon/label aktif teal; tab tidak aktif abu-abu dengan kontras memadai. |

Gunakan token warna semantik untuk teks, latar, batas, dan status. Jangan menambahkan nilai warna, radius, atau jarak hard-coded jika token yang sesuai tersedia. Status juga harus dibedakan dengan teks atau ikon, bukan warna saja.

## 3. Tata letak dan komponen

- Gunakan Auto Layout untuk susunan kartu dan kontrol yang perlu merespons perubahan konten.
- Kartu prediksi dan kontrol porsi memakai padding `16px` dan gap `8px`.
- Hindari dekorasi atau badge tanpa fungsi informasi maupun struktur.
- Tombol Scan menjadi CTA yang paling menonjol di Home.
- Navigasi bawah memiliki empat tab: **Home**, **Scan**, **History**, dan **Profile**. Gunakan keadaan aktif teal/cyan dan keadaan tidak aktif abu-abu.
- Pada layar proses scan, pertahankan fokus pada foto/prediksi, konfirmasi porsi, dan tindakan lanjut. Jangan memenuhi layar dengan navigasi atau dekorasi yang mengganggu tugas.
- Gunakan bahasa Indonesia yang lugas, tidak menghakimi, dan label tindakan yang menjelaskan hasilnya.

## 4. Daftar halaman pada prototipe

Prototipe iPhone 14 berisi 14 layar berikut. Status “prototipe” berarti tata letak dan alur divisualisasikan; fungsi kamera, inferensi, database, akun, penyimpanan profil, maupun audio belum terbukti berjalan di aplikasi.

| No. | Halaman | Peran dalam alur | Status cakupan |
|---:|---|---|---|
| 1 | **Home** | Entry point setelah onboarding; menampilkan CTA Scan Makanan, prioritas saat ini, dan riwayat singkat bila tersedia. | Layar utama MVP; isi riwayat hanya ditampilkan jika ada data nyata. |
| 2 | **Food Scanner** | Mengambil/memilih gambar makanan dan mengarahkan ke jalur makanan tanpa kemasan atau kemasan. | Jalur tanpa kemasan adalah alur demo inti; barcode/OCR kemasan merupakan tambahan P1. |
| 3 | **Food Recognition** | Menampilkan kandidat klasifikasi dan confidence untuk dikonfirmasi pengguna. | Alur inti; contoh skor yang tampak di prototipe adalah ilustrasi, bukan hasil model aktual. |
| 4 | **Portion Confirmation** | Meminta pengguna memilih jumlah/porsi dengan satuan yang sesuai jenis makanan. | Alur inti; model tidak memperkirakan berat atau porsi. |
| 5 | **Nutrition Result** | Menampilkan nutrisi untuk porsi terkonfirmasi beserta sumber dan basis sajian. | Alur inti; nilai yang belum tersedia ditampilkan sebagai belum tersedia, bukan nol. |
| 6 | **Personalized Insight** | Menjelaskan kelebihan, kekurangan, dan trade-off terhadap prioritas pengguna. | Alur inti; membutuhkan hasil kalkulasi deterministik dan data yang memadai. |
| 7 | **Nutrition Profile** | Mengatur usia/rentang usia, preferensi makanan, prioritas nutrisi, serta field opsional. | Personalisasi ringan sesuai arah MVP; tinggi/berat dan alergi opsional. |
| 8 | **Food Comparison** | Membandingkan pilihan makanan dengan basis sajian yang setara dan menampilkan trade-off. | Tambahan P1; nilai kosong tidak boleh diganti dengan angka rekaan. |
| 9 | **History** | Menampilkan analisis yang benar-benar tersimpan. | Tambahan P1; prototipe menggunakan empty state bila belum ada catatan. |
| 10 | **Profile & Settings** | Akses ke Nutrition Profile, pengaturan aplikasi, privasi, dan informasi aplikasi. | Permukaan UI prototipe; simpanan akun/pengaturan belum diimplementasikan. |
| 11 | **Splash** | Identitas produk dan titik masuk sebelum alur akun/onboarding. | Eksplorasi prototipe. |
| 12 | **Login** | Rancangan layar masuk. | Eksplorasi UI saja; autentikasi bukan komitmen MVP. |
| 13 | **Daftar** | Rancangan pembuatan akun yang mengarahkan ke onboarding personalisasi. | Eksplorasi UI saja; pembuatan akun dan penyimpanan data bukan komitmen MVP. |
| 14 | **Onboarding Personalization** | Mengumpulkan preferensi dan prioritas sebelum pengguna tiba di Home. | Rancangan onboarding ringan; field dan penyimpanan mengikuti PRD/FRD serta keputusan produk. |

Layar Login dan Daftar ditambahkan sebagai rancangan visual atas permintaan, tetapi tidak mengubah keputusan produk bahwa autentikasi kompleks, akun, dan sinkronisasi cloud berada di luar MVP kecuali tim menyetujui perubahan scope.

## 5. Alur navigasi dan layar

### 5.1 Entry dan personalisasi

`Splash → Login atau Daftar → Onboarding Personalization → Home`

Rangkaian ini menggambarkan prototipe. Login/Daftar bukan bukti adanya autentikasi. Untuk MVP, onboarding dapat tetap berupa pengaturan lokal yang ringan sesuai keputusan produk.

### 5.2 Makanan tanpa kemasan — alur utama

`Home → Food Scanner → Food Recognition → Portion Confirmation → Nutrition Result → Personalized Insight`

1. Home menonjolkan tombol **Scan Makanan**.
2. Food Scanner memberi panduan mengambil foto; jalur makanan tanpa kemasan menjadi jalur utama.
3. Food Recognition menampilkan kandidat kelas, top-k, dan confidence. Pengguna memilih atau mengoreksi jenis makanan.
4. Portion Confirmation meminta pengguna memasukkan porsi. Default satu porsi dapat digunakan jika sesuai konfigurasi.
5. Nutrition Result mengambil nilai dari sumber nutrisi terverifikasi dan menampilkan basis serta satuannya.
6. Nutrition Engine menghitung secara deterministik; Personalized Insight menjelaskan trade-off berdasarkan prioritas profil.

Confidence klasifikasi bukan ukuran kebenaran nilai nutrisi. Contoh prediksi pada prototipe diberi status ilustrasi dan tidak boleh dipresentasikan sebagai keluaran model.

### 5.3 Jalur tambahan dan cabang

- Food Scanner dapat menawarkan barcode atau OCR label untuk makanan kemasan sebagai jalur tambahan P1. Nilai hasil OCR/lookup perlu diperiksa pengguna.
- Nutrition Result/Personalized Insight dapat menuju Food Comparison bila terdapat data yang sebanding.
- Tab History membuka riwayat hanya jika hasil benar-benar disimpan.
- Tab Profile menuju Profile & Settings, lalu Nutrition Profile.
- Prototipe menggunakan placeholder/empty state ketika sumber data atau catatan belum tersedia.

## 6. Pola informasi dan konten

### Prediksi makanan

- Tampilkan nama kandidat dan confidence dengan format yang konsisten.
- Sediakan cara memilih kandidat lain, koreksi/pencarian manual, atau mengambil ulang foto.
- Jangan menentukan threshold confidence tanpa evaluasi model aktual.
- Pisahkan ketidakpastian klasifikasi dari kelengkapan/ketepatan data nutrisi.

### Konfirmasi porsi

- Gunakan unit yang sesuai konfigurasi makanan: jumlah buah, butir, potong, gram/porsi, atau volume/jumlah kemasan.
- Nilai default, rentang, langkah, dan konversi ditetapkan dalam konfigurasi terstruktur yang ditinjau.
- Tampilkan unit dan jumlah secara jelas; kontrol increment/decrement atau slider harus mudah disentuh.
- Jika faktor konversi atau basis data tidak tersedia, jelaskan dan jangan membuat angka pengganti.

### Hasil nutrisi dan insight

- Bedakan nilai per porsi dengan per 100 g/ml.
- Tampilkan sumber data dan porsi terpilih dekat dengan nilai terkait.
- Tampilkan nilai tidak tersedia sebagai **Belum tersedia** atau label setara, bukan nol.
- Sorot prioritas pengguna sambil mempertahankan konteks nutrisi lain yang tersedia.
- Bandingkan makanan hanya pada basis setara atau jelaskan perbedaan basisnya.
- LLM, bila digunakan, hanya menjelaskan hasil terstruktur; tidak menghitung nutrisi atau membuat klaim medis.

## 7. State, kegagalan, dan pemulihan

Setiap layar dengan data perlu menangani state yang relevan:

- **Loading:** jelaskan proses tanpa menampilkan nilai rekaan.
- **Kosong/tidak ditemukan:** jelaskan data yang tidak tersedia dan beri pilihan kembali atau input manual bila sesuai.
- **Confidence rendah:** minta konfirmasi lebih lanjut atau foto ulang.
- **Data nutrisi tidak tersedia:** tampilkan ketiadaan data dan sumber yang sudah dicoba jika relevan.
- **Kegagalan kamera, lookup, OCR, atau API:** sebutkan hanya penyebab yang diketahui dan sediakan langkah pemulihan.
- **TTS/LLM gagal:** hasil deterministik tetap dapat dibaca; jangan mengganti hasil dengan klaim generatif.
- **History kosong:** tampilkan empty state, bukan catatan contoh seolah aktivitas nyata.

## 8. Aksesibilitas dan tata letak responsif

- Jangan menjadikan warna satu-satunya penanda status; sertakan teks atau ikon bermakna.
- Beri nama aksesibel pada tombol ikon dan kontrol porsi serta hindari pembacaan ganda oleh screen reader.
- Dukung pembesaran teks, kontras yang terbaca, fokus yang terlihat, dan navigasi keyboard jika platform mendukungnya.
- Pastikan kontrol utama mudah disentuh dan tidak memerlukan ketepatan kecil.
- Periksa teks panjang, layar sempit, state kosong/error, dan orientasi yang didukung sebelum menyatakan UX terverifikasi.
- TTS merupakan peningkatan P1; TTS tidak menggantikan label aksesibel atau teks visual.

## 9. Batas prototipe dan hal yang masih perlu diputuskan

- Prototipe FigCraft mendokumentasikan tampilan dan alur; bukan implementasi Flutter atau validasi usability.
- Login/Daftar adalah eksplorasi UI dan perlu keputusan scope sebelum implementasi autentikasi.
- Finalisasi identitas visual, ikon, dan perilaku navigasi harus mengikuti review desain produk.
- Detail penyimpanan profil/riwayat, persetujuan, serta privasi perlu mengikuti keputusan produk dan kebutuhan implementasi.
- Barcode/OCR, TTS, LLM, dan Food Comparison tetap mengikuti prioritas serta status di PRD, FRD, dan DECISIONS.
- Data nutrisi pada layar hasil dan perbandingan hanya dapat diisi setelah pemetaan sumber dan basis sajian yang dapat diverifikasi tersedia.

## 10. Arah redesign struktural terbaru

Redesign terbaru mempertahankan seluruh 14 layar yang telah terdaftar di atas dan menambahkan sistem navigasi lima tab: **Home, Insight, Scan, History, Profile**. Scan berada di tengah sebagai FAB yang menonjol. Referensi visual digunakan untuk white space, sudut membulat, dan bayangan lembut; palet tetap teal/cyan, putih, serta abu-abu netral. Ungu, merah muda, dan jingga tidak digunakan.

Master component yang ditambahkan ke file FigCraft:

- **MASTER • Card Base** — kartu putih radius `24px`, shadow lembut, Auto Layout vertikal, padding `24px`, gap `8px`.
- **MASTER • Data Ring** — komponen ring berbasis teal dengan latar mint pucat.
- **MASTER • Bottom Navigation 5 tabs** — navigasi lima item dengan FAB Scan di tengah.

Gunakan master tersebut sebagai sumber komponen saat merakit atau menyempurnakan instance layar. Jarak layout mengikuti kelipatan `8px`. Spesifikasi ini adalah target sistem desain; keberadaan master tidak membuktikan semua layar lama telah dirakit ulang sebagai instance.

### Susunan konten layar utama

- **Home:** greeting dan profil singkat, statistik nutrisi hanya dari data yang benar-benar tersedia, lalu daftar horizontal ringkasan analisis terakhir. Jangan menampilkan target atau konsumsi kalori harian rekaan. Data Ring tidak boleh menyiratkan AI mengukur nutrisi langsung dari foto.
- **Insight:** judul “Personalized Nutrition Insight”, penjelasan trade-off gula/sodium/protein, ketidakpastian dan data yang hilang, lalu bagian Food Comparison. Hindari label “Sehat/Tidak Sehat”.
- **Scan:** FAB membuka overlay pemilihan **Packaged Food** (barcode) atau **Unpackaged Food** (kamera). Sebelum hasil, tampilkan kandidat dan confidence klasifikasi serta batas bahwa confidence bukan ketepatan nutrisi. Porsi dikonfirmasi pengguna melalui stepper/slider dengan unit terkonfigurasi.
- **History:** daftar vertikal dari hasil yang benar-benar tersimpan, dengan filter tanggal dan jenis; gunakan empty state jika belum ada riwayat.
- **Profile:** bagian Basic Info, Nutrition Priorities, Food Preferences, serta toggle TTS dan preferensi aplikasi. Tinggi/berat dan alergi bersifat opsional; riwayat penyakit dan obat tidak diminta.

### Alur dan cakupan yang dipertahankan

Semua layar lama tetap menjadi bagian file: Home, Food Scanner, Food Recognition, Portion Confirmation, Nutrition Result, Personalized Insight, Nutrition Profile, Food Comparison, History, Profile & Settings, Splash, Login, Daftar, dan Onboarding Personalization. Lima tab adalah struktur navigasi utama; layar khusus seperti autentikasi/onboarding dan tahap scan tetap mengikuti alur di [SUMMARY.md](SUMMARY.md). Login/Daftar tetap eksplorasi UI dan tidak menjadikan autentikasi bagian MVP.

Flow scan harus tetap `Home → Scan → pilih metode → Recognition/konfirmasi → Portion Confirmation → Nutrition Result → Personalized Insight`. Untuk jalur kemasan, OCR/barcode adalah rancangan tambahan dan hasilnya perlu dikoreksi pengguna. Seluruh angka contoh harus berlabel ilustrasi; nilai nutrisi yang tidak tersedia tetap tidak tersedia, bukan nol.

### Catatan penerapan ke seluruh artboard

Pembaruan visual terbaru diterapkan pada 14 artboard yang dipertahankan: warna aksen kuning pada chips/status diganti ke nuansa teal/mint, dan bingkai perangkat diperbesar radiusnya menjadi `36px`. Kartu lebar pada layar memakai radius `24px` dengan bayangan ringan. Lima artboard navigasi utama memakai instance master navigasi lima tab. Layar proses scan lainnya tetap mengikuti flow layar khusus dan tidak dipaksa memakai navigasi bawah bila mengganggu tugas konfirmasi.

Master Card Base dan Data Ring tersedia di canvas sebagai sumber komponen. Layar lama belum seluruhnya dipecah dan dirakit ulang dari instance Card Base/Data Ring; konten statistik pada Home wajib hanya berasal dari data yang tersedia. Prototipe tidak memuat metrik kalori harian rekaan. Saat meninjau atau melanjutkan implementasi, pastikan label confidence serta keterbatasan model tetap tampak dan tidak memakai klasifikasi “Sehat/Tidak Sehat”.
