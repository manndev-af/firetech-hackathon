# Arsitektur NutriLens AI

## Implementasi scanner backend — 7 November 2026

Jalur scanner terbaru mengikuti [keputusan pengganti](DECISIONS.md): multipart gambar + mode + deskripsi + OCR label, validasi file, retrieval SQL profil/riwayat/referensi reviewed, satu panggilan DeepSeek multimodal, validasi JSON/provenance, dan transaksi jurnal. ScanRequest dengan unique owner/key mencegah pengiriman ulang dan catatan ganda. Kalkulasi quantity dan ringkasan harian berjalan deterministik tanpa LLM. Foto bersifat sementara; tidak ada penyimpanan foto permanen atau vector database.

Model domain MySQL: User, NutritionProfile, FoodEntry, KnowledgeChunk, ScanRequest. Profil mengikuti Flutter termasuk allergyStatus tiga keadaan dan audioAnalysisEnabled. Nama/usia/ukuran tubuh/audio tidak dikirim ke DeepSeek. Domain routes hanya untuk identitas dummy development, bukan autentikasi produksi. Kontrak aktual dan setup ada di [server/README.md](../server/README.md). Bagian konseptual lama di bawah dipertahankan sebagai riwayat; untuk scanner, addendum ini mengesampingkan alur ONNX/verified-only yang belum diterapkan.

Dokumen ini merangkum arsitektur konseptual dan pembagian tanggung jawab yang menjadi panduan implementasi. `SUMMARY.md` adalah sumber konteks produk lengkap; keputusan yang diusulkan di dalamnya tetap dibedakan dari keputusan yang telah disepakati. Pembaruan terbaru mengenai Nutrition Profile tercatat pada addendum di bagian akhir [SUMMARY.md](SUMMARY.md).

## 1. Tujuan dan Batas Produk

NutriLens AI membantu pengguna memahami nutrisi makanan dan membandingkan trade-off berdasarkan preferensi yang mereka pilih. Produk mendukung keputusan dan literasi nutrisi; bukan diagnosis, konsultasi dokter, rekomendasi pengobatan, atau pengganti tenaga kesehatan.

Pipeline produk:

`Kenali → Verifikasi → Analisis → Personalisasi → Jelaskan`

Klasifikasi gambar hanya memprediksi kelas makanan. Identitas makanan dan porsi dikonfirmasi pengguna. Nilai nutrisi berasal dari sumber yang dapat ditelusuri, kalkulasi dilakukan secara deterministik, dan LLM (jika digunakan) hanya membantu penjelasan.

## 2. Komponen dan Tanggung Jawab

Pembaruan lokal: `local_app_state` memuat snapshot melalui `path_provider` sebelum `runApp`; model profil/riwayat/draft memiliki serialisasi JSON. `LocalStorage` mengantre write, memakai file sementara serta snapshot backup, dan melaporkan kegagalan. `ScanPipeline` menjalankan gate ML Kit untuk makanan atau OCR untuk label, memperkecil foto di isolate, dan menyimpan draft sebelum `AnalysisApi` mengirim request. API terkonfigurasi melalui `ANALYSIS_BASE_URL`, tanpa kunci LLM dalam aplikasi. `AnalysisContent` menampilkan hanya nilai respons nullable dan memakai `SummarySpeech` untuk kesimpulan singkat; history replay tidak perlu backend. Nilai hasil scan contoh lama tidak dipakai dalam alur nyata. Catatan session-only sebelumnya historis. Lihat [kontrak](SCAN_API.md).

Revisi editor Profil: `NutritionProfileScreen` dipakai ulang dengan `ProfileEditSection.identity` atau `.personalization` dan `inline: true` di `ProfileScreen`. Draft lokal baru diterapkan melalui callback `onSave` ke notifier router. Mode standalone lama tetap tersedia untuk route `/profile/nutrition`. Tidak ada model/persistensi/API baru; `PersonalPage` menerima scroll controller opsional untuk kembali ke ringkasan setelah form ditutup.

