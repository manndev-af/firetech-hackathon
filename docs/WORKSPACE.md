# Workspace NutriLens AI

Panduan ini menjelaskan tata letak repository dan cara berpindah antar area kerja. Tujuannya menjaga mobile app, backend, dan dokumen produk pada satu repository tanpa membuat struktur yang belum diperlukan.

## Backend scanner — 7 November 2026

Implementasi development tersedia tanpa perubahan Flutter. `server/prisma/schema.prisma` berisi User, NutritionProfile, FoodEntry, KnowledgeChunk, ScanRequest; migration awal berada di `server/prisma/migrations/202611070001_scanner_consumption/`. `seed.ts` membuat user dummy dengan salted password hash dan profil contoh lengkap tanpa null; nilai profil fiktif dijelaskan di README backend. `knowledge.ts` menyimpan referensi reviewed beserta sumber/izin. Client generated tetap diabaikan Git.

`server/src/services/` kini berisi `profile.service.ts`, `scan.service.ts`, `retrieval.service.ts`, `deepseek.service.ts`, `journal.service.ts`. Controller domain `nutrition.controller.ts`; middleware `demoOwner.ts` dan `scanUpload.ts`; validasi `nutrition.ts`. Router profile/scanner/food-entry/nutrition memiliki kontrak `.openapi.ts` masing-masing. Tidak ada login, vector DB, server TTS, atau penyimpanan foto permanen.

