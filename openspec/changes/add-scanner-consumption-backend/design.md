# Design

## Context

Lihat proposal.md untuk motivasi. Backend menggunakan Express 5, TypeScript CommonJS, AJV, Prisma 7 dengan adapter MariaDB/MySQL, dan Node test runner. Schema Prisma belum memiliki model. User starter masih array dalam memori, bukan akun domain. OpenAPI telah ditambahkan pada working tree dan setiap router harus memiliki dokumen kontrak terpisah. Perubahan lokal tersebut harus dipertahankan.

Scanner frontend sudah memiliki kamera, galeri, dan OCR lokal; hasilnya masih memuat preview. Tidak ada perubahan `app/` dalam change ini. Pengguna memilih user dummy development tanpa login, satu request DeepSeek per scan, serta penyimpanan konsumsi otomatis.

## Goals / Non-Goals

**Goals:** backend scanner yang dapat diuji melalui API, retrieval yang dapat ditelusuri, kepemilikan development yang eksplisit, porsi deterministik, dan kontrak handoff frontend.

**Non-Goals:** frontend/ML Kit, login/registrasi, deployment publik, vector database, embedding API, training ONNX, penyimpanan foto permanen, CRUD admin knowledge, dan multi-user production security. Tidak membuat abstraksi repository atau provider generik untuk satu implementasi.

## Decisions

### 1. Model domain dan seed

Model yang diusulkan di `server/prisma/schema.prisma`:

| Model | Isi dan batas |
|---|---|
| User | ID stabil, email unique yang dinormalisasi, passwordHash, timestamps. Nama panggilan hanya di NutritionProfile.name agar tidak ada dua sumber kebenaran. Tidak tersambung ke CRUD user starter. |
| NutritionProfile | userId primary key/FK one-to-one, seluruh field model profil Flutter, audioAnalysisEnabled, timezone IANA, timestamps. Mapping dan validasi pada bagian 1a. Gunakan JSON untuk daftar kecil yang divalidasi AJV. |
| FoodEntry | owner FK, consumedAt UTC, scanMode, title, description, original OCR jika diperlukan, basis analysis JSON berversi, quantity Decimal, nullable base nutrients Decimal, provenance, warnings, qualitative insight, snapshot konteks/citation dan model/prompt version. Index (userId, consumedAt, id). |
| KnowledgeChunk | ID/source key unique, topik/tag, teks pendek terkurasi, source URL/title/version, tanggal peninjauan, status reviewed. Bukan kumpulan respons LLM lama. |
| ScanRequest | owner FK, idempotency key, fingerprint, state, dispatchedAt, saved entry reference, terminal error/result metadata. Unique (userId, key). Metadata operasional, bukan konsumsi. |

FoodEntry menggabungkan analisis dan konsumsi; tidak ada tabel ScanAnalysis terpisah. ScanRequest diperlukan untuk deduplikasi sebelum panggilan eksternal, termasuk crash dan concurrency. Total nutrisi diturunkan dari basis + quantity; hindari menyimpan dua versi total yang dapat berbeda.

Seed berada di `server/prisma/seed.ts`, didaftarkan pada Prisma config dan script `db:seed`. Email dummy contoh `demo@nutrilens.test`; kredensial aktual dibaca dari `SEED_USER_EMAIL` dan `SEED_USER_PASSWORD` lokal. Hash salted menggunakan Node crypto.scrypt. Tidak menulis password ke log, source, atau response. Seed hanya development/test, transaksi, idempotent berdasarkan email, dan tidak mereset password/profil existing. Seed profil awal dan referensi yang telah diperiksa; jangan seed makanan fiktif ke jurnal pengguna. Fixture riwayat hanya untuk tes terisolasi.

Alternatif tabel user tanpa password ditolak karena pengguna meminta email/password. Login ditolak karena pengguna memilih seed saja. Password tersimpan sebagai hash tetapi tidak dipakai sebagai mekanisme akses pada MVP ini.

### 1a. Mapping lengkap screen profil ke schema dan API