Pembaruan akses review: `UI_PREVIEW` pada router kini memiliki default `true` agar tab Riwayat langsung terisi contoh sesuai permintaan pengguna. Nilai `false` menampilkan alur tanpa fixture. Constructor `HistoryScreen` tetap default `preview: false`; hanya konfigurasi route review yang mengaktifkannya. Tidak ada persistensi atau kalkulasi tambahan.

Revisi review pengguna: `analysisAudioSession` menyimpan preferensi audio sebagai notifier bool dalam memori router, independen dari draft profil. Tidak ada layanan TTS baru. `ScanHistoryEntry` memiliki `photoPath` untuk file capture lokal dan `photoAsset` untuk fixture. Tampilan menangani file hilang tanpa crash; integrasi capture/retensi file belum tersedia. Router hanya memasok fixture jika build define `UI_PREVIEW=true`; tidak ada banner dalam build review tersebut. Daftar tanpa filter, dan modal detail memakai root navigator agar berada di atas navigasi aplikasi.

Pembaruan audit 7 November 2026 menggantikan batas UI pada paragraf historis berikut: `NutritionProfile` mencakup tinggi/berat, pola makan/halal, dan status/bahan alergi opsional. Onboarding mempertahankan field tambahan. `ScanHistoryEntry` adalah snapshot tampilan nullable; `history_preview_data.dart` memasok fixture terpisah untuk preview eksplisit. Layar normal mengecualikan record ilustrasi. Filter/detail bekerja di UI tanpa repository atau endpoint baru. State profil tetap dalam memori router; tidak ada kalkulasi nutrisi, persistensi, maupun pengiriman data personal baru. Lihat [audit](PROFILE_HISTORY_AUDIT.md).

Status Flutter 7 November 2026: `NutritionProfile` di `app/lib/models/` merupakan model UI immutable. `ValueNotifier` milik konfigurasi router menyimpan profil dalam memori selama proses aplikasi; onboarding mengisinya, editor memperbaruinya setelah validasi/Simpan, dan Home/Profil mendengarkan perubahan. Tidak ada request API, database, penyimpanan disk, atau penerapan ke Nutrition Engine. Riwayat baru berupa layar filter dan empty state, tanpa repository hasil analisis. Penyimpanan permanen dan retensi tetap keputusan terbuka.

| Komponen | Teknologi yang direncanakan | Tanggung jawab |
|---|---|---|
| Aplikasi mobile | Flutter / Dart | Onboarding, Nutrition Profile, kamera, barcode/OCR, konfirmasi makanan dan porsi, hasil, aksesibilitas dan TTS. |
| API backend | Node.js + TypeScript + Express | Validasi request dan gambar, orkestrasi alur, inference, pencarian/mapping nutrisi, Nutrition Engine, trade-off, dan integrasi penjelasan opsional. |
| Database backend | Prisma ORM 7 + MySQL | Prisma schema/migration untuk penyimpanan backend. Infrastruktur client telah disiapkan; model domain dan fitur persistensi belum ditentukan atau dihubungkan. |
| Training ML | Python + PyTorch + torchvision | Audit subset data, preprocessing, fine-tuning, evaluasi, dan ekspor model. |
| Inference | MobileNetV3-Large, target ekspor ONNX | Klasifikasi makanan dan output top-k beserta confidence; backend menjalankan inference sesuai preprocessing model. |
| Nutrition Engine | Fungsi TypeScript deterministik | Konversi porsi, perhitungan nutrisi, penanganan data hilang, dan aturan insight yang dapat ditelusuri. |
| Sumber nutrisi | TKPI; Open Food Facts; USDA FoodData Central bila perlu | TKPI untuk pangan Indonesia, Open Food Facts untuk produk kemasan, USDA sebagai sumber tambahan yang perlu dicocokkan. |
| LLM (opsional) | Penyedia belum ditentukan | Mengubah hasil terstruktur menjadi penjelasan sederhana; tidak menghitung, mengubah sumber, atau menjadi otoritas medis. |

