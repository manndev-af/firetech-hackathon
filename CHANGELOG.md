    
# Changelog

Semua perubahan penting pada NutriLens AI dicatat di dokumen ini. Format mengikuti prinsip [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versi menggunakan [Semantic Versioning](https://semver.org/spec/v2.0.0.html) setelah proyek mulai membuat rilis; sebelum itu, perubahan dicatat pada bagian **Unreleased**.

## [Unreleased]

### Changed

- Decoder gambar, transport JSON vision dan tipe input kalkulasi nutrisi scanner dipisahkan untuk pemakaian ulang compare; kontrak dan perilaku scanner tetap dipertahankan.

### Fixed

- Backend scan label membedakan energi total dari energi lemak/AKG, menerima variasi spasi evidence OCR, serta membatalkan insight/TTS dari angka ditolak. Basis gram/ml per sajian dinormalisasi ke satu porsi; hitungan quantity tetap deterministik.
- Parser saran label Flutter mengenali label bilingual, LemakJenuh dan satuan kkal/kcal tanpa mencampur energi lemak atau AKG.
- OCR lokal opsional tidak lagi menghalangi analisis gambar oleh backend saat gagal/kosong/tanpa kata kunci; mode OCR wajib tersedia lewat dart-define SCANNER_USE_RAW_OCR=true. Batas teks diselaraskan menjadi 20.000 karakter.

### Added

- Service frontend integrasi backend `ProfileApi` (`app/lib/services/profile_api.dart`):
  - Berkomunikasi dengan endpoint `GET` dan `PATCH /api/v1/profile` untuk mengambil dan menyinkronkan profil nutrisi aktif serta status preferensi `audioAnalysisEnabled`.
- Service frontend integrasi backend `JournalApi` (`app/lib/services/journal_api.dart`):
  - Menangani pembacaan riwayat konsumsi (`GET /api/v1/food-entries`), rincian entri (`GET /api/v1/food-entries/:id`), penyesuaian porsi deterministik (`PATCH /api/v1/food-entries/:id/quantity`), penghapusan entri (`DELETE /api/v1/food-entries/:id`), dan pembacaan total akumulasi harian (`GET /api/v1/nutrition/daily`).
- Suite pengujian unit `app/test/backend_services_test.dart`:
  - Menguji `ProfileApi` (get & patch profile) dan `JournalApi` (list, quantity update, delete, dan getDailyNutrition) beserta pemetaan `DailyNutritionSummary` secara terisolasi dengan mock HTTP server lokal.

- Morgan development kini menulis log JSON request/response ke `server/src/logs/requests-YYYY-MM-DD.log`, dengan metadata upload, penyamaran kredensial/data privat/gambar dan batas ukuran. Folder otomatis dibuat dan diabaikan Git; panduan debugging serta workspace diperbarui.

- Contoh riwayat awal (`sampleHistoryEntry`) pada inisialisasi lokal (`initializeLocalState`):
  - Menyediakan 1 contoh catatan riwayat nyata (*"Yogurt Stroberi & Granola"*, porsi 150 g, 140 kkal, 8 g protein, 12 g gula) saat penyimpanan lokal pengguna masih kosong.
  - Memungkinkan pengujian langsung fitur suara Text-to-Speech (TTS) lokal tanpa harus mengambil atau memindai foto makanan terlebih dahulu.
  - Dilengkapi ringkasan kesimpulan singkat (`spokenSummary`) yang ramah aksesibilitas: *"Porsi camilan baik dengan 8 gram protein. Perhatikan 12 gram gula sesuai target harianmu."*

- Kolom deskripsi tambahan opsional setelah memotret pada peninjauan kamera (`ScannerScreen`):
  - Tampil di bawah pilihan mode saat foto berhasil diambil atau dipilih dari galeri, berlaku untuk mode Makanan maupun Label produk.
  - Dilengkapi label "Deskripsi tambahan", badge penanda "Opsional", ikon pensil/catatan, pembatasan 140 karakter, dan tombol bersihkan teks.
  - Menyediakan *hint text* kontekstual dinamis: contoh porsi & racikan masakan (*"Contoh: 1 mangkok sedang, tanpa kuah santan, sambal dipisah"*) untuk mode makanan, dan contoh varian/kemasan (*"Contoh: Varian cokelat, botol 250 ml, rasa tawar"*) untuk mode label produk.
  - Terintegrasi penuh ke dalam `ScanDraft.note`, `ScanHistoryEntry.userNote`, payload API (`userNote`), serta ditampilkan di kartu rincian riwayat dan hasil analisis (`AnalysisContent`).
- Halaman pembuka animasi (Splash Screen) pada `app/lib/features/splash/splash_screen.dart`:
  - Menampilkan logo resmi aplikasi (`assets/icons/iconaplikasi.png`) dengan animasi fade-in dan scale halus, nama merek `nutrisee`, badge `Personalized Nutrition AI`, tagline *"Pahami kandungan, pilih sesuai prioritasmu"*, serta indikator loading berputar.
  - Penentuan rute awal (`initialLocation: AppRoutes.splash`) dengan navigasi cerdas setelah durasi splash: mengarahkan pengguna ke Beranda jika profil nutrisi sudah terisi, atau ke halaman Login/Onboarding jika profil belum diatur.
  - Tahan terhadap reflow layar sempit (320 px) dan pembesaran font (2.0x) tanpa overflow layout.
- Pembaruan ikon launcher aplikasi Android (`ic_launcher.png` dan `ic_launcher_round.png`) menggantikan ikon default Flutter:
  - Dihasilkan dari aset logo resmi `assets/icons/iconaplikasi.png` dalam berbagai resolusi standar (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
  - Pembaruan `AndroidManifest.xml` dengan nama aplikasi launcher `NutriSee` serta dukungan `android:roundIcon`.
  - Integrasi splash layar awal native Android (`launch_background.xml` dan `drawable-v21/launch_background.xml`) menampilkan ikon NutriSee di tengah latar putih untuk transisi mulus saat aplikasi pertama kali dibuka.

### Changed

- Integrasi penuh frontend Flutter (`app/`) mengikuti arsitektur backend Node.js (`server/`) yang telah tersedia:
  - `ApiClient`: Ditambahkan dukungan untuk request `PATCH`, `DELETE` (penanganan status 204 No Content), dan `postMultipart` untuk pengunggahan file JPEG biner (`image`) beserta field metadata (`mode`, `rawOcrText`, `description`, `quantity`) dan header `Idempotency-Key`.
  - `ScanHistoryEntry`: Model diperluas mencakup 8 nutrisi lengkap (`totalFatG`, `saturatedFatG`, `carbohydratesG`, `fiberG`, `energyKcal`, `proteinG`, `sugarG`, `sodiumMg`), field kuantitas & porsi reaktif (`quantity`, `baseQuantity`), insight kualitatif personal (`pros`, `cons`), metadata `provenance`, dan `ttsSummarySource`.
  - `AnalysisApi`: Refaktor request scan mengarah ke `POST /api/v1/scans` menggunakan multipart form data, menangani kode status `201 Created` dan `200 OK`, dengan pemetaan bersih via `ScanHistoryEntry.fromBackend` serta mempertahankan fallback lokal saat offline.
  - `AnalysisContent` & `ScanResultScreen`: Menghapus estimasi sintetis hardcode dan menggantinya dengan nilai 8 nutrisi riil backend; merender poin `pros` dan `cons` secara dinamis; menghubungkan koreksi porsi ke `PATCH /api/v1/food-entries/:id/quantity` untuk rekalkulasi deterministik.
  - `HistoryEntryCard`: Menambahkan tombol hapus pada lembar rincian riwayat yang memanggil `DELETE /api/v1/food-entries/:id` di backend dan membersihkan entri dari cache lokal.
  - `LocalAppState` & `app_router.dart`: Mengintegrasikan sinkronisasi riwayat (`syncHistoryFromBackend`) dan ringkasan nutrisi harian (`fetchDailyNutritionFromBackend`) dari backend, menampilkan akumulasi asupan riil pada Beranda dengan fallback komputasi lokal deterministik saat offline.

- Raw OCR scanner sementara nonaktif secara default melalui `SCANNER_USE_RAW_OCR=false`: label dianalisis dari gambar, tanpa OCR pada retrieval/payload/validasi evidence. Set true mengembalikan gambar + OCR wajib; data OCR yang disertakan tetap tersimpan dan menjadi fingerprint. Prompt v4, OpenAPI, contoh environment dan handoff diselaraskan.

- Rate limiter global API dinonaktifkan atas permintaan pengguna agar validasi X-Forwarded-For dari express-rate-limit tidak mengganggu request melalui proxy. Batas concurrency dua operasi scanner tetap berlaku; OpenAPI dan panduan backend diselaraskan.

- Proposal scanner diselaraskan dengan konfigurasi provider, preprocessing 544 × 544 dan gaya TTS v3 yang sudah diterapkan. Handoff Flutter kini mencakup alur multipart, mapping field/nutrisi nullable, koreksi quantity, idempotency dan penanganan error; tidak mengubah endpoint atau frontend.

- Gambar scanner food/label kini dinormalisasi ke JPEG 544 x 544 dengan rasio asli dan padding putih tanpa crop untuk membatasi ukuran input vision. Raw OCR dan validasi upload tetap berlaku; kontrak OpenAPI dan panduan scanner diselaraskan.

- Prompt TTS scanner v3 dan template fallback memakai bahasa Indonesia sehari-hari yang lebih mudah dipahami, dengan sapaan kamu, kalimat pendek dan arahan menghindari jargon/bahasa laporan. Kontrak OpenAPI dan panduan frontend diperbarui.

- Respons konsumsi menyediakan `pros`/`cons` dari insight tersimpan untuk kartu Kelebihan/Kekurangan. Prompt v2 mempertegas personalisasi dari retrieval dan ringkasan TTS atas pro/cons; fallback lokal mencoba insight yang sama. Unit/transport tests lolos dan dua mode service live 9Router lolos tanpa menambah jurnal fixture. Flutter tidak diubah.

- Live smoke test 9Router untuk food dan label lolos validasi service dengan satu dispatch backend per mode (HTTP 200; 7.066/3.330 ms). Retrieval aktual ikut sebelum request; tidak menambah jurnal fixture. Hasil dan batas uji dicatat di README backend; ini bukan pengukuran akurasi nutrisi atau audit retry internal router.

- Base URL DeepSeek kini dibaca dari `DEEPSEEK_BASE_URL` pada environment backend; endpoint tidak lagi ditetapkan langsung di service. Template environment, panduan setup dan tes konfigurasi URL diselaraskan.

- Profil seed development kini berisi fixture lengkap tanpa field null untuk demo, termasuk identitas, personalisasi, alergi, audio, dan timezone. Seed ulang tetap mempertahankan koreksi profil yang sudah ada; tidak membuat konsumsi atau hasil scan fiktif.

- Batas minimal password seed dummy development diturunkan menjadi 5 karakter atas permintaan pengguna; batas maksimal 128, salted scrypt, dan larangan seed production tetap berlaku.

- Template environment backend disiapkan untuk demo lokal MySQL/XAMPP: dummy owner aktif, email/password seed contoh terisi, dan API key DeepSeek acak yang ditandai sebagai placeholder tidak valid untuk scan live.

- Perapian tata letak (layout) dan desain visual lembar rincian riwayat makanan (`HistoryEntryDetail` dan `AnalysisContent`):
  - Mengatur ulang struktur *drawer* modal bawah (`showModalBottomSheet`) dengan header tetap (*fixed top bar*) berisi *drag handle pill*, ikon riwayat, judul "Rincian Riwayat Makanan", dan tombol tutup (`Icons.close_rounded`) yang tidak ikut tergulir.
  - Mengharmoniskan palet warna latar belakang `AppColors.background` (`#F7FBFA`) dan kartu putih bergaris tepi halus (`AppColors.border`), menghilangkan kesan kotak-kotak terpisah yang tidak teratur.
  - Menggabungkan metrik kalori dan skor kualitas gizi dalam satu kartu informasi identitas makanan yang ringkas berdampingan dengan tanggal dan porsi awal.
  - Memposisikan kontrol porsi (*portion stepper* dan *quick chips* 1x, 2x, 3x, 4x) secara langsung setelah metrik energi, sehingga penyesuaian porsi langsung terlihat dampaknya secara visual pada nilai energi dan nutrisi.
  - Menyatukan makronutrisi (Protein, Lemak, Karbohidrat) dan mikronutrisi (Serat, Gula, Natrium) ke dalam satu kartu "Kandungan Nutrisi" terpadu dengan tata letak 3 kolom yang proporsional dan *reflow* otomatis pada layar sempit/skala font besar tanpa *render flex overflow*.
  - Mengelompokkan analisis dan *trade-off* personal secara terstruktur: kartu kesimpulan AI dengan tombol putar/hentikan suara TTS, kartu ringkasan *trade-off* dengan sorotan fokus saat dicatat, serta kartu kelebihan (hijau lembut) dan kekurangan (merah muda lembut) yang elegan tanpa emotikon.
  - Merapikan *expansion tile* "Tentang data nutrisi" dan deskripsi catatan pengguna dengan batas visual yang konsisten.


- Perbaikan batas outline tombol kamera pada Bottom Navigation Bar (`BottomNav` & `BottomNavPainter`):
  - Tombol aksi kamera mengambang diposisikan sejajar (`top: 20`, 56x56 px) dengan outline putih (`Border.all(color: Colors.white, width: 3.0)`) yang senada dengan warna dasar navbar, dan tidak keluar dari jalur garis tepi outline navbar.
  - Lengkungan notch diperhalus memeluk tombol kamera dengan rapi serta diberi goresan border halus bertema pada jalur outline navigasi bawah.
- Penyesuaian nada suara (*pitch / voice tune*) dan kecepatan bicara (*speech rate*) TTS pada `SummarySpeech`:
  - Nada suara (*pitch*) diatur ke nilai standar alami (`1.0`).
  - Kecepatan bicara (*speech rate*) diatur ke `0.45` (berada di antara rentang santai 0.4 dan 0.5) agar pelafalan ringkasan kesimpulan terdengar jelas, tenang, dan mudah dipahami.
- Tombol kembali (panah back) dan identitas roomchat pada asisten nutrisi AI (`AssistantScreen`) dijadikan fixed (statis) di bagian atas layar:
  - Tombol panah kembali beserta judul dan status konteks percakapan ditempatkan di top bar tetap di luar area scrollable, sehingga tidak ikut ter-scroll ke atas saat pesan percakapan memanjang.
  - Pengguna dapat menekan tombol kembali kapan saja dengan mudah tanpa perlu menggulir ke paling atas layar chat.

- Halaman Jelajahi (`ExploreScreen`), Perbandingan (`CompareScreen`), dan Konsultasi AI (`AssistantScreen`) diperbarui secara terstruktur:
  - Navigasi atas tetap (`TopNav`) disematkan pada halaman Jelajahi dengan logo resmi `assets/icons/iconaplikasi.png` dan nama aplikasi `nutrisee`, seragam dengan Beranda, Profil, dan Riwayat.
  - Tiga kartu navigasi utama ditata rapi dengan ikon Material bertema dan badge informatif tanpa emotikon: "Bandingkan dua pilihan", "Lihat pola catatanku", dan "Tanya soal makanan".
  - Layar "Bandingkan dua pilihan" (`CompareScreen`) menyediakan alur pemilihan foto melalui Kamera (`ImageSource.camera`) maupun Galeri (`ImageSource.gallery`), menyajikan perbandingan nilai gizi berdampingan (energi, protein, gula) dengan ringkasan kesimpulan "Mending yang mana?", serta tombol "Bahas pilihan ini" untuk melanjutkan analisis ke ruang percakapan AI.
  - Layar "Asisten gizi" (`AssistantScreen`) menyediakan antarmuka chat AI modern untuk konsultasi gizi, analisis pola konsumsi riwayat pengguna, maupun pembahasan perbandingan dua pilihan makanan:
    - Gelembung pesan interaktif bergaya modern (pesan pengguna dengan latar teal `AppColors.heroBackground`, jawaban AI dengan kartu putih dan badge `NutriSee AI`).
    - Input pertanyaan (`TextField`) dengan tombol kirim responsif dan dukungan pintasan keyboard.
    - Chip pertanyaan cepat yang dinamis dan relevan tanpa pengulangan pertanyaan yang sudah diajukan.
    - Struktur layout menggunakan `SingleChildScrollView` untuk memastikan scrolling dan pembaruan riwayat chat akurat tanpa estimasi berlebih.
- Validasi kata kunci nilai gizi OCR label kemasan: fungsi `containsNutritionKeywords` memvalidasi keberadaan istilah tabel gizi dalam bahasa Indonesia maupun Inggris (antara lain `informasi nilai gizi, nilai gizi, takaran saji, energi, kalori, lemak, protein, karbohidrat, gula, natrium, nutrition facts, calories, fat, sugar, sodium`). Jika tidak ada kata kunci yang cocok, pemrosesan label langsung melempar `ScanFailure` lokal tanpa membuang kuota/request ke AI.
- Penanganan kegagalan deteksi objek makanan/minuman dan label gizi tidak lagi berpindah ke halaman baru, melainkan menampilkan dialog popup peringatan yang bersih dan rapi langsung di layar kamera (`ScannerScreen`) dengan tombol "Foto Ulang" untuk kembali ke jendela bidik kamera dengan cepat.
- Tombol aksi utama di bagian bawah layar hasil scan (`ScanResultScreen`) diubah menjadi tombol "Simpan ke Riwayat" yang berlabuh di footer bawah layar (`footer:` pada `PersonalPage`), menggantikan opsi navigasi foto lain dan mempertegas fungsi pemindaian sebagai pencatatan konsumsi pengguna, lengkap dengan notifikasi konfirmasi SnackBar mengambang. Eksplorasi perbandingan dan konsultasi diarahkan ke fitur Jelajah.
- Tampilan rincian riwayat produk kemasan (`HistoryEntryDetail`) disatukan sepenuhnya menggunakan `AnalysisContent` sehingga memiliki tata letak kartu yang identik dengan foto makanan segar: foto hero dengan badge AI, kalori 32 px, skor kesehatan, kartu makronutrisi berikon, badge mikronutrisi, selector porsi interaktif (stepper + chip 1-4), analisis trade-off personal (Kelebihan & Kekurangan), dan pemutar suara TTS kesimpulan singkat.

- Beranda (`DashboardScreen`, `DashboardScanCard`, `DashboardHistory`) diperbarui secara menyeluruh mengikuti hierarki visual dan prinsip Personalized Nutrition:
  - Navigasi atas tetap (`TopNav`) menampilkan logo resmi `assets/icons/iconaplikasi.png` dan nama aplikasi `nutrisee` secara konsisten dengan layar lainnya.
  - Sapaan kontekstual waktu (`SELAMAT PAGI / SIANG / SORE / MALAM`), tipografi utama yang mudah dibaca (`Makan dengan lebih paham.`), dan penanda fokus nutrisi personal.
  - Kartu hero pemindaian makanan (`DashboardScanCard`) menggunakan latar teal tema (`AppColors.heroBackground`), ilustrasi semangkuk makanan, arahan pemindaian yang jelas, dan tombol aksi "Foto makanan" berwarna mint dengan ikon kamera tanpa emotikon.
  - Kartu "Analisis Terakhir" (`_RecentAnalysisCard`) menyajikan pratinjau instan dari makanan terakhir yang dianalisis: thumbnail foto/aset, nama makanan, porsi, tanggal/waktu, ringkasan analisis trade-off 1–2 kalimat, dan badge nutrisi tanpa emotikon.
  - Ringkasan "Nutrisi Tercatat Hari Ini" (`DashboardHistory`) menampilkan metrik gula, protein, dan energi dengan ikon Material bertema, membedakan secara tegas nilai null dari nol nyata, memberikan peringatan data nutrisi belum lengkap bila ada entri yang belum lengkap, serta mempertahankan tombol jelajah perbandingan ("Buka Jelajah  →").
  - Penghubungan reaktif `app_router.dart` dengan `historySession` untuk menghitung `DailyNutritionSummary` hari ini dan menampilkan analisis terbaru secara otomatis.

- Integrasi Flutter lokal untuk Object Detection + Image Labeling sebelum request foto makanan diperluas mencakup deteksi minuman (teh, susu, kopi, jus, smoothie, soda, air, dsb.) serta cadangan label hidangan bila object detector belum mendeteksi. Menolak objek non-makanan secara lokal agar tidak boros request ke backend. Mode label OCR membypass gate makanan, mengirim raw text OCR serta foto resized JPEG sebagai backup visual untuk LLM. Kontrak endpoint didokumentasikan di `docs/SCAN_API.md`; backend AI masih dalam pengembangan dan disiapkan siap disambungkan.
- Profil, preferensi audio, draft scan, foto/OCR, dan hasil analisis disimpan lokal dengan snapshot backup. Riwayat dapat melanjutkan draft; fixture tidak menjadi data pengguna. Nilai contoh tidak lagi menjadi fallback hasil scan nyata.
- Flutter TTS membacakan kesimpulan pendek (maksimal dua kalimat / 320 karakter) saat audio profil diaktifkan, bukan membacakan keseluruhan analisis panjang. Teks kesimpulan disimpan di Riwayat dan dapat dibacakan ulang secara lokal lewat TTS kapan saja melalui kartu riwayat (`HistoryEntryCard`) maupun detail analisis (`AnalysisContent`).
- Aksesibilitas tombol audio pada `HistoryEntryCard` menggunakan penataan `Wrap` responsif yang tahan reflow layar 320 px dengan pembesaran teks, serta penanganan error audio yang ramah pengguna.

- Komponen navbar atas bersama (`TopNav` pada `app/lib/shared/widgets/navigation/top_nav.dart`) ditambahkan:
  - Bersifat fixed di atas layar dan menjadi shared component seperti halnya `BottomNav`.
  - Menggunakan logo resmi aplikasi dari aset (`assets/icons/iconaplikasi.png`) dan menampilkan nama aplikasi `nutrisee`.
  - Disematkan secara konsisten pada layar Profil, Riwayat (`PersonalPage`), serta halaman hasil scan (`ScanResultScreen`).
- Penghapusan seluruh tag hashtag (`#tag`) yang tidak berfungsi pada tampilan hasil foto (`ScanResultScreen`) dan rincian riwayat (`HistoryEntryDetail`).
- Penghapusan penggunaan emotikon/emoji pada seluruh badge aplikasi:
  - Badge pil pada kartu riwayat (`HistoryEntryCard`) kini bersih tanpa emoji (`🔥`, `🥚`), mengutamakan keterbacaan teks dan tata letak yang profesional.
  - Memastikan seluruh status dan indikator hanya menggunakan ikon vektor Material bertema.

- Layout dan output tampilan riwayat (`HistoryEntryDetail` dan `HistoryEntryCard`) diselaraskan menyerupai output hasil foto kamera:
  - Tampilan detail riwayat menampilkan foto hero dengan badge AI, judul 24 px, kalori 32 px, skor kesehatan (`8.0+/10`), kartu makronutrisi berikon (Protein, Lemak, Karbohidrat), badge mikronutrisi (Serat, Gula, Natrium), kartu analisis trade-off (`Kelebihan` dan `Kekurangan`), serta kontrol interaktif porsi (`1`, `2`, `3`, `4` dan stepper `-` / `+`) yang mengalikan nilai gizi secara reaktif.
  - Kartu daftar riwayat diperbarui dengan sudut 22 px, pil informasi kalori dan protein, serta tipografi yang jelas dan mudah dibaca.
- Tata letak komponen layar Profil (`ProfileScreen`) dirasionalisasi menjadi hierarki yang lebih intuitif dan bersih:
  - Kartu identitas pengguna tampil elegan dengan avatar bergradien tema, nama pengguna tebal, status usia, dan tombol edit profil.
  - Kartu personalisasi dikelompokkan secara logis ke dalam 3 sub-bagian: Fokus Nutrisi (chip badge bertema), Pola & Preferensi Makan (pilihan makanan, pola makan, preferensi halal dengan ikon jelas), dan Keamanan Makanan (informasi alergen).
  - Pengaturan (Audio analisis dan Privasi dan data) dikemas rapi dalam kartu kontainer dengan pemisah halus.
- Palet warna dan tombol kamera diselaraskan dengan tema aplikasi:
  - Tombol tengah kamera pada navigasi bawah (`BottomNav`) diperbarui dengan gradien tema NutriLens (`AppColors.cyan` ke `AppColors.heroBackground`), cincin tepi putih 3.5 px, dan bayangan lembut agar serasi dengan keseluruhan antarmuka.
  - Penyelarasan warna `PersonalColors` dengan `AppColors.mint` dan `AppColors.border`.
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

- Instalasi backend pnpm: tetapkan izin build Prisma dan penolakan script Scarf dalam `server/pnpm-workspace.yaml` untuk mengatasi `ERR_PNPM_IGNORED_BUILDS`; dokumentasikan instalasi Windows dan generate client awal.

### Removed

### Security

- Aturan ignore root mencakup file konfigurasi rahasia lokal, dataset unduhan, cache, dan bobot model; file `.env.example` tetap dapat dibagikan.