Sumber yang dibaca penuh: `app/lib/features/profile/profile_screen.dart`, `nutrition_profile_screen.dart`, dan `widgets/profile_options.dart`; dilengkapi `app/lib/models/nutrition_profile.dart`, pilihan pada `onboarding_preference_screen.dart`, wiring state router, dan skenario `app/test/profile_history_test.dart`. Profil saat ini masih di memori. Switch audio memakai ValueNotifier terpisah; field backend baru tidak berarti model Dart sudah memiliki field itu.

| Field API/Prisma | Tipe Prisma yang diusulkan | Default / validasi setara UI |
|---|---|---|
| userId | String primary key + FK User | Ditentukan server; tidak writable pada PATCH |
| name | String @db.VarChar(60) | Empty string; trim, maksimal 60 karakter, boleh dikosongkan |
| age | Int? | null; integer 1..120 |
| heightCm | Float? @db.Double | null; finite, lebih dari 0 sampai 300 cm |
| weightKg | Float? @db.Double | null; finite, lebih dari 0 sampai 700 kg |
| preference | String? @db.VarChar(32) | null; satu pilihan keseharian yang tersedia |
| priorities | Json | []; array unik dari lima ID prioritas UI |
| eatingPattern | String? @db.VarChar(16) | null; satu pola makan yang tersedia |
| prefersHalal | Boolean | false; preferensi, bukan sertifikasi halal |
| allergyStatus | Enum AllergyStatus | unknown; nilai unknown, noneKnown, listed |
| allergies | Json | []; array unik dari delapan bahan UI |
| otherAllergies | String @db.VarChar(120) | Empty string; trim, maksimal 120 karakter |
| audioAnalysisEnabled | Boolean | false; pengaturan pemutaran, bukan input personalisasi nutrisi |
| timezone | String @db.VarChar(64) | Asia/Jakarta sebagai default development yang terdokumentasi; harus IANA valid |
| createdAt / updatedAt | DateTime | Metadata server, bukan input PATCH |

Float untuk ukuran tubuh mengikuti model Dart double tanpa memaksakan pembulatan desimal baru; nilai ini tidak dipakai untuk kalkulasi nutrisi. Nilai konsumsi tetap memakai Decimal. JSON array pada MySQL divalidasi lewat API dan seed; jangan mengandalkan tipe Json untuk menjamin item/keunikan.

Pertahankan key camelCase dan nilai string yang benar-benar dipakai frontend, bukan judul tampilan atau ID baru:
- priorities: `Gula`, `Natrium`, `Protein`, `Kalori`, `Keseimbangan`. Label seperti Perhatikan gula hanya presentation copy. Urutan response mengikuti daftar opsi UI; tidak ada duplikat.
- preference: `Masakan rumahan`, `Praktis dan cepat`, `Lebih banyak nabati` atau null. Ini pilihan tunggal dan berbeda dari eatingPattern.
- eatingPattern: `Fleksibel`, `Vegetarian`, `Vegan`, `Pescatarian` atau null.
- allergies: `Susu`, `Telur`, `Kacang tanah`, `Kacang pohon`, `Kedelai`, `Gandum`, `Ikan`, `Kerang / udang`.
- allergyStatus: `unknown` berarti belum diisi, `noneKnown` berarti tidak ada yang diketahui, `listed` berarti ada bahan tercatat. Jangan menyatukannya menjadi boolean.

GET profile mengembalikan seluruh field profil dengan shape flat di data, termasuk audioAnalysisEnabled/timezone dan metadata read-only. PATCH memakai field subset; field yang tidak dikirim tetap utuh. name/otherAllergies dikosongkan dengan empty string, age/heightCm/weightKg/preference/eatingPattern dengan null; array memakai [] dan boolean harus boolean. Null untuk field non-nullable ditolak. Ukuran tubuh di API adalah JSON number, bukan string berkomma; tim frontend melakukan konversi dari input lokal seperti yang sudah dilakukan _decimal.

