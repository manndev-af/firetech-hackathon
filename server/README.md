# NutriSee — Backend API

Backend Node.js/TypeScript dengan Express, Prisma/MySQL, retrieval SQL dan integrasi DeepSeek. Panduan ini menjelaskan konfigurasi development MVP; lihat [README utama](../README.md) untuk ringkasan produk.

## Panduan API

- [Scanner, profil, dan jurnal](SCANNER_API.md).
- [Perbandingan dua makanan](COMPARE_API.md).
- [Asisten nutrisi](ASSISTANT_API.md).

Perintah dijalankan dari folder `server/`. Gunakan `pnpm dev` untuk development, `pnpm build` untuk kompilasi, dan `pnpm start` untuk menjalankan hasil build.

Pembaruan 8 November 2026: `SCANNER_USE_RAW_OCR=false` menjadi default sementara. Mode label menerima gambar tanpa raw OCR; OCR yang disertakan tetap divalidasi batas input, disimpan dan masuk fingerprint deduplikasi, tetapi tidak digunakan untuk retrieval, payload provider atau pencocokan evidence. Prompt v4 meminta evidence `origin=image`. Set `SCANNER_USE_RAW_OCR=true` di `server/.env` lalu restart backend untuk mengaktifkan gambar + OCR kembali; OCR label kembali wajib. Deskripsi tambahan, provenance, validasi angka/satuan, satu dispatch dan kalkulasi porsi tetap berlaku. Ini menggantikan kewajiban OCR pada uraian sebelumnya untuk konfigurasi default. Data lama/replay tidak dianalisis ulang; gunakan operasi scan baru yang disengaja untuk membandingkan mode.

## Swagger / OpenAPI

Jalankan `pnpm dev` dari `server/`, lalu buka `http://localhost:3000/api/docs/`.
Dokumen JSON tersedia di `http://localhost:3000/api/openapi.json`.
Sesuaikan port dengan `PORT`; kedua URL mengikuti `API_PREFIX` (default `/api`).
Dokumentasi tersedia juga pada hasil build (`pnpm build`, `pnpm start`). Aset Swagger dilayani lokal; validator eksternal dinonaktifkan.

- `src/routes/health.openapi.ts`: `/health` dan route health di bawah API prefix.
- `src/routes/user.openapi.ts`: CRUD user contoh dalam memori, bukan autentikasi atau profil nutrisi. Perubahan hilang setelah proses restart.
- `src/config/openapi.ts`: metadata dan penggabungan dokumen untuk Swagger; kontrak route tetap di file masing-masing.

Setiap penambahan/perubahan/penghapusan route wajib memperbarui `<name>.openapi.ts` di samping `<name>.routes.ts` dalam pekerjaan yang sama. Daftarkan modul baru pada assembler, dokumentasikan semua method, parameter, body, validasi, status, schema respons, dan contoh relevan. Jangan satukan kontrak semua route dalam satu file. Schema validasi user dipakai ulang agar batas input tetap sinkron.

OpenAPI mencerminkan kontrak health/user contoh serta scanner, profil, jurnal, ringkasan nutrisi, compare, dan assistant (`success`, `message`, `data`, `timestamp` pada respons sukses). Kontrak domain berada di `profile.openapi.ts`, `scanner.openapi.ts`, `food-entry.openapi.ts`, `nutrition.openapi.ts`, `compare.openapi.ts`, dan `assistant.openapi.ts`. Rate limiter global API dinonaktifkan; konfigurasi RATE_LIMIT_* tidak diterapkan pada request. Header keamanan tetap aktif; `upgrade-insecure-requests` dinonaktifkan khusus dokumentasi agar aset bekerja pada HTTP localhost.

Verifikasi: `pnpm test`, `pnpm build`, dan `pnpm lint`. Tes memakai Node.js test runner dan menguji JSON, aset UI, prefix khusus, serta respons route. Gunakan Node.js yang kompatibel dengan dependency Prisma 7 yang terpasang.

## Prisma + MySQL

Backend memakai Prisma ORM 7 dengan adapter MariaDB resmi yang kompatibel dengan MySQL. Prisma schema ada di `prisma/schema.prisma`; client TypeScript digenerate ke `src/generated/prisma/` dan tidak disimpan di Git.