Gunakan satu backend sederhana dan hindari microservices/infrastruktur yang belum dibutuhkan untuk MVP.

## 3. Alur Data Utama

### Makanan tanpa kemasan

1. Flutter meminta foto makanan dan mengirimkannya ke API.
2. API memvalidasi file dan menjalankan preprocessing yang konsisten dengan training.
3. MobileNetV3-Large mengembalikan top-k kelas dan confidence.
4. Pengguna mengonfirmasi atau mengoreksi kelas (termasuk pencarian manual/foto ulang).
5. Aplikasi memuat konfigurasi porsi untuk kelas yang dipilih; pengguna mengonfirmasi unit dan jumlah.
6. Backend memetakan kelas ke record nutrisi yang memiliki sumber dan basis.
7. Nutrition Engine menghitung nilai sesuai porsi, mempertahankan null untuk data yang tidak tersedia.
8. Aturan personalisasi menyoroti nutrisi sesuai profil/preferensi pengguna.
9. Hasil deterministik ditampilkan dan dapat diteruskan ke LLM untuk penjelasan atau TTS.

### Makanan kemasan

1. Pengguna memindai barcode; sistem mencari produk melalui Open Food Facts.
2. Jika produk/data tidak ditemukan atau tidak lengkap, jalur OCR label atau input manual dapat digunakan.
3. Pengguna memeriksa dan memperbaiki produk, ukuran sajian, nilai dan jumlah sajian.
4. Data terverifikasi pengguna masuk ke Nutrition Engine dan aturan personalisasi seperti pada jalur tanpa kemasan.

Barcode dan OCR merupakan jalur tambahan bila kapasitas MVP memungkinkan; jalur makanan tanpa kemasan adalah fokus demo utama dalam rancangan saat ini.

## 4. Nutrition Profile dan Batas Personalisasi

Profil terbaru dapat mencakup usia/rentang usia, preferensi makanan, dan beberapa prioritas nutrisi: Sugar Awareness, Sodium Awareness, Protein Intake, Calorie Awareness, serta Balanced Nutrition. Tinggi dan berat badan bersifat opsional; alergi makanan juga opsional untuk menandai bahan yang perlu diperhatikan. Aktivitas fisik merupakan pengembangan berikutnya. Riwayat penyakit dan obat tidak termasuk MVP.

Profil memengaruhi fokus penjelasan, perbandingan, atau alternatif yang ditampilkan, tetapi tidak mengubah nilai nutrisi asli makanan. Alergi dapat menjadi penanda berdasarkan informasi bahan yang tersedia; jangan menyiratkan deteksi lengkap bila komposisi tidak diketahui. Jangan menghasilkan diagnosis, konsultasi medis, rekomendasi pengobatan, atau perubahan dosis obat. Fitur medis memerlukan validasi tenaga kesehatan dan perlindungan data kesehatan yang sesuai.

## 5. Model, Dataset, dan Batas Klaim

- Model yang dipilih untuk eksperimen adalah MobileNetV3-Large dengan transfer learning/fine-tuning menggunakan PyTorch.
- Dataset yang direncanakan adalah subset MM-Food-100K. Audit metadata, label, distribusi kelas, duplikasi, ketersediaan/validitas gambar, lisensi, serta potensi data leakage harus dilakukan sebelum training.
- Output model adalah kelas makanan, top-k predictions, dan confidence. Contoh angka dalam dokumen brainstorming adalah ilustrasi, bukan metrik model aktual.
- Model tidak memperkirakan berat, jumlah, porsi, kalori, atau kandungan nutrisi secara langsung.
- Pengguna mengonfirmasi kelas dan porsi. Satuan dan konversi porsi ditentukan konfigurasi terstruktur, bukan LLM.
- Ukuran subset, kelas final, split data, threshold confidence, preprocessing final, dan metrik tetap ditentukan melalui audit dan evaluasi, bukan diasumsikan.
- Jika model diekspor ke ONNX, validasi output dan preprocessing terhadap model PyTorch sebelum dipakai.