Semantik update berdasarkan kelompok field yang disertakan, tanpa menambah endpoint baru:
- Identitas (name, age, heightCm, weightKg): boleh disimpan ketika priorities masih []; tidak mengubah personalisasi/audio.
- Personalisasi (preference, priorities, eatingPattern, prefersHalal, allergyStatus, allergies, otherAllergies): setelah merge, wajib minimal satu priority valid. Initial profile dengan [] tetap sah untuk GET/scan; aturan ini khusus penyimpanan personalisasi seperti UI.
- Pengaturan (audioAnalysisEnabled, timezone): boleh diubah terpisah tanpa mewajibkan priorities dan tanpa mengubah data profil lain.
- Bila hasil merge allergyStatus=listed, wajib ada minimal satu allergies atau otherAllergies nonempty. Saat status berubah ke unknown/noneKnown, clear allergies dan otherAllergies secara atomik. Tolak payload yang secara eksplisit mengirim bahan nonempty bersama status non-listed; bila bahan tidak dikirim, bersihkan bahan lama. Validasi invariant dilakukan terhadap hasil merge, bukan patch terpisah.
- UI editor mengembalikan model lengkap melalui callback, belum melakukan HTTP. Handoff harus meminta tim frontend mengirim field kelompok yang diedit; full stale-object PATCH dapat menimpa kelompok lain. Identitas-only tidak boleh mengirim priorities=[] sebagai pengganti field yang tidak diedit.

Seed default mengikuti constructor NutritionProfile: name='', numeric/preference/eatingPattern=null, priorities/allergies=[], prefersHalal=false, allergyStatus=unknown, otherAllergies='', audioAnalysisEnabled=false, timezone development. Jangan mengarang usia, ukuran tubuh, alergi, atau fokus nutrisi. Fixture profil lengkap untuk tes dibuat terpisah; menjalankan seed ulang tidak menimpa koreksi pengguna maupun pilihan audio.

Penyimpanan field profil tidak berarti semua field dikirim ke DeepSeek. RAG mengambil priorities, preference, eatingPattern, prefersHalal, serta allergyStatus/bahan relevan. Nama, usia, tinggi, berat, email, password, dan audio tidak dikirim; timezone hanya dipakai backend untuk memilih periode riwayat. Tidak menghitung BMI/target energi/berat dari field tubuh. Unknown allergy dan ketiadaan data bahan tidak boleh berubah menjadi klaim aman; halal preference tidak membuktikan produk halal.

Catatan handoff: copy privasi di kedua screen saat ini menyatakan data hanya selama sesi dan tidak dikirim ke server. Tim frontend harus memperbarui pernyataan ini sebelum mengaktifkan integrasi backend/LLM; perubahan UI tersebut tetap di luar change ini. Audio disimpan sebagai preferensi saja, bukan implementasi TTS server.

### 2. Identitas development dan routing

Domain routes memerlukan flag eksplisit `ENABLE_DEMO_USER=true`, NODE_ENV development/test, serta `DEMO_USER_EMAIL` yang cocok dengan seed. Resolver di server menentukan owner. Tolak userId/header override; tidak menerima pemilik melalui payload. Bila disabled, domain routes tidak tersedia. Dokumentasikan server lokal ini bukan layanan multi-user atau endpoint publik aman.

Gunakan `${API_PREFIX}/v1`, sehingga default `/api/v1`, tanpa mengubah route starter `/api/users` atau health. Setiap router memiliki `.openapi.ts` dan didaftarkan di assembler yang sudah ada.

| Method | Path relatif terhadap API_PREFIX | Perilaku |
|---|---|---|
| GET | /v1/profile | Profil dummy aktif |
| PATCH | /v1/profile | Update parsial identitas, personalisasi, atau audio/timezone sesuai bagian 1a |
| POST | /v1/scans | Analisis dan langsung membuat konsumsi |
| GET | /v1/food-entries | Daftar paginated, filter tanggal lokal opsional |
| GET | /v1/food-entries/:id | Detail konsumsi dan provenance |
| PATCH | /v1/food-entries/:id/quantity | Ubah quantity dalam unit yang sama |
| DELETE | /v1/food-entries/:id | Hapus konsumsi, simpan tombstone deduplikasi |
| GET | /v1/nutrition/daily?date=YYYY-MM-DD | Ringkasan hari berdasarkan timezone profil |

Pertahankan envelope starter `success`, `message`, `data`, `timestamp`; domain errors menambahkan machine-readable code di data tanpa mengubah kontrak starter. Status: 201 create, 200 replay/read/update, 204 delete, 400 invalid metadata, 413 size, 415 format, 422 nonfood/uncertain label, 409 reused key/in-progress/unknown dispatch, 410 deleted replay, 429 rate limit, 502 invalid provider output, 504 provider timeout, 503 configuration/database failure. Detail kontrak dan contoh wajib tercatat sebelum handoff.