1. Salin `.env.example` menjadi `.env`, lalu isi `DATABASE_URL` dengan kredensial dan nama database MySQL lokal. Encode karakter khusus pada username/password sesuai URL.
2. Jalankan `pnpm install` untuk memasang dependency dari `pnpm-lock.yaml`.
3. Jalankan `pnpm db:generate` setelah instalasi awal dan setelah mengubah schema.
4. Terapkan migration yang tersedia dengan `pnpm db:deploy`. Untuk perubahan schema berikutnya, buat migration lokal dengan `pnpm db:migrate`; jangan reset database berisi data pengguna.

Client singleton tersedia dari `src/config/prisma.ts` lewat `getPrismaClient()`. Database tidak dikontak saat server mulai; client menginisialisasi saat fitur pertama kali memintanya. Model domain: `User`, `NutritionProfile`, `FoodEntry`, `KnowledgeChunk`, `ScanRequest`. Migration awal tersedia di `prisma/migrations/202611070001_scanner_consumption/`.

### Instalasi pnpm di Windows

Gunakan pnpm 12 dan lockfile yang tersedia; jangan mencampur `npm install` dengan instalasi pnpm. `pnpm-workspace.yaml` mengizinkan build script `@prisma/engines` dan `prisma`, serta menolak script `@scarf/scarf`. Kebijakan ini mengatasi `ERR_PNPM_IGNORED_BUILDS` tanpa mengizinkan semua script dependency. Notifikasi agent skills `dotenv` tidak menghalangi instalasi dan tidak diperlukan untuk menjalankan backend.

Jika PowerShell memblokir `pnpm.ps1`, gunakan `pnpm.cmd` untuk perintah yang sama. Jika muncul Windows error 32 saat membuat symlink, pastikan instalasi lain pada folder yang sama sudah selesai, lalu ulangi `pnpm install --frozen-lockfile`.

## Struktur service

Logika bisnis dan orkestrasi data berada di `src/services/`: profile, scan, retrieval, deepseek, journal, compare, dan assistant. Controller di `src/controllers/` menangani HTTP dan mendelegasikan pekerjaan ke service.

## Scanner konsumsi development

Gunakan Node.js 22.12+ atau versi lebih baru yang didukung Prisma 7, serta pnpm. Konfigurasi domain MVP hanya mengizinkan development/test dengan user dummy; belum tersedia autentikasi produksi.

1. Isi `.env` lokal: `NODE_ENV=development`, `DATABASE_URL`, `SEED_USER_EMAIL`, dan `SEED_USER_PASSWORD` (5–128 karakter untuk dummy development). Jangan membagikan password/key di chat atau Git.
2. Jalankan `pnpm install`, `pnpm db:generate`, `pnpm db:deploy`, lalu `pnpm db:seed` dari `server/`.
3. Set `ENABLE_DEMO_USER=true`, `DEMO_USER_EMAIL` sama dengan seed, `DEEPSEEK_API_KEY`, `DEEPSEEK_BASE_URL=https://api.deepseek.com`, serta `DEEPSEEK_MODEL` yang mendukung image input. Base URL wajib berupa HTTP(S) tanpa kredensial/query/fragment; backend menambahkan `/chat/completions` dan mendukung base path seperti `/v1`. Untuk 9Router lokal, gunakan base URL `http://localhost:20128/v1` dan ID model dari `/v1/models`. Default model `deepseek-flash`; hasil smoke test konfigurasi 9Router ada di bawah.
4. Jalankan `pnpm dev`; kontrak tersedia di `/api/docs/`. Route domain memakai `${API_PREFIX}/v1`; jangan menambahkan `/v1` pada prefix kecuali memang menginginkan versi ganda.

Seed memakai salted scrypt, membuat profil dummy lengkap tanpa field null dan 14 referensi knowledge (tiga FDA dan sebelas Kemenkes yang diaktifkan atas konfirmasi pengguna). Profil contoh: Pengguna Demo, usia 25, tinggi 165 cm, berat 60 kg, masakan rumahan, prioritas Gula/Protein, pola Fleksibel, preferensi halal aktif, alergi Susu/Wijen, audio aktif, timezone Asia/Jakarta. Seluruh nilai profil ini fiktif untuk demo, bukan data pengguna atau rekomendasi kesehatan. Seed ulang mempertahankan profil yang sudah ada, audio, password hash, dan jurnal; fixture lengkap diterapkan saat profil baru dibuat. Seed ditolak di production atau tanpa kredensial valid. Email/password dummy **bukan login**; tidak ada autentikasi. Semua request domain memakai satu owner yang dipilih server, override ditolak. Domain nonaktif ketika flag mati atau `NODE_ENV` bukan development/test. Ini backend lokal MVP, bukan layanan publik multi-user.

