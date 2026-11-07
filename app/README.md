# NutriLens AI — Flutter App

Aplikasi mobile NutriLens AI berada di folder ini. Baca [panduan root](../AGENTS.md), [ringkasan produk](../docs/SUMMARY.md), [PRD](../docs/PRD.md), [FRD](../docs/FRD.md), dan [panduan UI](../docs/DESIGN.md) sebelum mengembangkan fitur.

## Menjalankan aplikasi

Pastikan Flutter SDK sesuai batas versi di `pubspec.yaml`, lalu dari folder `app/` jalankan:

```bash
flutter pub get
flutter run
```

## Routing

Tujuan Jelajahi menggunakan `AppRoutes.explore` (`/explore`) dan `AppRouteNames.explore` (`explore`). Route tersebut kini terhubung ke tab Jelajahi pada shell navigasi. `/comparison` dan `/assistant` membuka halaman detail di atas shell; halaman asisten menerima `extra: true` untuk pintasan pola catatan yang menampilkan tampilan percakapan.

Navigasi menggunakan `go_router`. Konfigurasi utama ada di `lib/core/router/app_router.dart`, sedangkan nama dan path route ada di `lib/core/router/route_paths.dart`. Aplikasi saat ini dimulai dari `/login`. Route `/login` merender `LoginScreen` di luar shell navigasi bawah. Halaman, route, dan akses pendaftaran telah dihapus. Dashboard `/home`, Jelajahi `/explore`, Riwayat `/history`, dan Profil `/profile` berada di shell. Tombol Kamera masih memberi pemberitahuan bahwa fitur belum tersedia. `/comparison` dan `/assistant` adalah halaman detail di luar shell.

## Jelajahi, perbandingan, dan asisten

- Tab Jelajahi dan kartu Buka Jelajah dari Home membuka `ExploreScreen`.
- Bandingkan dua pilihan membuka `CompareScreen` (`/comparison`). Minuman A/B dan nilai gizi pada layar hanya data ilustrasi dari referensi desain, bukan data nutrisi terverifikasi.
- Perbandingan meminta dua gambar dari galeri sebelum membuka ringkasan. Gambar ditampilkan dari file lokal; belum diunggah ke backend atau dianalisis. Ringkasan masih memakai nilai ilustrasi.
- Lihat pola catatanku membuka `AssistantScreen` dengan tampilan percakapan contoh. Tanya soal makanan membuka halaman asisten tanpa tampilan chat.
- Tidak ada catatan makanan, lookup nutrisi, kalkulasi, pengiriman chat, atau jawaban LLM yang terhubung. Tampilan percakapan bersifat prototipe.

Halaman login berada di `lib/features/auth/login_screen.dart` dan dapat dibuka menggunakan `context.go(AppRoutes.login)`. UI mengikuti referensi terbaru: latar putih, wordmark nutrilens, ilustrasi makanan, judul “Kenali isi piringmu.”, dan satu tombol “Lanjutkan dengan Google”. Form email/kata sandi telah dihapus. Tombol Google membuka onboarding sebagai alur demo; status prototipe/login belum terhubung tetap terlihat. Tidak ada proses OAuth, pengiriman kredensial, atau sesi akun. Layout dapat digulir pada layar kecil dan saat teks diperbesar.

## Onboarding

Route `/onboarding` berada di luar shell dan merender `features/onboarding/onboarding_screen.dart`. Container ini mengatur tiga layar: `onboarding_focus_screen.dart` (01/02), `onboarding_preference_screen.dart` (02/02), dan `onboarding_finish_screen.dart`. Komponen khusus alur berada di `features/onboarding/widgets/`.

- Langkah 1 memilih satu fokus: Gula, Protein, Natrium, atau Keseimbangan; default Gula mengikuti referensi.
- Langkah 2 memilih satu preferensi opsional: Masakan rumahan, Praktis dan cepat, atau Lebih banyak nabati; default Masakan rumahan mengikuti referensi. Lanjutkan menerima pilihan, sedangkan Lewati dulu mengosongkan preferensi.
- Layar selesai menampilkan fokus aktual dan preferensi jika dipilih, lalu Ke beranda membuka `/home`. Tombol kembali dan back sistem berpindah ke langkah sebelumnya; dari langkah pertama menuju login. Pilihan dipertahankan ketika kembali di dalam alur.
- Pilihan hanya hidup di state UI selama onboarding. Keluar dari alur/memulai ulang mengembalikan default; fokus terpilih diteruskan ke label dashboard sebagai route extra, tanpa penyimpanan permanen atau penerapan ke engine. Ini bukan implementasi lengkap Nutrition Profile.
- `assets/images/onboarding_finish_reference.png` berasal dari ekspor pengguna `Group-16.png`; hanya area ilustrasi dirender. Aset bukan hasil scan atau referensi nutrisi.

## Dashboard dan ringkasan hari ini

`features/dashboard/dashboard_screen.dart` mengikuti referensi Home kosong/berisi. Kartu scan berada di `widgets/dashboard_scan_card.dart`; bagian riwayat berada di `widgets/dashboard_history.dart`.

