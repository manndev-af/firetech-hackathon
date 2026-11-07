    
# Changelog

Semua perubahan penting pada NutriLens AI dicatat di dokumen ini. Format mengikuti prinsip [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versi menggunakan [Semantic Versioning](https://semver.org/spec/v2.0.0.html) setelah proyek mulai membuat rilis; sebelum itu, perubahan dicatat pada bagian **Unreleased**.

## [Unreleased]

### Changed

- Proposal scanner diselaraskan dengan konfigurasi provider, preprocessing 544 × 544 dan gaya TTS v3 yang sudah diterapkan. Handoff Flutter kini mencakup alur multipart, mapping field/nutrisi nullable, koreksi quantity, idempotency dan penanganan error; tidak mengubah endpoint atau frontend.

- Gambar scanner food/label kini dinormalisasi ke JPEG 544 x 544 dengan rasio asli dan padding putih tanpa crop untuk membatasi ukuran input vision. Raw OCR dan validasi upload tetap berlaku; kontrak OpenAPI dan panduan scanner diselaraskan.

- Prompt TTS scanner v3 dan template fallback memakai bahasa Indonesia sehari-hari yang lebih mudah dipahami, dengan sapaan kamu, kalimat pendek dan arahan menghindari jargon/bahasa laporan. Kontrak OpenAPI dan panduan frontend diperbarui.

- Respons konsumsi menyediakan `pros`/`cons` dari insight tersimpan untuk kartu Kelebihan/Kekurangan. Prompt v2 mempertegas personalisasi dari retrieval dan ringkasan TTS atas pro/cons; fallback lokal mencoba insight yang sama. Unit/transport tests lolos dan dua mode service live 9Router lolos tanpa menambah jurnal fixture. Flutter tidak diubah.

- Live smoke test 9Router untuk food dan label lolos validasi service dengan satu dispatch backend per mode (HTTP 200; 7.066/3.330 ms). Retrieval aktual ikut sebelum request; tidak menambah jurnal fixture. Hasil dan batas uji dicatat di README backend; ini bukan pengukuran akurasi nutrisi atau audit retry internal router.

- Base URL DeepSeek kini dibaca dari `DEEPSEEK_BASE_URL` pada environment backend; endpoint tidak lagi ditetapkan langsung di service. Template environment, panduan setup dan tes konfigurasi URL diselaraskan.

- Profil seed development kini berisi fixture lengkap tanpa field null untuk demo, termasuk identitas, personalisasi, alergi, audio, dan timezone. Seed ulang tetap mempertahankan koreksi profil yang sudah ada; tidak membuat konsumsi atau hasil scan fiktif.

- Batas minimal password seed dummy development diturunkan menjadi 5 karakter atas permintaan pengguna; batas maksimal 128, salted scrypt, dan larangan seed production tetap berlaku.

- Template environment backend disiapkan untuk demo lokal MySQL/XAMPP: dummy owner aktif, email/password seed contoh terisi, dan API key DeepSeek acak yang ditandai sebagai placeholder tidak valid untuk scan live.

- Layout dan UX kamera (`ScannerScreen`) diperbarui: viewfinder dilengkapi overlay retikel sudut AI dan badge status deteksi, tombol jepret (shutter) dan galeri ditata lebih modern dan proporsional, serta tipografi diselaraskan dengan standar onboarding.
- Tampilan hasil foto (`ScanResultScreen`) didesain ulang secara menyeluruh mengikuti referensi UI/UX modern:
  - Kandungan gizi kini disajikan dalam format kartu dan badge berikon sesuai tema (Protein, Lemak, Karbohidrat, Serat, Gula, Natrium).
  - Porsi dihitung dalam satuan dengan tombol cepat porsi (`1`, `2`, `3`, `4`) serta kontrol stepper (`-` / `+`), di mana semua nilai gizi langsung dikalikan secara reaktif.
  - Ditambahkan kartu analisis trade-off personal (`Kelebihan` dan `Kekurangan`) dengan indikator ikon dan kontras tema yang jelas.
  - Form koreksi manual dan tombol "Periksa & koreksi" dihilangkan sehingga alur menjadi langsung, bersih, dan intuitif.
  - Data pratinjau lengkap (nama hidangan/produk, kalori 32 px, skor kesehatan `8.0+/10`, tag karakteristik, komposisi hidangan) aktif untuk pengujian realistis.
  - Tipografi diperbesar seukuran onboarding (judul 24 px, angka kalori 32 px, judul kartu 18 px, deskripsi 15 px) sehingga nyaman dibaca dan tidak kekecilan.

### Removed

- Scaffold kosong food_search, food_journal, dan recipes di Flutter dihapus karena belum diperlukan.

- Halaman register Flutter, route/nama/path `/register`, akses Daftar pada login dan navigasi placeholder, serta pengujian khusus register dihapus atas permintaan pengguna.

### Added

- Backend scanner konsumsi development: Prisma MySQL schema/migration/seed dummy, profil sesuai Flutter, upload food/label tervalidasi, RAG SQL dari profil/riwayat/referensi reviewed, satu dispatch DeepSeek per idempotency key, jurnal persisten, koreksi quantity Decimal, daily summary nullable, dan teks ringkas TTS dengan fallback lokal. Kontrak OpenAPI per route dan handoff backend tersedia; Flutter tidak diubah. Tes provider mock pada database MariaDB terisolasi tersedia; live DeepSeek belum diuji tanpa API key.

- Swagger UI dan OpenAPI JSON backend, dengan kontrak health/user terpisah per modul route, schema input user memakai validasi yang sama, serta pengujian HTTP. AGENTS mewajibkan pembaruan OpenAPI setiap perubahan route; README server, WORKSPACE, dan arsitektur menjelaskan penggunaan serta batas endpoint demo.

- Panel nutrisi hasil mengikuti referensi pengguna: ikon/nama, angka besar, pita satuan dan warna per kandungan dalam grid responsif.
- Kartu hasil memprioritaskan energi, protein, gula, dan natrium yang tersedia. Nilai yang belum terbaca dirangkum dalam satu baris; lemak, karbohidrat, dan serat tersedia pada detail Kandungan lainnya. Grid dua kolom berikon berubah menjadi satu kolom saat teks diperbesar.
- Hasil scan langsung tanpa form porsi/deskripsi, pengali sajian untuk label terkonfirmasi, grid nutrisi berikon, dan lingkaran tombol jepret terisi.
- Scan meminta porsi dan deskripsi opsional sebelum hasil; preview kamera mengisi bingkai dengan crop proporsional. Hasil memakai kartu nutrisi responsif dan teks 16/18 px. Porsi tetap catatan pengguna, belum dipakai menghitung nutrisi.
- OCR label di perangkat dengan ekstraksi konservatif, nilai kosong tetap unknown, dan pengujian parser.
- Review foto terhubung ke detail hasil, koreksi angka/sajian/acuan dan teks komposisi asli. Klasifikasi makanan dan penyimpanan hasil belum terhubung.
- Kamera Flutter dari tombol tengah, Beranda, dan Riwayat kosong: preview kamera belakang, mode Makanan/Label produk, galeri, review foto, dan foto ulang. Kamera dilepas saat latar belakang/review; izin, kegagalan, dan lifecycle diuji.
- Panduan `server/src/services/` untuk memisahkan logika bisnis/akses data dari controller; belum ada service domain sebelum kontrak fiturnya ditentukan.
- Setup Prisma ORM 7 untuk MySQL di backend: CLI/client dan MariaDB adapter, schema/config, client singleton lazy, contoh `DATABASE_URL`, serta perintah generate/migrate. Belum ada model domain atau migration.
- Profil memisahkan editor informasi diri dan personalisasi. Detail personalisasi langsung menjadi form inline dengan Simpan/Kembali di bawah; bottom sheet dan langkah Edit tambahan dihapus. Informasi diri dapat disimpan tanpa prioritas, data bagian lain tetap utuh, dan scroll kembali ke ringkasan setelah selesai. Pengujian mencakup alur simpan/batal serta layar sempit dengan teks besar.

- Contoh Riwayat kini langsung tampil melalui tab saat aplikasi dijalankan biasa: tiga makanan dengan foto, porsi, summary, dan detail yang dapat dibuka. Router review mengaktifkan fixture secara default; `UI_PREVIEW=false` tersedia untuk state tanpa contoh. Data contoh tetap tidak disimpan sebagai catatan pengguna.

- Revisi review Profil/Riwayat: ringkasan personalisasi dengan detail, preferensi audio aktif/nonaktif selama sesi, foto lokal dan ringkasan catatan. Filter serta banner demo dihapus dari tampilan; fixture terpisah dapat diaktifkan dengan `UI_PREVIEW=true`. Font Inter disamakan per peran 24/18/16/14. TTS, capture kamera, dan penyimpanan nyata belum terintegrasi. Foto preview berlisensi Unsplash dan sumbernya dicatat dalam audit.

- Personalisasi Profil dilengkapi pola makan, preferensi halal, status/bahan alergi, tinggi dan berat opsional; validasi, konfirmasi pembatalan, dan pemeliharaan field saat onboarding diperbarui. Data masih dalam memori dan belum diterapkan ke engine/pencocokan alergen.
- Preview Riwayat berisi dengan fixture terpisah berlabel ilustrasi, filter jenis/tanggal, kelompok tanggal, detail sumber/porsi/basis, serta pembedaan null dan nol. Tidak menambah catatan pengguna atau API penyimpanan.
- Audit Profil/Riwayat, ekspor PNG widget Flutter, dan pengujian form lengkap, pemisahan preview, keyboard, serta layout teks besar. Hierarki kedua layar dirapikan dengan tema teal/mint dan Inter yang ada.

- Layar Jelajahi, Bandingkan, dan Asisten mengikuti artboard FigCraft; perbandingan meminta dua gambar galeri sebelum ringkasan ilustrasi ditampilkan. Tab/kartu Home membuka Jelajahi; route asisten membedakan pintasan pola catatan dari halaman tanya tanpa chat. Gambar belum diunggah atau dianalisis.
- UI Flutter Profil, editor profil nutrisi, dan Riwayat mengikuti referensi Figcraft serta palet teal–mint pengguna. Profil mendukung nama/usia opsional, lima prioritas jamak, preferensi makanan, validasi, simpan/batal, dan informasi privasi sesi. Riwayat menyediakan filter jenis/tanggal serta empty state tanpa catatan contoh.
- State profil dalam memori menghubungkan onboarding, Profil, dan label fokus Home. Tab History/Profile aktif; kamera memberi status belum tersedia. Penyimpanan permanen, API riwayat, dan integrasi engine/TTS belum ditambahkan.
- Pengujian profil/riwayat untuk validasi, simpan/batal, navigasi, filter, dan layar sempit dengan teks besar. Pengujian onboarding diperbaiki agar menggulir tombol kembali ke layar dan melepas handle semantics sebelum pemeriksaan akhir.

- Font Inter lokal beserta lisensi SIL Open Font License, mapping bobot 400/500/600/700 pada pubspec, dan panduan font di README/WORKSPACE.

- Dashboard NutriLens sesuai referensi Home kosong/berisi, widget riwayat terpisah, serta model ringkasan harian nullable dengan penanda kelengkapan nutrisi. Ringkasan menerima data yang diberikan; belum ada integrasi penyimpanan/scan atau data contoh dalam aplikasi.
- Ilustrasi dashboard lokal dari ekspor pengguna dan pengujian empty state, ringkasan, data hilang, callback, serta teks besar.

- Alur onboarding Flutter sesuai tiga referensi pengguna: pilihan fokus nutrisi, preferensi opsional dengan Lewati dulu, dan ringkasan selesai dinamis menuju beranda. Pilihan dipertahankan saat kembali antar-langkah, masih berupa state UI tanpa penyimpanan/profil engine.
- Route `/onboarding`, komponen pilihan aksesibel, ilustrasi selesai lokal dari ekspor pengguna, dan pengujian navigasi/pilihan/layar sempit. Tombol Google membuka alur demo; autentikasi Google belum terhubung.

- Folder aset Flutter `app/assets/images/` dan `app/assets/icons/`, deklarasi direktori di `pubspec.yaml`, ekspor desain pengguna untuk ilustrasi login, serta panduan aset statis pada WORKSPACE dan README app.

- Layar login Flutter sesuai referensi pengguna dengan tombol Google, layout scroll, serta named route `/login` di luar navigasi bawah. Autentikasi dan pembuatan akun belum diimplementasikan.

- Bottom navigation Flutter dengan ikon dan label tab, penanda tab aktif, serta tombol kamera mengambang di tengah; ditambahkan bersama contoh dashboard.
- Fondasi komunikasi API backend terpisah di Flutter: `ApiClient`, daftar endpoint usulan, hook interceptor, dan `ApiException`.
- Kerangka direktori feature berdasarkan domain food, food journal, recipes, dashboard, dan profile; halaman serta model domain dibuat saat implementasi fiturnya diminta.
- Kerangka arsitektur Flutter untuk `core`, `data`, `features`, dan `shared`, serta app theme teal/cyan yang mengikuti DESIGN.md.
- Fondasi navigasi Flutter dengan `go_router`, named routes untuk flow produk, dan layar placeholder sementara.
- Dokumentasi produk terintegrasi: ringkasan brainstorming, PRD, FRD, dan arsitektur.
- Konsep Nutrition Profile terbaru: prioritas nutrisi, preferensi makanan, serta field usia, tinggi/berat badan, dan alergi dengan status opsional sesuai dokumen.
- Aturan konteks proyek dan alur pemeliharaan changelog untuk AI agent.
- Mekanisme CHANGELOG untuk melacak perubahan penting dalam bagian Unreleased sebelum rilis.

### Changed

- Detail Riwayat tanpa tanda silang, dengan kartu ringkasan dan fokus saat dicatat. Form Profil dirapikan; preview Personalisasi menampilkan seluruh prioritas, pilihan makanan, pola makan, halal, dan alergi dengan hierarki font yang konsisten.

- Aturan Git proyek diperbarui sesuai permintaan pengguna: pekerjaan dan commit langsung di `main`, tanpa pembuatan/perpindahan branch otomatis. AGENTS, WORKSPACE, dan README menegaskan prioritas aturan proyek atas saran branch dari skill generik.

- Konstanta navigasi Insight diganti menjadi Jelajahi: `AppRoutes.explore` (`/explore`) dan `AppRouteNames.explore` (`explore`). Screen Jelajahi kini terdaftar pada shell navigasi.

- Seluruh halaman Flutter memakai Inter melalui tema dan TextTheme global, tanpa dependency tambahan atau unduhan font saat runtime.

- Dashboard contoh toko diganti kartu scan dan Hari ini; fokus onboarding diteruskan ke label kartu. Navigasi bawah tetap menggunakan desain dan callback sebelumnya sesuai permintaan pengguna.

- Login Flutter mengikuti referensi terbaru dengan ilustrasi lokal, latar putih, dan tombol tunggal Lanjutkan dengan Google; form email/kata sandi dihapus. Status prototipe tetap terlihat dan integrasi Google belum terhubung. Pengujian UI serta panduan aset diperbarui.

- Arsitektur Flutter diarahkan ke layer global untuk models, services, repositories, dan providers; folder feature hanya menampung file UI langsung dan widgets, tanpa subfolder `pages/` atau layer data berulang.
- Struktur Flutter memindahkan tanggung jawab model/repository/service ke dalam feature dan menghapus folder data generik serta konfigurasi Supabase dari starter kit.
- Router `go_router` dipindahkan ke `lib/core/router/`; `main.dart` kini memakai `app.dart` sebagai root aplikasi.
- README Flutter dan WORKSPACE diperbarui untuk mencerminkan struktur starter kit; Supabase belum diintegrasikan.
- `MaterialApp` starter diganti `MaterialApp.router` dengan tema teal; README app dan struktur WORKSPACE mencatat setup routing.
- Redesign visual `nutrilens-base.figcraft` melalui MCP FigCraft: foto editorial pada Home/Splash, kamera dengan panel tindakan, foto konfirmasi, perapian 14 artboard, state tab aktif, dan kartu nutrisi Auto Layout. Foto/skor contoh tetap berlabel ilustrasi; palet teal serta scope PRD dipertahankan. DESIGN.md mencatat hasil dan batas verifikasinya.

- Seluruh 14 artboard FigCraft diselaraskan ke palet teal/mint dengan frame lebih membulat dan kartu berbayang lembut; lima layar navigasi utama menggunakan instance bottom navigation lima tab.
- Prototipe FigCraft menerima master component Card Base, Data Ring, dan navigasi lima tab; DESIGN.md mencatat arah redesign teal/cyan dan susunan konten layar tanpa menghapus 14 layar yang sudah ada.
- DESIGN.md diperbarui agar mencerminkan token visual dan pola tata letak pada prototipe FigCraft, serta mencantumkan 14 layar dan alur navigasinya. Login/Daftar ditandai sebagai eksplorasi UI, bukan komitmen autentikasi MVP.
- Dokumentasi menegaskan batas personalisasi: profil memengaruhi fokus insight/perbandingan, bukan nilai nutrisi sumber; kalkulasi dilakukan deterministik dan LLM hanya menjelaskan hasil.
- Struktur repository pada panduan agent dan summary diselaraskan dengan proyek Flutter di `app/` dan backend di `server/`, termasuk README lokal masing-masing.
- Panduan workspace lama yang merujuk proyek lain diganti dengan layout NutriLens AI, rujukan dokumen, dan alur kolaborasi `main`/`development`.
- Aturan sinkronisasi dokumentasi disesuaikan dengan dokumen aktif, komponen, serta batas produk NutriLens AI.
- Dokumen desain UI, register keputusan, dan aturan mutu UI yang sebelumnya berisi konteks proyek lain diselaraskan dengan NutriLens AI.

### Fixed

### Removed

### Security

- Aturan ignore root mencakup file konfigurasi rahasia lokal, dataset unduhan, cache, dan bobot model; file `.env.example` tetap dapat dibagikan.