Scan sukses langsung mencatat konsumsi. Alur: validasi gambar/metadata, claim idempotency, retrieval profil/riwayat/referensi, satu dispatch DeepSeek, validasi output, transaksi simpan jurnal. Tidak ada retry otomatis, tool loop, atau panggilan repair JSON. Provider gagal berarti konsumsi tidak dicatat. Jurnal dan koreksi quantity tetap tersedia tanpa API key.

Upload satu JPEG/PNG maksimal 5 MiB/20 megapixel, total multipart maksimal 6 MiB. Metadata: `mode`, `description` maksimal 1.000 karakter, `rawOcrText` maksimal 20.000 (wajib label), `consumedAt` ISO8601 opsional, `quantity` positif maksimal 10.000/enam desimal (default 1). Field berulang/tak dikenal, URL input, MIME palsu, dan gambar rusak ditolak. Decoder merotasi, membatasi sisi 1600 px dan menghapus metadata. Gambar tidak disimpan permanen; hanya dikirim ke provider. Dua operasi scan bersamaan per proses; request berikutnya mendapat 429. Rate limiter starter dinonaktifkan; batas dua operasi scan bersamaan tetap berlaku.

`Idempotency-Key` UUID wajib. Key dan input identik memberi hasil tersimpan (200); input berbeda 409; processing/dispatch tidak pasti 409; replay sesudah delete 410. Crash setelah dispatch tidak boleh mengirim ulang. Key baru merupakan operasi baru yang dapat memakai biaya baru; jangan membuat key baru otomatis saat timeout.

Nutrisi foto berlabel `model_estimate`; label `label_extracted_unverified`, bukan database terverifikasi. Angka label harus punya evidence angka/unit; konflik OCR atau kolom ambigu menjadi null. Ekstraksi ini konservatif, bukan pembuktian kebenaran gambar. Porsi/basis ambigu meminta scan ulang. Nutrisi tidak tersedia tetap null. Formula quantity `baseValue * quantity / baseQuantity` memakai Decimal; unit tetap. Respons detail menyimpan analisis dan snapshot konteks saat scan; edit/hapus tidak memperbarui insight lama milik entri lain.

RAG memakai query SQL/tag/text berparameter, bukan vector search. Kandidat maksimal 100 entri tujuh hari sebelum konsumsi; ranking kecocokan kata, waktu, ID menghasilkan maksimal lima entri. Referensi reviewed maksimal tiga dari corpus FDA dan Kemenkes, dengan sumber/versi/izin tercatat di `prisma/knowledge.ts`. Konteks maksimal sekitar 8.000 karakter. Cold start eksplisit tanpa riwayat/referensi. Profil terkirim hanya priorities, preference, eatingPattern, prefersHalal, allergyStatus, allergies, otherAllergies; nama/usia/tinggi/berat/audio/email/password tidak dikirim. Gambar, deskripsi, OCR dan konteks tersebut diperlukan untuk analisis eksternal; jangan masukkan informasi pribadi di foto/deskripsi. Timezone menentukan periode; bukan target medis.

Profil mendukung PATCH tiga kelompok: identity (`name`, `age`, `heightCm`, `weightKg`), personalization (`preference`, `priorities`, `eatingPattern`, `prefersHalal`, `allergyStatus`, `allergies`, `otherAllergies`), settings (`audioAnalysisEnabled`, `timezone`). Semua field/opsi/batas tercantum pada OpenAPI. Kirim hanya field yang diedit. Identity/settings boleh sebelum memilih prioritas; personalization memerlukan minimal satu. Field tidak dikirim tetap utuh; null membersihkan scalar opsional, string kosong membersihkan nama/alergi lain. Status unknown/noneKnown membersihkan bahan lama; listed wajib bahan. Payload kontradiktif ditolak. Nama maksimal 60; usia integer 1–120; tinggi (0,300]; berat (0,700]; alergi lain 120 karakter; timezone IANA valid.

Panduan request/response dan integrasi TTS: [SCANNER_API.md](SCANNER_API.md). Tim frontend harus memperbarui copy privasi yang masih menyatakan session-only sebelum menghubungkan profil persisten/LLM. `audioAnalysisEnabled` menyimpan preferensi, bukan menghasilkan audio. Bacakan `ttsSummary`, bukan seluruh daftar insight; tersedia juga ketika audio off dan setelah quantity berubah.

### Verifikasi