### 3. Input scan dan penyimpanan sementara

Multipart fields: image wajib (JPEG/PNG), mode food|label, description opsional, rawOcrText wajib nonempty pada label, consumedAt ISO8601 opsional (default waktu penerimaan yang dibekukan), quantity opsional positive (default 1). Header Idempotency-Key wajib UUID. Baseline batas: image 5 MiB dan 20 megapixel, description 1.000 karakter, OCR 20.000 karakter; total multipart dibatasi dengan overhead terukur. Tolak field tak dikenal/berulang.

Parser multipart berlimit dan decoder gambar diperlukan karena express.json tidak menerima file. Validasi magic bytes dan actual decode; jangan mempercayai MIME/ekstensi. Normalize orientation, resize maksimum 1600 px sisi terpanjang, strip metadata, lalu kirim data URL langsung dari backend. Jangan fetch URL dari input. Bersihkan buffer/temp files di jalur sukses, error, dan pembatalan. Tidak menyimpan image/base64 dalam MySQL; API awal tidak menjanjikan thumbnail permanen.

### 4. RAG sebelum satu panggilan

1. Ambil profil pemilik dengan allowlist bagian 1a: prioritas, preference, eatingPattern, prefersHalal, allergyStatus, allergies, otherAllergies. Profil tanpa prioritas tidak diberi prioritas buatan. Jangan kirim nama/usia/ukuran tubuh/audio/email/password.
2. Hitung ringkasan hari konsumsi dari entri sebelumnya; sertakan known subtotal, jumlah nilai hilang, provenance counts, timezone, dan waktu snapshot. Untuk backdated scan, jangan gunakan konsumsi setelah consumedAt sebagai konteks sebelumnya.
3. Pilih maksimal 5 entri relevan dari 7 hari sebelumnya dengan ranking kata kunci description/OCR dan recency. Jangan menganggap foto sudah dikenal sebelum vision.
4. Ambil maksimal 3 chunk reviewed berdasarkan prioritas/tag dan pencarian teks berparameter pada OCR/deskripsi. Ranking deterministik dan tie-break ID. Batasi total konteks tekstual retrieval sekitar 8.000 karakter.
5. Sertakan ID dan versi sumber sebagai allowlist citation. Simpan sumber yang digunakan dan snapshot ringkas; respons tidak mengirim data pengguna lain.

Untuk corpus kecil, SQL/tag/text retrieval cukup, tidak butuh vector store atau LLM pembuat query. Cold start memakai profil saja dan eksplisit menyatakan history/reference kosong. Seed referensi harus punya sumber dan izin penggunaan yang diperiksa; sumber yang belum diperiksa tidak aktif. Personalisasi tidak melakukan kalkulasi target medis.

### 5. DeepSeek dan hasil nutrisi

Satu HTTP native fetch dengan timeout dan batas response; model vision dipilih lewat environment. Dokumentasi DeepSeek yang diperiksa saat eksplorasi menyebut `deepseek-flash` mendukung image input; verifikasi model dan akses akun sebelum live smoke test. Tidak mengasumsikan semua model DeepSeek mendukung vision. Tidak memakai tool loop, retries otomatis, atau JSON repair melalui panggilan kedua.

System prompt terpisah untuk mode food/label dalam kode backend, ditambah konteks RAG. OCR/deskripsi/referensi adalah data tak tepercaya; instruksi di dalamnya tidak boleh menggantikan system prompt. Output JSON berisi relevance/status, identity, portion basis, nutrient values/units/source, uncertainty, qualitative advantages/tradeoffs, dan citation IDs. Schema AJV + pemeriksaan semantik wajib setelah JSON parse.

Kontrak basis: `baseQuantity`, `unitCode`, `displayLabel`, optional `referenceWeightG`/`referenceVolumeMl`, `basisSource`, dan nilai nutrisi pada baseQuantity tersebut. LLM memilih unit dari daftar backend (butir/biji, potong, porsi, g, ml, botol/kemasan); istilah tidak dikenal ditolak. Gram/ml hasil tebakan tetap diberi provenance estimasi, bukan pengukuran foto. Label mempertahankan basis asli per serving/per100g/per100ml dan evidence OCR/image. Jangan mengonversi botol ke serving tanpa volume atau rasio yang cukup; hasil ambiguous meminta input diperjelas dan tidak masuk jurnal.

