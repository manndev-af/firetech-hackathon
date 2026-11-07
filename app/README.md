# NutriLens AI — Flutter App

Aplikasi mobile NutriLens AI berada di folder ini. Baca [panduan root](../AGENTS.md), [ringkasan produk](../docs/SUMMARY.md), [PRD](../docs/PRD.md), [FRD](../docs/FRD.md), dan [panduan UI](../docs/DESIGN.md) sebelum mengembangkan fitur.

## Menjalankan aplikasi

Pastikan Flutter SDK sesuai batas versi di `pubspec.yaml`, lalu dari folder `app/` jalankan:

```bash
flutter pub get
flutter run
```

## Routing

Navigasi menggunakan `go_router`. Konfigurasi utama ada di `lib/core/router/app_router.dart`, sedangkan nama dan path route ada di `lib/core/router/route_paths.dart`. Aplikasi saat ini dimulai dari `/login`. Route `/login` merender `LoginScreen` di luar shell navigasi bawah. Halaman, route, dan akses pendaftaran telah dihapus. Dashboard contoh `/home` tetap berada dalam shell. Route produk lain masih dinonaktifkan dalam konfigurasi; konstanta path bukan bukti fitur sudah tersedia.

Halaman login berada di `lib/features/auth/login_screen.dart` dan dapat dibuka menggunakan `context.go(AppRoutes.login)`. UI mengikuti referensi terbaru: latar putih, wordmark nutrilens, ilustrasi makanan, judul “Kenali isi piringmu.”, dan satu tombol “Lanjutkan dengan Google”. Form email/kata sandi telah dihapus. Tombol Google hanya menampilkan pemberitahuan bahwa integrasi belum terhubung; tidak ada proses OAuth, pengiriman kredensial, atau sesi akun. Layout dapat digulir pada layar kecil dan saat teks diperbesar.

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