`pnpm test`, `pnpm build`, `pnpm lint`. Tes integrasi dilewati bila `TEST_DATABASE_URL` tidak diisi. Untuk menjalankannya, sediakan database terisolasi dengan nama berakhiran `_test`, jalankan `pnpm db:deploy` menggunakan URL itu, lalu set `TEST_DATABASE_URL` dan jalankan `pnpm test`. Jangan arahkan tes ke database aplikasi. Fixture synthetic dan transport mock memastikan tidak ada dispatch provider sungguhan.

Verifikasi lokal 7 November 2026 setelah revisi seed: 18 tes lolos tanpa skip dengan provider mock; build dan OpenSpec strict lolos. Prisma validate/generate/deploy telah lolos pada verifikasi awal. Lint exit 0 dengan 12 warning (console/any starter dan non-null assertion journal). Integrasi memakai provider MySQL Prisma pada MariaDB 10.4.32 terisolasi, bukan Oracle MySQL 8. Atas permintaan pengguna, migration dan seed juga diterapkan pada database lokal terkonfigurasi; profil fixture memiliki 13 field terisi tanpa null dan seed ulang tidak menggandakan data. `.env` pengguna tidak diubah. Live smoke test DeepSeek belum dijalankan; akses vision dan kualitas analisis nyata belum tervalidasi.

### Live smoke test 9Router — 7 November 2026

Pembaruan pro/cons: respons entry kini menyediakan `pros`/`cons` di root `data`, alias analisis tersimpan. Prompt v2 meminta insight yang terkait profil/retrieval dan `ttsSummary` yang merangkumnya. Tes unit mencakup mapping respons, fallback berbasis insight, dan summary tetap setelah quantity berubah. Uji service live v2 food/label juga HTTP 200 (7.811/3.038 ms), satu dispatch masing-masing, pro/cons terisi dan kedua summary bersumber model. Fixture tidak disimpan ke jurnal. Detail handoff ada di SCANNER_API.md.

Uji yang diizinkan pengguna memakai `http://localhost:20128/v1/chat/completions`, model konfigurasi `ds/deepseek-v4-flash-vision-exp`; `/v1/models` merespons 200 dan mengiklankan vision=true. Kedua respons generation melaporkan model `deepseek-flash`, finish_reason=stop. Satu dispatch dari backend per mode, tanpa retry; jumlah panggilan upstream internal 9Router tidak diaudit.

| Mode | Fixture | Status provider | Latensi service | Validasi | TTS |
|---|---|---|---|---|---|
| food | Crop foto mangkuk nasi/ayam dari aset repo, tanpa identitas pribadi | 200 | 7.066 ms | Lolos schema/basis/provenance | Template lokal |
| label | Gambar label sintetis dan raw OCR yang sama, bukan produk nyata | 200 | 3.330 ms | Delapan angka hasil ekstraksi cocok dengan fixture | Model |

Uji memanggil service analisis aktual dengan retrieval database sebelum request; profil allowlist dan tiga referensi ikut, riwayat tersedia nol. Tidak membuat FoodEntry/ScanRequest atau mengubah konsumsi pengguna. Ini menguji koneksi, input gambar/OCR, output JSON dan validasi service, bukan alur HTTP multipart/persistensi live atau akurasi nutrisi foto. Angka food tetap estimasi; keberhasilan label sintetis tidak mengukur OCR gambar nyata. HTTP/persistensi sudah diuji terpisah memakai provider mock. Fallback TTS food tersedia tanpa panggilan model tambahan. Tidak ada key/credential dalam catatan ini.

## Log debugging request dan response

Pada `NODE_ENV=development`, Morgan menulis satu baris JSON per respons selesai ke `server/src/logs/requests-YYYY-MM-DD.log` (tanggal UTC), termasuk method, path/query, status, durasi, header/body request, body respons JSON, serta MIME/ukuran upload. Logger dipasang sebelum parser agar error validasi/parser juga tercatat. Log konsol tetap tersedia. Folder dibuat otomatis, termasuk ketika menjalankan build dari `dist`; log diabaikan Git.

Tujuan log: debugging integrasi request/response Flutter dengan API. Nilai key terstruktur untuk otorisasi/cookie/password/token/API key, identitas pribadi, OCR/deskripsi pengguna, gambar/base64, stack, profil dan snapshot context disamarkan. Upload gambar hanya dicatat sebagai MIME/ukuran. Teks di field lain seperti judul makanan, pro/cons dan TTS masih dapat berisi informasi konsumsi; jangan membagikan log mentah. Tiap string dibatasi 4.000 karakter, body/header/query dibatasi sekitar 32.000 karakter, kedalaman dan array juga dibatasi. Respons non-JSON/stream tidak direkam isinya. Log debug file tidak aktif pada production/test.