- Tanpa `summary`, layar menampilkan Belum ada catatan dan Catat makanan pertama. Tidak ada angka contoh yang dimasukkan ke data aplikasi.
- `DashboardScreen(summary: DailyNutritionSummary(...))` menerima ringkasan catatan hari ini yang sudah dihitung dari data terkonfirmasi oleh integrasi berikutnya. Model global ada di `models/daily_nutrition_summary.dart`: jumlah catatan positif, total gula/protein/energi nullable, dan penanda kelengkapan tiap nutrisi. Widget hanya memformat nilai yang diberikan; belum ada penyimpanan, pengambilan riwayat, atau kalkulasi nutrisi baru.
- Nilai null tampil sebagai Belum tersedia, angka nol yang diketahui tetap nol, dan nutrisi yang hilang/ditandai parsial menghasilkan catatan belum lengkap. Ringkasan bukan target atau total konsumsi harian di luar makanan yang dicatat.
- Fokus onboarding dibawa lewat `GoRouterState.extra` dan divalidasi terhadap empat opsi yang tersedia. Akses langsung `/home` tanpa fokus menampilkan Belum dipilih; route extra tidak disimpan setelah restart/reload.
- Foto makanan dan Catat makanan pertama memakai callback `onScan`; kartu Buka Jelajah membuka tab Jelajahi. Callback kamera tetap memberi pemberitahuan fitur belum tersedia. Riwayat tersimpan belum ada.
- Navigasi bawah tetap memakai desain sebelumnya: latar berlekuk, tombol kamera hijau mengambang, dan label Beranda/Jelajahi/Riwayat/Profil. Empat tab konten kini terhubung ke empat branch shell. Konten dashboard memiliki padding bawah agar tidak tertutup bar.
- `assets/images/dashboard_reference.png` adalah ekspor pengguna `Group-18.png`; hanya area ilustrasi kartu yang dirender. Teks, tombol, dan ringkasan merupakan widget Flutter. Setelah menambah aset, hentikan dan jalankan ulang aplikasi agar bundle baru terbentuk.

## Profil dan Riwayat

Revisi Profil terbaru: ikon Edit profil membuka nama, usia, tinggi, dan berat langsung di halaman. Lihat detail pada Personalisasi membuka seluruh form prioritas, pilihan makanan, dan alergi di bawah judulnya, tanpa bottom sheet atau tombol Edit tambahan. Tombol Simpan/Kembali berada di akhir form; data kedua bagian dipertahankan secara terpisah. Selesai mengedit mengembalikan halaman ke ringkasan. Uraian bottom sheet di catatan sebelumnya sudah digantikan.

Revisi review pengguna 7 November 2026 menggantikan uraian UI awal berikut: Profil menampilkan ringkasan lalu Lihat detail, serta sakelar Audio analisis aktif/nonaktif dalam sesi. TTS belum terintegrasi. Riwayat memakai foto dan ringkasan singkat, tanpa filter atau label demo. `ScanHistoryEntry.photoPath` menerima file foto lokal; file tidak tersedia memiliki fallback. Asal data dan Acuan perhitungan dapat dibuka di detail.