Setup: dari `server/`, jalankan `pnpm install`, `pnpm db:generate`, `pnpm db:deploy`, lalu `pnpm db:seed` setelah mengisi environment lokal. Domain memerlukan `NODE_ENV=development`, `ENABLE_DEMO_USER=true`, dan email owner sesuai seed. Detail environment/batas keamanan ada di [README backend](../server/README.md#scanner-konsumsi-development); contoh integrasi tersedia di [SCANNER_API.md](../server/SCANNER_API.md). Jangan memakai kredensial seed sebagai login frontend.

Tes berada di `server/test/`; `pnpm test` menjalankan unit/HTTP/OpenAPI. Isi `TEST_DATABASE_URL` ke database terisolasi berakhiran `_test` yang sudah dimigrasi untuk integrasi Prisma dengan provider mock. `pnpm build` dan `pnpm lint` memeriksa backend. Verifikasi lokal menggunakan MariaDB 10.4.32 melalui provider MySQL Prisma; Oracle MySQL 8 dan live DeepSeek belum diuji. Panduan struktur lama di bawah dipertahankan sebagai konteks; bagian ini memperbarui status domain scanner.

## Sumber konteks

Baca [AGENTS.md](../AGENTS.md) sebelum mengubah proyek. Dokumen berikut menjadi rujukan sesuai jenis pekerjaan:

| Dokumen | Kegunaan |
|---|---|
| [SUMMARY.md](SUMMARY.md) | Konteks brainstorming, user flow, Nutrition Profile, ML, sumber nutrisi, prioritas MVP, serta keputusan terbuka. |
| [PRD.md](PRD.md) | Sasaran, pengguna, masalah, ruang lingkup, dan definisi keberhasilan produk. |
| [FRD.md](FRD.md) | Kebutuhan fungsional dan kriteria penerimaan. |
| [DESIGN.md](DESIGN.md) | Arahan UI/UX, komponen, konten, state, aksesibilitas, dan pertanyaan desain terbuka. |
| [DECISIONS.md](DECISIONS.md) | Register keputusan, rekomendasi, konflik, serta hal yang belum final. |
| [architecture.md](architecture.md) | Batas komponen, aliran data, tanggung jawab, dan rancangan integrasi. |
| [rules/ui.md](../rules/ui.md) | Aturan implementasi dan review mutu UI Flutter. |
| [CHANGELOG.md](../CHANGELOG.md) | Catatan perubahan penting yang telah dibuat atau disiapkan. |
| [app/README.md](../app/README.md) | Panduan lokal Flutter. |
| [server/README.md](../server/README.md) | Panduan lokal backend Node.js. |

Jika dokumen berisi rekomendasi yang belum disepakati, jangan memperlakukannya sebagai requirement final. Catat konflik dan minta keputusan tim bila memengaruhi implementasi.

## Struktur repository

Berikut struktur yang ada saat panduan ini diperbarui. Folder build/cache dan dependency lokal yang diabaikan Git tidak ditampilkan.

```text
D:\firetech-hackathon\
├── .github/
├── AGENTS.md
├── CHANGELOG.md
├── README.md
├── app/                         # Flutter application
│   ├── README.md
│   ├── android/                 # Platform scaffold yang tersedia saat ini
│   ├── assets/                  # Aset statis aplikasi, di luar lib/
│   │   ├── fonts/               # Inter lokal, terdaftar pada flutter.fonts
│   │   │   ├── Inter-Regular.ttf
│   │   │   ├── Inter-Medium.ttf
│   │   │   ├── Inter-SemiBold.ttf
│   │   │   ├── Inter-Bold.ttf
│   │   │   └── OFL.txt
│   │   ├── images/              # Foto, ilustrasi, dan logo hasil ekspor desain
│   │   │   ├── .gitkeep
│   │   │   ├── login_reference.png # Ekspor desain pengguna; sumber ilustrasi login
│   │   │   ├── onboarding_finish_reference.png # Ilustrasi selesai onboarding
│   │   │   └── dashboard_reference.png # Ekspor pengguna untuk ilustrasi kartu scan
│   │   └── icons/               # Ikon kustom hasil ekspor desain
│   │       └── .gitkeep
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── core/
│   │   │   ├── router/
│   │   │   │   ├── app_router.dart
│   │   │   │   └── route_paths.dart
│   │   │   ├── theme/
│   │   │   │   ├── app_colors.dart
│   │   │   │   ├── app_theme.dart
│   │   │   │   └── app_typography.dart
│   │   │   ├── network/
│   │   │   │   ├── api_client.dart
│   │   │   │   ├── api_endpoints.dart
│   │   │   │   └── api_interceptor.dart
│   │   │   └── utils/
│   │   │       └── api_exception.dart
│   │   ├── models/                # Model global lintas feature
│   │   │   └── daily_nutrition_summary.dart
│   │   ├── services/              # Akses API/backend global
│   │   ├── repositories/          # Abstraksi data global
│   │   ├── providers/             # State global
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   └── login_screen.dart
│   │   │   ├── onboarding/
│   │   │   │   ├── onboarding_screen.dart
│   │   │   │   ├── onboarding_focus_screen.dart
│   │   │   │   ├── onboarding_preference_screen.dart
│   │   │   │   ├── onboarding_finish_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── onboarding_widgets.dart
│   │   │   ├── dashboard/
│   │   │   │   ├── dashboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── dashboard_history.dart
│   │   │   │       └── dashboard_scan_card.dart
│   │   │   ├── food_search/
│   │   │   │   └── widgets/
│   │   │   ├── food_journal/
│   │   │   │   └── widgets/
│   │   │   ├── recipes/
│   │   │   │   └── widgets/
│   │   │   └── profile/
│   │   └── shared/
│   │       └── widgets/
│   │           └── route_placeholder_screen.dart
│   ├── test/
│   │   ├── widget_test.dart
│   │   └── dashboard_test.dart
│   ├── analysis_options.yaml
│   ├── pubspec.yaml
│   └── pubspec.lock
├── docs/
│   ├── FRD.md
│   ├── DESIGN.md
│   ├── DECISIONS.md
│   ├── PRD.md
│   ├── SUMMARY.md
│   ├── WORKSPACE.md
│   └── architecture.md
├── rules/
├── server/                      # Node.js + TypeScript backend
│   ├── README.md
│   ├── README.Docker.md
│   ├── src/
│   │   ├── app.ts
│   │   ├── server.ts
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── types/
│   │   ├── utils/
│   │   └── validation/
│   ├── package.json
│   ├── pnpm-lock.yaml
│   └── tsconfig.json
└── .gitignore
```

### `app/` — Flutter

`app/` adalah proyek Flutter pada root subfoldernya dan memakai scaffold Flutter yang tersedia. Pertahankan struktur platform hasil generate; kode aplikasi ditempatkan di `lib/`, dan tes Flutter berada di `test/`. Routing `go_router` ada di `lib/core/router/`; tema global ada di `lib/core/theme/`; network client untuk backend terpisah ada di `lib/core/network/`; exception API ada di `lib/core/utils/`. Model, service, repository, dan provider berada di layer global. Folder feature hanya berisi UI dan widgets. Supabase tidak termasuk struktur saat ini. Saat ini scaffold platform Android tersedia. Jangan memindahkan app ke `app/mobile/` atau membuat folder platform lain tanpa kebutuhan yang jelas.

`app/` memakai pendekatan layer global: model, service, repository, dan provider berada masing-masing di `lib/models/`, `lib/services/`, `lib/repositories/`, dan `lib/providers/`. Folder `features/` hanya mengelompokkan UI berdasarkan domain. File halaman diletakkan langsung di folder feature, sedangkan komponen khusus halaman berada di subfolder `widgets/`. Jangan membuat subfolder `pages/` atau mengulang layer data di dalam feature. Folder yang masih kosong adalah kerangka, bukan fitur yang sudah diimplementasikan. Supabase tidak termasuk struktur saat ini.

#### Contoh alur tanggung jawab

Contoh ketika tim mengimplementasikan pencarian makanan:

1. `models/food_model.dart` mendefinisikan bentuk data makanan yang dipakai app.
2. `services/food_service.dart` memanggil endpoint melalui `core/network/api_client.dart`.
3. `repositories/food_repository.dart` mengubah respons service menjadi operasi data yang dipakai app.
4. `providers/food_provider.dart` mengelola state pencarian dan memanggil repository.
5. `features/food_search/food_search_page.dart` menampilkan UI dan menggunakan provider; widget khusus pencarian berada di `features/food_search/widgets/`.

Contoh ini menjelaskan penempatan tanggung jawab, bukan file/endpoint yang sudah tersedia. Jangan membuat model, endpoint, atau halaman sebelum kontraknya dibutuhkan dan disepakati.

Untuk dependency, perintah, dan cara menjalankan app, ikuti [app/README.md](../app/README.md) serta konfigurasi `pubspec.yaml` yang ada.

#### Aset statis Flutter

- [app/assets/images/](../app/assets/images/) menyimpan foto, ilustrasi, dan logo yang diekspor dari Figma atau sumber lain dengan izin penggunaan yang sesuai.
- [app/assets/icons/](../app/assets/icons/) menyimpan ikon kustom. Ikon Material bawaan tetap dapat digunakan tanpa berkas tambahan.
- Kedua folder sudah didaftarkan pada `flutter.assets` di [pubspec.yaml](../app/pubspec.yaml). Folder icons masih berisi `.gitkeep`; images juga memuat `login_reference.png` dari ekspor desain pengguna `Group-11.png`. Onboarding juga memakai `onboarding_finish_reference.png` dari ekspor pengguna `Group-16.png`, sedangkan dashboard memakai `dashboard_reference.png` dari `Group-18.png`. Login, onboarding, dan dashboard hanya merender area ilustrasi makanan dari ekspor tersebut, sementara teks dan tombol tetap widget Flutter. Aset merupakan ilustrasi, bukan bukti hasil identifikasi atau nilai nutrisi. Lisensi/sumber asli ilustrasi belum diverifikasi; pastikan izin sebelum redistribusi.
- Gunakan nama berkas `snake_case`, misalnya `nutrilens_logo.png`, dengan path dari root Flutter seperti `assets/images/nutrilens_logo.png`. Nama tersebut hanya contoh, bukan aset yang sudah tersedia.
- Jika menambahkan subfolder, daftarkan path-nya tersendiri di `pubspec.yaml`; deklarasi direktori tidak mencakup subfolder secara rekursif, kecuali varian resolusi gambar Flutter.
- Gunakan format gambar yang didukung Flutter untuk gambar/ikon lokal. SVG memerlukan dukungan tambahan; jangan menambah dependency sebelum diperlukan. Inter kini dibundel di `app/assets/fonts/` dan didaftarkan pada `flutter.fonts` untuk bobot 400/500/600/700. Tema global menerapkannya ke seluruh halaman. Berkas `OFL.txt` menyertakan lisensi SIL Open Font License; sumber Google Fonts dan petunjuk rebuild ada di README app.
- Folder ini hanya untuk aset aplikasi. Foto pengguna, hasil scan, dataset, dan model besar tidak ditempatkan atau dikomit di sini. Catat sumber/lisensi aset saat menambahkan berkas sebenarnya.

### `server/` — backend

`server/` adalah proyek Node.js + TypeScript tersendiri dengan Express, pnpm, dan Prisma ORM 7 untuk MySQL. Entry point ada di `src/server.ts`; Prisma schema dan CLI config berada di `prisma/schema.prisma` serta `prisma.config.ts`. Prisma Client digenerate ke `src/generated/prisma/` (di-ignore Git) dan diakses melalui `src/config/prisma.ts`. `src/services/` menampung logika bisnis dan orkestrasi data; controller hanya menangani HTTP. Model, migration, seed, serta service domain scanner kini memakai database; lihat addendum backend scanner di atas.

Gunakan [server/README.md](../server/README.md), `package.json`, dan lockfile untuk setup serta perintah backend. Sebagian isi README berasal dari starter template. Batasan MVP dalam [AGENTS.md](../AGENTS.md) tetap berlaku; misalnya, jangan menambahkan atau menjalankan Docker hanya karena template menyediakan dukungan Docker.

Nutrition Engine, food classifier, dan integrasi nutrisi belum boleh diasumsikan sudah tersedia hanya karena tercantum dalam rancangan. Implementasikan modul tersebut saat ada task yang memintanya dan tambahkan struktur seperlunya.

Dokumentasi backend tersedia pada `<API_PREFIX>/docs/` dan `<API_PREFIX>/openapi.json`. Setiap modul route memiliki `src/routes/<name>.openapi.ts` tersendiri di samping router; `src/config/openapi.ts` hanya menggabungkan metadata dan dokumen. Saat ini tersedia modul health/user contoh serta profile/scanner/food-entry/nutrition development. Kontrak wajib diperbarui bersama perubahan route sesuai [AGENTS.md](../AGENTS.md#openapi-documentation-for-every-route); perintah verifikasi ada di [README server](../server/README.md#swagger--openapi).

### ML dan data nutrisi

Training model direncanakan menggunakan Python/PyTorch, MobileNetV3-Large, dan subset MM-Food-100K. Folder ML belum menjadi bagian struktur aktif repository. Buat pipeline training, manifests, atau artefak hanya ketika tahap tersebut dikerjakan. Jangan commit dataset unduhan, cache gambar, checkpoint, atau bobot model besar; aturan ignore ada di [.gitignore](../.gitignore).

## Branch dan alur kolaborasi

Aturan aktif mengikuti permintaan pemilik repository: pekerjaan dan commit dilakukan langsung di `main`. Instruksi ini merupakan izin tetap untuk commit ke `main` ketika pengguna meminta commit. Jangan membuat branch fitur atau berpindah branch secara otomatis. Buat/pindah branch hanya atas permintaan eksplisit pengguna; bila branch aktif berbeda, pertahankan perubahan lokal dan laporkan situasinya sebelum berpindah.

Aturan proyek ini mengesampingkan saran generik skill yang mewajibkan branch fitur atau melarang commit ke `main`. Periksa status Git sebelum commit, sertakan hanya perubahan yang diminta, dan pertahankan pekerjaan lokal lain. Push tetap memerlukan permintaan pengguna.

Catatan historis: panduan sebelumnya menyarankan branch fitur dari `development`, lalu merge ke `development` dan `main`. Saran tersebut digantikan aturan kerja langsung di `main` di atas; keberadaan branch lama tidak mewajibkan penggunaannya. Pemeriksaan kode, pengujian yang relevan, serta pembaruan dokumentasi/changelog tetap berlaku.

## Alur kerja perubahan

1. Buka root repository, baca `AGENTS.md`, lalu baca dokumen dan README subproyek yang relevan.
2. Periksa struktur dan implementasi yang sudah ada sebelum mengedit atau menambah file.
3. Kerjakan satu irisan vertikal MVP pada satu waktu; jangan membuat seluruh struktur target di awal.
4. Jaga batas tanggung jawab: Flutter untuk UI dan interaksi pengguna; backend untuk API/orchestration; Nutrition Engine untuk kalkulasi deterministik; pipeline Python untuk training; LLM hanya untuk menjelaskan hasil terstruktur.
5. Pertahankan informasi yang dapat ditelusuri: sumber nutrisi, basis nilai, porsi, ketidakpastian model, serta data yang hilang.
6. Jalankan verifikasi yang relevan dengan perubahan. Jangan menyatakan test atau runtime berhasil bila belum dijalankan.
7. Perbarui dokumentasi yang terdampak dan catat perubahan penting di [CHANGELOG.md](../CHANGELOG.md) pada `Unreleased`.
8. Laporkan file yang berubah, hasil verifikasi, dan keterbatasan yang masih ada.

## Format, konfigurasi, dan data lokal

- `.gitignore` root dan aturan ignore subproyek mengecualikan secret, dependency lokal, hasil build, cache, dataset unduhan, serta bobot/checkpoint model.
- File `.env` lokal tidak boleh masuk Git. Gunakan `.env.example` untuk nama variabel contoh tanpa nilai rahasia.
- `.gitattributes` mengatur EOL teks dan menandai berkas biner yang umum. Ikuti format repository dan hindari perubahan format massal yang tidak diminta.
- Jangan mengubah konfigurasi Git global sebagai bagian setup workspace tanpa permintaan eksplisit.
- Jangan mengunggah informasi kesehatan, foto pengguna, atau secret ke layanan eksternal tanpa kebutuhan produk dan dokumentasi yang sesuai.

## Batas bukti saat ini

Panduan ini mendokumentasikan layout dan alur kerja repository. Ia tidak menyatakan bahwa alur produk, classifier, lookup nutrisi, model terlatih, API NutriLens, atau integrasi perangkat telah selesai atau diuji. Periksa kode dan hasil verifikasi terbaru sebelum membuat klaim implementasi.

### Log debugging backend

`server/src/middleware/requestLogger.ts` mencatat request/response development melalui Morgan ke `server/src/logs/requests-YYYY-MM-DD.log` (UTC). Folder dibuat saat server development berjalan dan diabaikan Git. Isi disamarkan serta dibatasi; tidak menyimpan gambar mentah. Lihat [panduan log backend](../server/README.md#log-debugging-request-dan-response) untuk batas data dan perintah pemantauan.


### Backend compare - 8 November 2026

Backend compare aktif melalui `server/src/routes/compare.routes.ts` dan `compare.openapi.ts`, `controllers/compare.controller.ts`, `middleware/compareUpload.ts`, serta `services/compare.service.ts`. Tes upload, provider mock, kalkulasi, read-only database dan concurrency ada di `server/test/compare.test.cjs`; OpenAPI/logging tercakup suite terkait. Handoff Flutter ada di [COMPARE_API.md](../server/COMPARE_API.md). Tidak menambah folder, schema Prisma, env atau dependency; frontend/asisten di luar change ini.

### Backend assistant - 8 November 2026

`server/src/validation/assistant.ts` berisi schema dan parser JSON 64 KiB sebelum parser global. `services/assistant.service.ts` menangani prompt/konteks/agregasi tujuh tanggal lokal; `controllers/assistant.controller.ts`, `routes/assistant.routes.ts` dan `assistant.openapi.ts` menyediakan POST messages serta kontraknya. Slot provider dibagi scanner/compare/assistant. Tes ada di `server/test/assistant.test.cjs`, dengan regresi OpenAPI/logger pada suite terkait. [ASSISTANT_API.md](../server/ASSISTANT_API.md) menjadi handoff Flutter; tidak ada perubahan app, Prisma, env atau dependency.