File dipisah per hari tanpa pembersihan otomatis; hapus log lama setelah debugging. Pantau langsung dari PowerShell:

```powershell
Get-Content .\src\logs\requests-YYYY-MM-DD.log -Wait
```


### Koreksi label - 8 November 2026

Untuk scan label baru dengan basis `per_serving`, keluaran model `20 g` atau `200 ml` dinormalisasi ke `baseQuantity: 1`, `unitCode: porsi`, dengan massa/volume asli pada `referenceWeightG`/`referenceVolumeMl`. Jadi `quantity: 1` berarti satu sajian, bukan satu gram/ml. Basis `per_100g`/`per_100ml` tetap memakai satuan sumber. Entri lama tidak ditulis ulang; scan ulang bila basis entri lama salah.

Evidence per nutrisi harus berisi satu baris nama, angka dan satuan. Energi dari lemak dan acuan AKG bukan energi total. Variasi spasi OCR diterima; konflik angka sebenarnya tetap menghasilkan `null`. Bila angka ditolak, insight dan TTS diganti penjelasan keterbatasan agar tidak mempertahankan klaim dari angka tersebut. `extractLabel()` Flutter tetap parser saran lokal, bukan sumber angka request atau hasil API. Batas teks Flutter/backend sama: 20.000 karakter.

## Compare dua makanan

POST `{API_PREFIX}/v1/comparisons` menerima dua gambar dalam satu request multipart, memakai dummy owner yang sama dengan scanner. Hasil hanya untuk sesi, tidak mencatat konsumsi atau menyimpan perbandingan. Route berbagi kapasitas dua operasi dengan scanner dan satu dispatch vision untuk pasangan A/B. Tidak memerlukan env/dependency atau migration baru.

Lihat [COMPARE_API.md](COMPARE_API.md) untuk request, contoh respons/error, basis, null dan handoff CompareScreen. OpenAPI tersedia di `{API_PREFIX}/openapi.json` dan Swagger di `{API_PREFIX}/docs/`. Payload request/response compare selalu dihilangkan dari log debugging, termasuk saat gagal parsing; route lain mempertahankan redaksi log yang ada. Integrasi Flutter dijelaskan terpisah di [README aplikasi](../app/README.md); API assistant memiliki kontrak sendiri.

## Assistant nutrisi

Kontrak dan handoff tim Flutter ada di [ASSISTANT_API.md](ASSISTANT_API.md). Assistant memakai dummy owner dan provider yang sama; mode general/pattern tanpa compare atau histori chat persisten. JSON dibatasi 64 KiB, isi request/response/query dihilangkan dari log termasuk error parsing. Teks pertanyaan/history serta preferensi dan catatan yang relevan diproses provider eksternal; retensi provider terpisah dari aplikasi yang tidak menyimpan chat. Tidak menambahkan identitas pribadi ke payload model. POST `{API_PREFIX}/v1/assistant/messages` aktif dengan prompt assistant terpisah dan satu dispatch teks per request. Pattern memakai tujuh tanggal lokal, agregasi Decimal dan batas 1000 catatan; general tidak mengirim jurnal ke model.


### Knowledge Kemenkes — 8 November 2026

`prisma/knowledge.ts` menggabungkan tiga referensi FDA dan sebelas parafrasa Permenkes No. 41 Tahun 2014 dari data pengguna. Pengguna mengonfirmasi sumber PDF dan menyetujui aktivasi retrieval; `reviewedAt` mencatat tanggal konfirmasi tersebut, bukan klaim pemeriksaan PDF independen. URL sumber: https://peraturan.bpk.go.id/Download/109856/Permenkes%20Nomor%2041%20Tahun%202014.pdf. Ketentuan penggunaan belum diverifikasi dan tetap dicatat demikian pada metadata.

Jalankan `pnpm db:seed` dari `server/` pada environment development/test untuk memasukkan data. Seed meng-upsert knowledge berdasarkan ID dan memperbarui konten serta metadata referensi yang sudah ada tanpa menggandakan data. Edit knowledge melalui file seed; perubahan manual database pada ID yang sama akan ditimpa saat seed diulang. User/password dan profil yang sudah ada tetap dipertahankan. Seed tidak menghapus referensi lain.
