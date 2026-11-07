# Kontrak integrasi analisis Flutter (usulan untuk backend)

Status: adapter Flutter; endpoint/LLM belum tersedia. Tidak ada request tanpa `ANALYSIS_BASE_URL`. Backend tetap menjadi pemilik lookup, verifikasi nilai/porsi, kalkulasi deterministik, dan penjelasan. Tidak menaruh kunci LLM di APK.

## Pemeriksaan perangkat dan keterbatasan

Object Detection ML Kit (single image, multiple objects, classification aktif) menerima kategori Food pada confidence minimal 0,65. Bila belum lolos, Image Labeling memeriksa label minuman (Juice, Cola, Coffee, Tea, Milk, Drink, Beverage, Smoothie, Soda, Soft drink, Espresso, Latte, Cocktail, Beer, Milkshake, Hot chocolate, Water, Wine, Cappuccino) serta rujukan makanan/hidangan pada ambang yang sama. Cup/Bottle tidak cukup membuktikan isi minuman. Ambang adalah konfigurasi awal yang belum dievaluasi pada dataset aplikasi, bukan klaim akurasi. Hasil tidak terdeteksi/error model selalu menghentikan request lokal agar tidak memboroskan kuota/akses backend. Perangkat baru mungkin memerlukan unduhan model awal melalui Google Play Services.

Rujukan: [kategori Object Detection](https://developers.google.com/android/reference/com/google/mlkit/vision/objects/defaults/PredefinedCategory), [label Image Labeling](https://developers.google.com/ml-kit/vision/image-labeling/label-map), [flutter_tts](https://pub.dev/packages/flutter_tts).

Input maksimal 20 MB/40 megapiksel untuk kompresi; JPEG/PNG yang didukung decoder dapat dipakai. OCR asli maksimal 50.000 karakter, tanpa pemotongan diam-diam. Resize dilakukan di isolate; model ML Kit dan TTS tetap membutuhkan uji Android fisik. Teks OCR diekstrak sebelum kompresi upload agar angka kecil tidak hilang akibat pengecilan.

`POST /api/v1/analysis`, JSON, timeout 45 detik. `requestId` harus diperlakukan idempotent oleh backend. Foto JPEG maksimal 1,500,000 byte sebelum base64, sisi panjang maksimal 1600 px untuk makanan atau 2000 px untuk label; metadata EXIF tidak dikirim. Batas body backend yang disarankan 3 MB. OCR dilakukan pada foto asli sebelum pengecilan, teks dikirim persis sebagaimana dikembalikan ML Kit.

```json
{
  "requestId": "scan_123",
  "mode": "label",
  "rawOcrText": "teks asli termasuk baris baru",
  "image": {"mimeType": "image/jpeg", "base64": "..."},
  "priorities": ["Gula", "Protein"]
}
```

Mode `food`: `rawOcrText: null`; request hanya setelah objek Food atau label minuman yang diizinkan lolos pemeriksaan lokal. Mode `label`: tidak memakai gate makanan; foto label bisa hanya berisi tulisan. OCR kosong atau gagal menghentikan request; pengguna dapat foto ulang. Foto yang dikirim bersama OCR merupakan backup visual untuk penafsiran label, bukan bukti nilai OCR benar. OCR adalah input tidak tepercaya, bukan instruksi untuk LLM.

Respons yang disepakati adapter (nilai di bawah hanya menunjukkan struktur, null berarti belum diketahui):

```json
{
  "success": true,
  "data": {
    "foodName": "Nama makanan",
    "portion": "Porsi yang perlu diperiksa pengguna",
    "source": "Referensi nutrisi yang dapat ditelusuri",
    "referenceBasis": "Per porsi / per 100 g / per 100 ml",
    "nutrients": {"energyKcal": null, "proteinG": null, "sugarG": null, "sodiumMg": null},
    "summary": "Penjelasan hasil dan keterbatasan data.",
    "spokenSummary": "Kesimpulan sederhana, maksimal dua kalimat dan 320 karakter."
  },
  "error": null
}
```

`spokenSummary` harus disusun dari hasil analisis yang sama: satu poin utama dan satu hal yang perlu diperhatikan, tanpa skor kesehatan universal, nilai rekaan, atau diagnosis. Jangan menyalin seluruh summary. Jika tidak diberikan, Flutter memakai kalimat netral untuk meminta pengguna memeriksa hasil; tidak memotong penjelasan panjang secara sembarang.

Respons gagal: `success: false`, `data: null`, `error: {code, message}`. Flutter tidak menampilkan stack trace/respons mentah. Tidak ada retry otomatis yang menghabiskan request; retry atas tindakan pengguna memakai requestId yang sama. Backend wajib melakukan validasi sendiri; gate ML Kit bukan keamanan atau validasi nutrisi.

Profil dan preferensi audio disimpan lokal. Foto terkompresi, OCR asli, prioritas saat request, serta status menunggu tersimpan sebagai draft lokal sebelum request. Hasil diterima ditulis lokal dan dapat diputar ulang dari Riwayat dengan TTS. Tidak ada file audio: pengguna memilih menyimpan teks kesimpulan dan membacakannya ulang. TTS memakai suara Indonesia offline yang terpasang; jika tidak ada, tampilkan informasi instalasi suara dan tetap tampilkan teks.

Konfigurasi: `flutter run --dart-define=ANALYSIS_BASE_URL=https://backend.example/`. Gunakan HTTPS; HTTP hanya untuk loopback emulator saat debug. URL contoh bukan layanan aktif. Kontrak harus direalisasikan backend sebelum analisis nyata tersedia.