Riwayat terisi kini langsung terlihat saat menjalankan `flutter run`, sesuai permintaan review pengguna. Tiga contoh: yogurt stroberi, nasi/ayam/sayur, dan teh tawar, lengkap dengan foto, porsi, ringkasan, serta detail analisis. Router memakai `UI_PREVIEW` dengan default `true`; jalankan `flutter run --dart-define=UI_PREVIEW=false` untuk melihat state tanpa fixture. Angka/foto hanya bahan review desain, bukan hasil analisis/kamera nyata, dan tidak masuk ke penyimpanan atau ringkasan pengguna. Font Inter memakai ukuran menurut peran 24/18/16/14. Sumber foto dan hasil review ada dalam [audit](../docs/PROFILE_HISTORY_AUDIT.md#revisi-setelah-review-pengguna).

### Catatan implementasi awal

Pembaruan 7 November 2026 menggantikan status navigasi/profil pada uraian dashboard terdahulu:

- Tab History membuka `/history`; Profile membuka `/profile`; editor berada di `/profile/nutrition`. Home tetap branch pertama. Insight dan tombol kamera memberi pemberitahuan belum tersedia, bukan membuka route yang tidak ada.
- `features/profile/` memuat ringkasan dan editor lima bagian: prioritas jamak, preferensi/pola makan/halal, alergi, nama/usia, serta tinggi/berat. Semua selain minimal satu prioritas bersifat opsional. Simpan memvalidasi draft; Batal/Kembali meminta konfirmasi jika ada perubahan. Tinggi/berat tidak menghitung BMI atau target kalori. Pencocokan alergen belum tersedia.
- Model `models/nutrition_profile.dart` serta notifier sesi pada router menghubungkan onboarding, profil, dan label fokus dashboard. State tidak disimpan ke disk atau server dan hilang setelah restart. Profil belum diterapkan ke engine.
- `features/history/history_screen.dart` menyediakan filter jenis/tanggal, reset, empty state, dan detail snapshot. Lihat contoh riwayat membuka preview berlabel ilustrasi yang terpisah dari catatan pengguna. Sumber/basis/porsi ditampilkan dan null tetap Belum tersedia. API serta penyimpanan hasil nyata belum tersedia; Mulai pindai menjelaskan kamera belum tersedia.
- Komponen bersama berada di `shared/widgets/personal_page.dart`, memakai token teal/mint dan font Inter aplikasi. Figcraft tidak dimodifikasi. TTS dan penyimpanan permanen belum tersedia. Rincian perubahan, bukti pengujian, serta batasnya ada di [audit Profil/Riwayat](../docs/PROFILE_HISTORY_AUDIT.md).

Ekspor enam preview PNG dari widget Flutter (hasil lokal di `build/ui-audit/after/`, tidak dilacak Git):

```bash
flutter test --no-pub test/profile_history_preview_test.dart --dart-define=EXPORT_UI_PREVIEWS=true
```

## Font global Inter

Seluruh halaman memakai Inter melalui `fontFamily` pada `AppTheme.light` dan penerapan font ke `TextTheme`. Nama family disimpan di `AppTypography.fontFamily`; tidak perlu menambahkan `fontFamily` pada setiap `Text` atau layout. `TextStyle` lokal tetap dapat mengatur ukuran/bobot/warna dan mewarisi family tema.

File lokal berada di `assets/fonts/`: Inter-Regular (400), Inter-Medium (500), Inter-SemiBold (600), dan Inter-Bold (700), dengan mapping bobot pada `flutter.fonts` di `pubspec.yaml`. Font dibundel agar tersedia offline, tanpa package tambahan atau request font saat aplikasi dibuka. Sumber unduhan: [Google Fonts Inter](https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700); lisensi SIL Open Font License disertakan pada `assets/fonts/OFL.txt` dari [repository Google Fonts](https://github.com/google/fonts/blob/main/ofl/inter/OFL.txt).

Setelah menambahkan font, hentikan aplikasi, jalankan `flutter pub get` dari `app/`, lalu `flutter run` agar bundle font ikut dibangun. Hot reload saja belum tentu memuat font baru.

## Struktur kode

- `assets/images/` menyimpan foto, ilustrasi, dan logo; `assets/icons/` menyimpan ikon kustom. Keduanya terdaftar di `pubspec.yaml`. `assets/images/login_reference.png` adalah ekspor desain pengguna (`Group-11.png`); layar login hanya merender area ilustrasi makanannya. Gambar ini merupakan ilustrasi, bukan hasil scan/model atau referensi nutrisi. Simpan aset statis di luar `lib/`; panduan penamaan, subfolder, dan lisensi ada di [WORKSPACE.md](../docs/WORKSPACE.md#aset-statis-flutter).
- `lib/app.dart` mengatur `MaterialApp.router` dan tema aplikasi.
- `lib/core/theme/` berisi token warna teal/cyan, tipografi, dan `ThemeData` sesuai [DESIGN.md](../docs/DESIGN.md): judul 24 px bold, teks dasar 14 px, kartu putih radius 24 px, dan latar mint pucat.
- `lib/core/router/` berisi konfigurasi serta path/nama route.
- `lib/core/network/` menjadi batas komunikasi ke backend API terpisah. `ApiClient` menerima base URI saat dibuat; URL environment belum ditetapkan. Endpoint yang tercantum mengikuti usulan kontrak di AGENTS.md dan belum menyatakan endpoint backend sudah tersedia.
- `lib/core/utils/` menyimpan utilitas umum dan `ApiException`.
- `lib/models/`, `lib/services/`, `lib/repositories/`, dan `lib/providers/` adalah layer global lintas fitur.
- `lib/features/` hanya memuat UI per domain. File halaman berada langsung di folder feature; widget khusus halaman berada di `widgets/`. Jangan membuat folder `pages/` atau mengulang model/provider/repository/service dalam feature.
- Contoh alur pencarian: `features/food_search/food_search_page.dart` menggunakan `providers/food_provider.dart`, yang memanggil `repositories/food_repository.dart`, lalu `services/food_service.dart` untuk request via `core/network/api_client.dart`. File tersebut merupakan contoh penempatan, belum semuanya dibuat.
- Integrasi Supabase tidak termasuk struktur saat ini.

Navigasi menggunakan `context.go(path)` untuk berpindah ke tujuan dan `context.pop()` untuk kembali. Tambahkan layar produk saat mengerjakan flow terkait dan ganti builder route tersebut tanpa mengubah path publik secara diam-diam.

## Verifikasi

```bash
flutter analyze
flutter test
```

Dokumentasi Flutter tersedia di [docs.flutter.dev](https://docs.flutter.dev/). Kontrak produk dan batas nutrisi tetap mengikuti dokumen proyek; route yang tersedia tidak berarti fitur kamera, akun, model, database, atau analisis nutrisi sudah diterapkan.
