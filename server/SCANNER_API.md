# Handoff backend scanner

Backend development saja; frontend tidak diubah. Sumber kontrak lengkap: `/api/openapi.json` dan `/api/docs/`; prefix default `/api`, delapan operasi domain di `/api/v1`. Setup dummy seed ada di [README.md](README.md#scanner-konsumsi-development). Tidak ada endpoint login; email/password seed disimpan sebagai identitas development dan hash, bukan dikirim lewat HTTP.

| Method | Path | Hasil |
|---|---|---|
| GET/PATCH | `/api/v1/profile` | Profil owner konfigurasi server |
| POST | `/api/v1/scans` | 201 simpan konsumsi, 200 replay |
| GET | `/api/v1/food-entries?date=2026-11-07&page=1&limit=20` | `{entries,total,page,limit}` |
| GET | `/api/v1/food-entries/{id}` | Detail dan snapshot analisis |
| PATCH | `/api/v1/food-entries/{id}/quantity` | Detail dengan total baru |
| DELETE | `/api/v1/food-entries/{id}` | 204 tanpa body; key menjadi tombstone |
| GET | `/api/v1/nutrition/daily?date=2026-11-07` | Subtotal catatan hari lokal |

Semua respons JSON memakai `{success,message,data,timestamp}`. Error domain memakai `success:false`, `data:{code:"INVALID_INPUT"}` dan message aman. Pengecualian: DELETE 204 tanpa body; rate limiter starter dapat mengembalikan teks. Jangan membaca stack/error provider sebagai pesan pengguna.

## Contoh request

Perintah berikut memakai shell dengan sintaks curl standar (`curl.exe` pada Windows; tulis sebagai satu baris). Ganti key UUID untuk operasi baru; pertahankan key dan input persis untuk pemeriksaan ulang request sama.

```sh
curl -X POST http://localhost:3000/api/v1/scans -H "Idempotency-Key: 108ca11c-e9ae-4f66-b671-5689d998ff19" -F "mode=food" -F "description=Telur rebus yang saya makan" -F "quantity=1" -F "image=@food.jpg;type=image/jpeg"
curl -X POST http://localhost:3000/api/v1/scans -H "Idempotency-Key: 11bb71ae-f211-4386-ae99-06d152951105" -F "mode=label" -F "rawOcrText=Takaran saji 100 g. Protein 5 g" -F "image=@label.jpg;type=image/jpeg"
curl -X PATCH http://localhost:3000/api/v1/food-entries/ENTRY_ID/quantity -H "Content-Type: application/json" -d '{"quantity":2}'
curl http://localhost:3000/api/v1/nutrition/daily?date=2026-11-07
```

Contoh payload profil, kirim melalui PATCH `/api/v1/profile` dengan `Content-Type: application/json`:

```json
{"name":"Naya","age":22,"heightCm":null,"weightKg":null}
```
```json
{"preference":"Masakan rumahan","priorities":["Gula","Protein"],"eatingPattern":"Vegetarian","prefersHalal":true,"allergyStatus":"listed","allergies":["Susu"],"otherAllergies":""}
```
```json
{"audioAnalysisEnabled":true}
```

Identity/settings tidak wajib prioritas. Personalization wajib minimal satu prioritas setelah merge. `{"name":"","age":null}` membersihkan identitas opsional; `{"allergyStatus":"noneKnown"}` membersihkan bahan tersimpan. Kirim hanya kelompok yang diedit, bukan seluruh model lama dari callback editor Flutter. Daftar vocabulary persis mengikuti `src/validation/nutrition.ts` dan OpenAPI; preference keseharian berbeda dari eatingPattern.

## Contoh respons sintetis

Berikut cuplikan `data` food scan, bukan nilai makanan nyata. Respons penuh juga memiliki description, rawOcrText, model, promptVersion, context, timestamps dan seluruh field analysis sesuai OpenAPI.

```json
{
  "id":"b75cd08a-de68-4a40-9822-c65eac50d22c",
  "mode":"food",
  "title":"Synthetic fixture",
  "quantity":1,
  "baseQuantity":1,
  "provenance":"model_estimate",
  "nutrients":{"calories_kcal":null,"protein_g":5,"total_fat_g":null,"saturated_fat_g":null,"carbohydrates_g":null,"sugar_g":null,"sodium_mg":null,"fiber_g":null},
  "ttsSummary":"Nilai nutrisi masih berupa perkiraan. Periksa porsi dan data yang belum lengkap.",
  "ttsSummarySource":"model"
}
```

Untuk label, `mode="label"`, `provenance="label_extracted_unverified"`, `rawOcrText` dipertahankan dan `analysis.evidence.protein_g` dapat berupa `{"origin":"ocr","text":"Protein 5 g"}`. `analysis.portion` contoh: `{"baseQuantity":1,"unitCode":"porsi","displayLabel":"1 porsi","basis":"per_serving","originalServingText":"Takaran saji 100 g","referenceWeightG":100,"referenceVolumeMl":null}`. Evidence tidak cocok berarti nilai null; bukan nol. Angka image tetap hasil ekstraksi belum diverifikasi. Unit dikunci setelah scan.

PATCH quantity `2` pada fixture di atas mengembalikan `quantity:2`, `nutrients.protein_g:10`, `baseNutrients.protein_g:5`; gula tetap null dan `ttsSummary` sama. Tidak ada panggilan LLM baru. Kembali ke quantity `1` menghasilkan protein `5`, tanpa pembulatan kumulatif.

Cuplikan `data` daily untuk satu fixture tersebut:

```json
{
  "date":"2026-11-07",
  "timezone":"Asia/Jakarta",
  "entryCount":1,
  "recordedIntakeOnly":true,
  "nutrients":{
    "protein_g":{"knownTotal":5,"knownCount":1,"missingCount":0,"complete":true,"provenanceCounts":{"model_estimate":1}},
    "sugar_g":{"knownTotal":null,"knownCount":0,"missingCount":1,"complete":false,"provenanceCounts":{"model_estimate":1}}
  }
}
```

Respons penuh mempunyai delapan nutrient. Hari kosong berarti belum ada catatan, bukan belum makan; knownTotal null. Filter tanggal mengikuti timezone profil, termasuk DST. Koreksi/hapus langsung memengaruhi daftar, daily dan retrieval berikutnya; snapshot insight entri lama tidak dianalisis ulang.

## TTS dan privasi

Prompt v3 mengarahkan `ttsSummary` menjadi bahasa obrolan yang ramah untuk orang awam: gunakan "kamu", "tapi", "cek lagi" dan "perkiraan"; hindari istilah laporan/teknis seperti provenance, terverifikasi, trade-off, atau "mendukung fokus protein". Jelaskan tujuan dengan bahasa sehari-hari sesuai profil, misalnya "kalau kamu lagi mengurangi gula". Tetap 2–3 kalimat, maksimal 60 kata/450 karakter, berbasis pro/cons tanpa klaim tambahan. Template terakhir juga memakai bahasa sederhana. Penilaian keterbacaan seluruh output model tetap memerlukan review manusia; instruksi gaya bukan bukti akurasi semantik.

Respons scan, daftar/detail dan koreksi quantity menyediakan `data.pros` serta `data.cons` sebagai array string. Keduanya alias dari `data.analysis.advantages`/`data.analysis.tradeoffs`, bukan analisis kedua. Untuk kartu Kelebihan/Kekurangan pada `scan_result_screen.dart`, consumer dapat memakai `pros.join('\n')` dan `cons.join('\n')`. Screen saat ini masih menggunakan `_kelebihanText`/`_kekuranganText` preview lokal; integrasi HTTP/mapping tetap pekerjaan frontend, tanpa perubahan app pada backend change ini.

Prompt `scanner-2026-11-v2` meminta pro/cons konkret bagi prioritas, preferensi dan konteks riwayat yang tersedia. `ttsSummary` merangkum satu pro, satu cons dan ketidakpastian relevan dalam 2–3 kalimat pendek; boleh menyebut peran protein/gula tanpa daftar angka. Ringkasan tidak menambah klaim baru, total quantity atau penilaian medis. Model tetap satu panggilan. Bila summary invalid, fallback mencoba kalimat lengkap dari insight tersimpan dan fokus pengguna; jika terlalu panjang/tidak aman formatnya, template ketidakpastian tetap dipakai. Ketika evidence tidak cukup, pro/cons menyatakan keterbatasan, bukan mengarang manfaat/kerugian. Record lama dengan arrays kosong tetap dibaca apa adanya; tidak dipanggil ulang ke provider.

Contoh cuplikan service live v2 untuk fixture foto nasi/ayam (nilai model, bukan bukti medis):

```json
{
  "pros": ["Ayam memberi protein, mendukung fokus protein pengguna."],
  "cons": ["Bahan saus tidak jelas, sehingga risiko susu atau wijen belum bisa dinilai."],
  "ttsSummary": "Ayam pada hidangan ini memberi protein yang mendukung fokus protein Anda, dan gulanya diperkirakan rendah. Namun bumbu bisa membuat natrium cukup tinggi, dan bahan saus belum jelas sehingga alergi susu atau wijen belum dapat dinilai. Porsi serta nilai gizi hanya estimasi dari foto, bukan pengukuran.",
  "ttsSummarySource": "model"
}
```

Arrays di cuplikan dipendekkan; summary live merangkum arrays lengkap. Semua insight menggunakan snapshot saat scan dan tetap sama ketika quantity diubah; hanya total nutrient dihitung ulang.

Unit botol/kemasan hanya diterima bila teks takaran menyebut satu botol/kemasan secara eksplisit serta memiliki berat/volume acuan; backend tidak menebak konversi dari sajian ke seluruh kemasan. Label yang hanya menyebut gram/ml dapat mempertahankan unit gram/ml atau sajian dengan basis asli.

`analysis.portion.basisSource` ditentukan backend: `model_estimate` atau `label_extracted_unverified`, terpisah dari kode `basis` per_serving/per_100g/per_100ml. Profil tidak mengubah basis atau nilai nutrient sumber.

Sinkronkan ValueNotifier audio frontend dengan `GET profile`/PATCH `audioAnalysisEnabled`. Backend selalu menyediakan `ttsSummary` dan `ttsSummarySource` (`model`/`template`), plain text Indonesia 2–3 kalimat, maksimal 60 kata/450 karakter. Backend tidak menghasilkan audio. Playback pada `scan_result_screen.dart` tetap tugas frontend. Bila summary model tidak valid, template lokal dipakai tanpa request tambahan.

Sebelum integrasi, ubah copy frontend yang menyatakan data session-only/tidak dikirim ke server. Profil dan jurnal kini persisten; foto/OCR/deskripsi dan profil allowlist/riwayat relevan dikirim ke provider eksternal. Nama/usia/ukuran tubuh/audio/email/password tidak masuk retrieval provider. Jangan menyatakan hasil foto sebagai pengukuran akurat, label sebagai data verified, halal/alergi sebagai jaminan, atau subtotal sebagai seluruh konsumsi nyata.

RAG SQL/tag/text menyimpan context snapshot berisi profile, recordedDaily, history, references dengan ID/versi/URL sumber. Tidak ada vector DB. Riwayat estimasi tetap punya provenance; referensi menjelaskan konsep, bukan membuktikan angka nutrient model.

Live service DeepSeek melalui 9Router telah diuji untuk food dan label dengan fixture nonpribadi: kedua respons HTTP 200 dan lolos validasi backend, satu dispatch per mode. Uji tidak menambah konsumsi fixture; HTTP/persistensi diuji terpisah dengan provider mock. Model, latensi, hasil TTS dan batas observasi ada di [README backend](README.md#live-smoke-test-9router--7-november-2026). Tidak ada perubahan Flutter dalam change ini.