## 6. Data Nutrisi dan Perhitungan

Setiap record mempertahankan identitas makanan, sumber, basis (misalnya per 100 g/per sajian), ukuran/satuan, nilai nutrisi, dan keterkaitan dengan skema porsi. Gunakan TKPI sebagai referensi utama yang disarankan untuk pangan Indonesia; Open Food Facts untuk produk kemasan; USDA FoodData Central sebagai tambahan jika diperlukan dan cocok.

Nutrition Engine menghitung dengan unit konsisten. Contoh basis per 100 g:

`nilai_porsi = nilai_per_100g × berat_porsi_g / 100`

Jangan memperlakukan nilai yang tidak tersedia sebagai nol. Jangan memetakan hidangan ke record yang sekadar bernama mirip tanpa menandai ketidakcocokan resep/metode masak. Nutrition data harus diverifikasi dan tidak boleh dikarang untuk demo.

## 7. Antarmuka API

Dokumentasi runtime tersedia melalui Swagger UI di `<API_PREFIX>/docs/` dan OpenAPI JSON di `<API_PREFIX>/openapi.json`. Kontrak aktual terpisah per modul pada `server/src/routes/*.openapi.ts`, lalu dirakit oleh `server/src/config/openapi.ts`. Cakupan saat ini adalah health, CRUD user starter dalam memori, serta profil/scanner/jurnal/nutrisi development pada addendum di atas; tidak ada autentikasi. Detail penggunaan dan verifikasi ada di [README server](../server/README.md#swagger--openapi).

`SUMMARY.md` memuat contoh endpoint awal untuk klasifikasi, pencarian makanan, lookup nutrisi, kalkulasi, insight, barcode, dan OCR. Endpoint tersebut adalah usulan, bukan kontrak yang telah disahkan. Dokumentasikan kontrak API sebelum implementasi, validasi input, terapkan batas ukuran dan validasi MIME/decoding gambar, dan jangan mengekspos secret atau stack trace.

## 8. Evaluasi dan Keandalan

- Laporkan top-1/top-3 accuracy, precision, recall, F1 per kelas, confusion matrix, dan hasil pada test set independen. Jangan menyajikan training accuracy sebagai performa.
- Uji konsistensi preprocessing PyTorch dan ONNX bila deployment ONNX dilakukan.
- Verifikasi kalkulasi per 100 g/per sajian, konversi satuan porsi, nilai null, dan pelabelan sumber/basis.
- Jika inference, lookup, OCR, atau LLM gagal, tampilkan kegagalan dan jalur pemulihan yang jujur. Fallback insight deterministik tetap tersedia tanpa LLM.
- Jangan menampilkan hasil contoh seolah-olah merupakan prediksi atau nutrisi aktual.

## 9. Tahapan Implementasi

1. Audit repository, dataset, dan sumber nutrisi; sepakati scope vertikal slice.
2. Bangun baseline classifier dan evaluasi dengan subset terkelola.
3. Siapkan mapping nutrisi serta skema porsi terverifikasi.
4. Implementasikan alur unpackaged end-to-end: foto → top-k → konfirmasi → porsi → nutrisi → insight.
5. Validasi kalkulasi, model, UX, dan batasan klaim.
6. Tambahkan packaged food, OCR, LLM, TTS, riwayat, dan perbandingan hanya sesuai prioritas/waktu.

Target 24 jam dan urutan terperinci dalam summary adalah rencana brainstorming, bukan jaminan waktu atau komitmen bahwa semua fitur P1 akan selesai.

## 10. Keputusan vs Rekomendasi

### Arah produk yang telah ditetapkan dalam pembaruan terbaru

- Fokus produk adalah pemahaman nutrisi personal yang non-klinis.
- Nutrition Profile berisi prioritas/preferensi; usia, tinggi/berat, serta alergi memiliki status opsional sesuai addendum terbaru.
- Riwayat penyakit dan obat tidak termasuk MVP.
- Model MobileNetV3-Large/PyTorch/MM-Food-100K mengklasifikasikan kelas makanan; pengguna memverifikasi kelas dan porsi.
- Nutrition Engine deterministik, sumber nutrisi dapat diverifikasi, dan LLM hanya menjelaskan.

### Rekomendasi atau keputusan yang masih perlu tim finalisasi

- Nama/branding final dan segmen usia sasaran.
- Daftar kelas, ukuran subset, split, metrik aktual, dan threshold confidence model.
- Record TKPI yang dipetakan dan nilai nutrisi yang telah diekstrak/diverifikasi.
- Detail satuan porsi, rentang/default dan faktor konversi per makanan.
- Apakah barcode/OCR, LLM, TTS, perbandingan, dan riwayat masuk build hackathon.
- Penyimpanan profil/foto dan kebijakan retensi/consent.
- Endpoint API dan infrastruktur data final.

## 11. Konflik Dokumentasi yang Perlu Diperhatikan

Summary awal menyebut tinggi/berat bukan syarat MVP dan menghindari pengumpulan data sensitif; pembaruan brainstorming terbaru mengizinkan tinggi/berat opsional dan alergi opsional, tetap mengecualikan riwayat penyakit serta obat. Pembaruan terbaru dicatat sebagai arah konsep terkini, namun manfaat, kebutuhan, cara penyimpanan, persetujuan, dan perlindungan data untuk field opsional tersebut perlu dikonfirmasi sebelum implementasi.

Summary juga memuat beberapa skala data dan fitur dengan status berbeda: eksperimen awal 2.000 atau 5.000 gambar, usulan sekitar 36.000 gambar dengan split belum disepakati, dan alternatif subset 10.000–20.000. Tidak satu pun boleh dianggap final sebelum audit. Barcode/OCR, TTS, LLM, riwayat, dan perbandingan memiliki prioritas berbeda di bagian dokumen; gunakan P0/P1 dan konfirmasi scope demonstrasi.


### Koreksi basis label - 8 November 2026

Scan label baru dengan basis per sajian dalam gram/ml dinormalisasi menjadi satu porsi dengan massa/volume referensi tetap tersimpan; entri lama dan basis per-100 tidak diubah. Validasi evidence membedakan energi total dari energi lemak/AKG; konflik nyata mengosongkan nilai dan membatalkan insight/TTS terkait. Kontrak dan batasannya ada di [SCANNER_API.md](../server/SCANNER_API.md).

Fallback label: OCR perangkat bersifat opsional secara default; kegagalan OCR tidak memblokir pengiriman gambar ke satu dispatch LLM awal. Build Flutter SCANNER_USE_RAW_OCR=true mempertahankan OCR wajib dan harus diselaraskan dengan flag backend. Validasi gambar, batas OCR 20.000 karakter dan kalkulasi quantity backend tetap berlaku.


### Backend compare - 8 November 2026

Route compare memakai demoOwner, scanSlot bersama scanner, compareUpload, compare.controller dan compare.service. Decoder, requestVision dan totals dipakai ulang tanpa perubahan kontrak scanner. Profil/retrieval dibaca sekali, dua gambar diberi penanda A/B dalam satu dispatch. Backend memvalidasi evidence dan menghitung normalisasi/selisih dengan Decimal; hasil transient tanpa write Prisma/cache/ID lookup. Logger menghilangkan payload compare sebelum parsing. Detail kontrak dan batas narasi ada di [COMPARE_API.md](../server/COMPARE_API.md).