Nilai foto menjadi `model_estimate`; nilai label menjadi `label_extracted_unverified`. Nutrien yang tidak didukung evidence tetap null, bukan nol atau angka model tambahan. Source ID dari retrieval harus ada di allowlist; RAG penjelasan tidak menjadikan angka model sebagai database verified. Nutrisi canonical mencakup calories_kcal, protein_g, total_fat_g, saturated_fat_g, carbohydrates_g, sugar_g, sodium_mg, fiber_g.

Insight LLM berupa karakter/tradeoff kualitatif dan konteks pada waktu scan. Total konsumsi dihitung backend, tidak mengikuti angka total dari model. Prompt tidak meminta skor sehat universal, diagnosis, jaminan bebas alergen, atau klaim numerik porsi yang menjadi usang. Kehilangan layanan vision membuat scan gagal secara jujur; jurnal lama dan koreksi kuantitas tetap berfungsi tanpa provider.

### 5a. Ringkasan khusus text-to-speech

Tambahkan instruksi system prompt (bukan prompt injection dari input pengguna) untuk menghasilkan field `ttsSummary` di JSON yang sama dengan analisis food/label. Field disediakan pada setiap hasil sukses, termasuk saat audioAnalysisEnabled=false, sehingga pengguna dapat mengaktifkan audio belakangan tanpa request DeepSeek baru. Backend hanya menghasilkan teks; playback dan integrasi pada scan_result_screen.dart milik tim frontend.

Kontrak `ttsSummary`: plain text bahasa Indonesia, 2-3 kalimat pendek, maksimal 60 kata dan 450 karakter setelah trim. Tidak ada Markdown, bullet, emoji, URL, citation IDs, SSML, jargon, atau daftar seluruh nilai gizi. Prioritaskan satu insight yang relevan dengan fokus pengguna dan satu trade-off/tindakan sederhana jika didukung hasil; jangan memaksakan kelebihan/kekurangan bila data tidak cukup. Jika ketidakpastian atau data hilang memengaruhi kesimpulan, sebutkan singkat. Dilarang menambahkan angka/klaim di luar analisis, diagnosis, skor sehat universal, atau jaminan bebas alergen/halal.

Usulan blok prompt untuk implementasi:

```text
Isi ttsSummary dengan ringkasan lisan bahasa Indonesia yang mudah dipahami.
Gunakan 2 sampai 3 kalimat pendek, maksimal 60 kata dan 450 karakter.
Pilih satu insight paling relevan dengan prioritas pengguna dan satu trade-off
atau langkah sederhana hanya jika didukung data analisis. Jangan membaca ulang
seluruh kelebihan, kekurangan, atau daftar nutrisi. Sebutkan ketidakpastian
penting dengan singkat. Bila data tidak cukup, katakan demikian tanpa menebak.
Jangan sertakan angka total porsi, kesimpulan terhadap batas konsumsi harian,
atau klaim yang akan berubah ketika jumlah porsi diedit. Gunakan teks biasa
tanpa Markdown, SSML, URL atau sitasi. Jangan membuat klaim medis baru.
```

Validasi tipe/panjang/format ringkasan di backend. Bila hanya ringkasannya kosong, hilang, terlalu panjang atau tidak memenuhi format, gunakan template lokal berbasis status data; jangan panggil model lagi, memotong kalimat secara buta, atau membatalkan konsumsi yang analisis intinya valid. Bila ada indikasi kontradiksi dengan analisis, gunakan fallback yang sama; validasi otomatis tidak dianggap bukti akurasi semantik menyeluruh. Contoh fallback untuk foto estimasi: "Nilai nutrisi makanan ini masih berupa perkiraan. Periksa jenis makanan dan porsi yang tercatat sebelum menggunakan hasilnya sebagai acuan." Core analysis invalid tetap mengikuti jalur kegagalan scan.

Simpan `ttsSummary` dan `ttsSummarySource` (`model` atau `template`) dalam payload insight berversi FoodEntry; kembalikan pada respons POST scan, detail, dan update quantity. Ringkasan tidak memuat angka total atau penilaian ambang harian sehingga tetap dapat dibacakan setelah quantity berubah. Ringkasan tidak menjanjikan penilaian ulang profil/riwayat secara live; konteksnya tetap saat scan. Tidak ada tabel/endpoint TTS baru dan tidak menambahkan server TTS atau frontend dependency.

### 6. At-most-once dispatch dan simpan konsumsi

Fingerprint mencakup hash image bytes serta metadata yang dinormalisasi, termasuk presence field opsional; default waktu tidak dihitung ulang pada replay. Atomic claim ScanRequest dengan unique owner/key dilakukan sebelum dispatch. Request identik mengambil state existing; fingerprint berbeda mendapat 409. Commit state dispatched sebelum HTTP; jangan menahan transaksi DB selama network call.

Sukses: validasi lalu transaksi membuat FoodEntry dan menyelesaikan ScanRequest. Error/timeout tidak membuat konsumsi. Jika proses crash setelah dispatch, state dianggap uncertain dan tidak otomatis dikirim ulang: at-most-once mengorbankan recovery otomatis. User dapat memulai scan baru dengan key baru setelah melihat error, yang merupakan operasi baru dan bisa memakai biaya baru. Transaksi gagal setelah provider sukses tidak memicu provider retry. Hapus entry tidak menghapus tombstone key; replay mengembalikan deleted, bukan mencatat ulang.

### 7. Porsi, ringkasan, dan pembagian service

Rumus setiap nutrient: `baseValue * quantity / baseQuantity`; null tetap null. Simpan Decimal, gunakan arithmetic decimal yang tersedia dengan Prisma, bulatkan hanya pada serialization/tampilan. Quantity positive finite, batas domain terdokumentasi; koreksi tidak mengubah unit/komposisi. Summary mengembalikan nullable knownTotal, knownCount, missingCount, complete, dan provenance counts per nutrient. Empty day memiliki entryCount=0, bukan bukti tidak makan. Ambil batas hari timezone IANA lalu query consumedAt UTC; jangan hardcode UTC+7.

Controllers menangani HTTP. Service profil, scan orchestration, retrieval, DeepSeek, dan jurnal dibuat sesuai kebutuhan; kalkulasi pure function bisa berada di service jurnal. Reuse ApiResponse, AppError, AJV, rate limiter, getPrismaClient. Tidak menambah layer repository generik. Batas scan concurrency dan rate limit diterapkan sebelum provider untuk menjaga memori dan biaya.

## Risks / Trade-offs

- Estimasi foto belum terverifikasi: provenance dan uncertainty wajib; tidak dipromosikan menjadi referensi tepercaya untuk scan berikutnya.
- Satuan LLM dapat salah: allowlist dan basis wajib; menolak ambiguitas lebih baik daripada menghitung konversi palsu.
- Koreksi jumlah tidak memperbarui paragraf model: pisahkan insight scan-time dari total terkini; jangan menjanjikan insight harian yang terus diperbarui.
- Dummy user tidak mengisolasi manusia yang memakai server bersama: hanya development lokal, bukan deployment publik.
- Tanpa thumbnail persisten, frontend harus menggunakan foto lokal; penyimpanan foto server menjadi scope terpisah bila diminta.
- At-most-once provider dispatch tidak menjamin setiap scan berhasil setelah crash; state uncertain terlihat dan tidak diulang diam-diam.
- Estimasi/satuan LLM berbeda dengan DEC-004/005/006: approval tasks harus mencakup arah ini dan pembaruan dokumen terkait sebelum implementasi.

## Migration Plan

Setelah persetujuan: tambahkan schema dan migration ter-review; generate client; jalankan migration/seed hanya pada MySQL development yang dituju. Gunakan credential seed dari environment lokal; tidak mengubah `.env` secara otomatis. Verifikasi seed berulang tidak menghapus data. Semua domain route dapat dinonaktifkan melalui demo flag. Rollback aplikasi menonaktifkan route sambil mempertahankan tabel/data; jangan menjalankan reset/drop database otomatis. Handoff menyertakan OpenAPI, contoh request, source limitations, dan hasil tes; tidak menjalankan deploy atau commit tanpa permintaan.
