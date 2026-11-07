# Compare API - handoff Flutter

Kontrak backend compare: POST `{API_PREFIX}/v1/comparisons`, prefix default `/api`. Implementasi frontend dan chat API berada di luar change ini. Gunakan Swagger `/api/docs/` dan JSON `/api/openapi.json` untuk kontrak route aktif.

## Request

Multipart berisi tepat satu `imageA`, satu `imageB`, dan satu string JSON `metadata`:

```json
{
  "a": { "mode": "food", "description": "Pilihan makanan A", "quantity": 1 },
  "b": { "mode": "label", "rawOcrText": "Energi Total 100 kkal", "quantity": 1 },
  "basis": "per_serving"
}
```

Mode wajib `food` atau `label` per pilihan; bisa campuran. `quantity` angka JSON positif 0.000001-10000, maksimal enam desimal, default 1. Description maksimal 1000 karakter dan OCR maksimal 20000 karakter per opsi. `SCANNER_USE_RAW_OCR=false`: OCR opsional dan dikeluarkan dari analisis/retrieval. Jika true, OCR tidak kosong wajib pada setiap mode label. Field asing, owner/userId, consumedAt, URL dan nutrisi dari klien ditolak.

Gambar JPEG/PNG maksimal 5 MiB dan 20 MP per file; MIME harus sesuai isi. Maksimal total multipart 11 MiB termasuk transfer tanpa Content-Length; metadata maksimal 256 KiB UTF-8. Backend memvalidasi dan menormalisasi ke JPEG 1600 x 1600 dengan padding putih, tanpa crop. Tidak menyimpan gambar. Perbandingan tidak membutuhkan Idempotency-Key: request baru dapat memakai satu panggilan berbayar baru, jangan retry otomatis.

Contoh PowerShell, jalankan dari folder `server` (ganti path gambar):

```powershell
curl.exe -X POST http://localhost:3000/api/v1/comparisons `
  -F 'imageA=@C:/samples/food.jpg;type=image/jpeg' `
  -F 'imageB=@C:/samples/label.png;type=image/png' `
  --form-string 'metadata={"a":{"mode":"food"},"b":{"mode":"label","rawOcrText":"Energi Total 100 kkal"},"basis":"per_serving"}'
```

Port mengikuti `PORT` lokal. Jangan atur header Content-Type sendiri; boundary multipart dibuat klien.

## Hasil dan privasi

Sukses memakai HTTP 200 dan envelope `{success,message,data,timestamp}`. Error memakai `{success:false,message,data:{code},timestamp}`. Status: 400 validasi/OCR_REQUIRED, 404 demo disabled, 413 batas upload, 415 tipe/gambar rusak, 422 RESCAN_REQUIRED untuk A/B, 429 SCAN_BUSY, 502 provider/output gagal, 503 konfigurasi/profile/database, 504 timeout 45 detik. Kedua opsi berbagi satu dispatch LLM; capacity maksimal dua operasi scanner/compare bersama.

Database hanya dibaca untuk dummy owner, profil dan konteks personal yang relevan; tidak ada write FoodEntry/ScanRequest/profile, tabel compare, cache hasil, server photo URL atau GET lookup. Logger hanya merekam metadata operasional dan menghilangkan body compare, OCR, gambar dan hasil termasuk saat gagal validasi. Kebijakan retensi provider eksternal terpisah dari perilaku aplikasi.

Contoh error (HTTP 422):

```json
{"success":false,"message":"Pilihan B belum menunjukkan makanan atau basis yang jelas. Foto ulang pilihan tersebut.","data":{"code":"RESCAN_REQUIRED"},"timestamp":"2026-11-08T00:00:00.000Z"}
```

## Basis

- `per_serving` default: nutrisi per jumlah sajian masing-masing; massa/volume yang berbeda atau tidak diketahui ditandai `as_portioned`, bukan dianggap sama.
- `per_100g`/`per_100ml`: hanya dari referensi valid dengan satuan sesuai; quantity tidak mengubah nilai per-100. Tidak mengonversi gram ke ml.
- Tanpa konversi, status `unavailable`, comparedNutrients/differences null; analisis asli A/B tetap ada.
- Delapan key: calories_kcal (kcal), sodium_mg (mg), protein_g/total_fat_g/saturated_fat_g/carbohydrates_g/sugar_g/fiber_g (g). Unknown selalu null, nol tetap nol.
- Differences adalah **B minus A**. Contoh angka sintetis: gula A=12 g/B=6 g menghasilkan -6 g; bukan data nutrisi produk nyata.

## Handoff sesi

CompareScreen kelak mengirim dua gambar dan mode eksplisit, lalu memakai items.a/b untuk kartu dan comparisonBasis untuk label acuan. Angka selisih berasal dari differences, bukan parsing narasi LLM. Simpan respons hanya pada state sesi; "Bahas pilihan ini" membawa snapshot ke layar asisten, bukan ID database. API asisten belum tersedia. Snapshot yang dikirim klien kembali tidak otomatis menjadi data terverifikasi.

| Kebutuhan CompareScreen | Field respons |
|---|---|
| Judul/porsi dan nutrisi kartu A/B | `items.a/b.title`, `quantity`, `portion`, `nutrients` |
| Kelebihan/kekurangan masing-masing | `items.a/b.pros`, `cons` |
| Acuan tabel | `comparisonBasis.requested`, `status`, `reason`, `references` |
| Nilai tabel pada acuan terpilih | `comparedNutrients.a/b` |
| Selisih dan sorotan prioritas | `differences`, `prioritySignals` |
| Penjelasan dan audio | `summary`, `ttsSummary`, `ttsSummarySource` |
| Batas informasi | `warnings`, `items.a/b.provenance` |

`comparisonBasis.references` menjelaskan porsi input aktual; untuk per-100, tabel memakai acuan 100 g/ml pada `requested`. Quantity memakai satuan `portion.unitCode`, bukan parsing `displayLabel`. Foto pratinjau tetap path lokal klien. Untuk "Bahas pilihan ini", simpan snapshot A/B, basis, selisih, prioritas, narasi dan provenance selama sesi. Jangan membuat lookup ID atau menganggap hasil compare mencatat konsumsi.


## Analisis pasangan

Profil/retrieval dibaca satu kali per request; snapshot berisi konteks terbatas tanpa identitas email/password. Hasil foto berstatus model_estimate dan label label_extracted_unverified, bukan nilai terverifikasi. Dua gambar diberi penanda A/B dalam satu payload provider. Tidak ada retry/repair call, cache, write jurnal atau replay. Angka hasil dibandingkan setelah validasi evidence; input yang tidak jelas/nonfood meminta foto ulang pilihan terkait.

prioritySignals.direction menunjukkan arah B terhadap A (lower/higher/equal/unknown); preferredDirection adalah sorotan sesuai profil, bukan keputusan pemenang. Gula/natrium/kalori menyorot lower, protein higher, Keseimbangan tidak diberi bobot/skor. Narasi model tetap kualitatif; angka tabel dan differences dihitung backend. Narasi yang bergantung pada angka ditolak/basis unavailable diganti template dan ttsSummarySource=template. Audio 2-3 kalimat, maksimal 60 kata/450 karakter.


## Contoh respons sintetis

Contoh ini bukan hasil pengukuran makanan atau klaim akurasi model. Selisihnya diperiksa oleh compare.test.cjs.

```json
{
  "success": true,
  "message": "Perbandingan selesai; belum dicatat sebagai konsumsi.",
  "data": {
    "items": {
      "a": {
        "title": "Fixture A (sintetis)",
        "mode": "food",
        "quantity": 1,
        "portion": {
          "baseQuantity": 1,
          "unitCode": "porsi",
          "displayLabel": "1 porsi (100 g)",
          "basis": "per_serving",
          "basisSource": "model_estimate",
          "originalServingText": null,
          "referenceWeightG": 100,
          "referenceVolumeMl": null
        },
        "baseNutrients": {
          "calories_kcal": null,
          "protein_g": 4,
          "total_fat_g": null,
          "saturated_fat_g": null,
          "carbohydrates_g": null,
          "sugar_g": 12,
          "sodium_mg": null,
          "fiber_g": null
        },
        "nutrients": {
          "calories_kcal": null,
          "protein_g": 4,
          "total_fat_g": null,
          "saturated_fat_g": null,
          "carbohydrates_g": null,
          "sugar_g": 12,
          "sodium_mg": null,
          "fiber_g": null
        },
        "evidence": {
          "calories_kcal": null,
          "protein_g": null,
          "total_fat_g": null,
          "saturated_fat_g": null,
          "carbohydrates_g": null,
          "sugar_g": null,
          "sodium_mg": null,
          "fiber_g": null
        },
        "provenance": "model_estimate",
        "pros": [
          "Pertimbangkan sesuai kebutuhanmu."
        ],
        "cons": [
          "Periksa kembali data yang belum jelas."
        ],
        "warnings": [
          "Contoh sintetis, bukan nutrisi produk nyata."
        ]
      },
      "b": {
        "title": "Fixture B (sintetis)",
        "mode": "food",
        "quantity": 1,
        "portion": {
          "baseQuantity": 1,
          "unitCode": "porsi",
          "displayLabel": "1 porsi (100 g)",
          "basis": "per_serving",
          "basisSource": "model_estimate",
          "originalServingText": null,
          "referenceWeightG": 100,
          "referenceVolumeMl": null
        },
        "baseNutrients": {
          "calories_kcal": null,
          "protein_g": 2,
          "total_fat_g": null,
          "saturated_fat_g": null,
          "carbohydrates_g": null,
          "sugar_g": 6,
          "sodium_mg": null,
          "fiber_g": null
        },
        "nutrients": {
          "calories_kcal": null,
          "protein_g": 2,
          "total_fat_g": null,
          "saturated_fat_g": null,
          "carbohydrates_g": null,
          "sugar_g": 6,
          "sodium_mg": null,
          "fiber_g": null
        },
        "evidence": {
          "calories_kcal": null,
          "protein_g": null,
          "total_fat_g": null,
          "saturated_fat_g": null,
          "carbohydrates_g": null,
          "sugar_g": null,
          "sodium_mg": null,
          "fiber_g": null
        },
        "provenance": "model_estimate",
        "pros": [
          "Pertimbangkan sesuai kebutuhanmu."
        ],
        "cons": [
          "Periksa kembali data yang belum jelas."
        ],
        "warnings": [
          "Contoh sintetis, bukan nutrisi produk nyata."
        ]
      }
    },
    "comparisonBasis": {
      "requested": "per_serving",
      "status": "common_basis",
      "reason": "Kedua pilihan memakai acuan massa yang sama.",
      "references": {
        "a": {
          "quantity": 1,
          "displayLabel": "1 porsi (100 g)",
          "weightG": 100,
          "volumeMl": null
        },
        "b": {
          "quantity": 1,
          "displayLabel": "1 porsi (100 g)",
          "weightG": 100,
          "volumeMl": null
        }
      }
    },
    "comparedNutrients": {
      "a": {
        "calories_kcal": null,
        "protein_g": 4,
        "total_fat_g": null,
        "saturated_fat_g": null,
        "carbohydrates_g": null,
        "sugar_g": 12,
        "sodium_mg": null,
        "fiber_g": null
      },
      "b": {
        "calories_kcal": null,
        "protein_g": 2,
        "total_fat_g": null,
        "saturated_fat_g": null,
        "carbohydrates_g": null,
        "sugar_g": 6,
        "sodium_mg": null,
        "fiber_g": null
      }
    },
    "differences": {
      "calories_kcal": null,
      "protein_g": -2,
      "total_fat_g": null,
      "saturated_fat_g": null,
      "carbohydrates_g": null,
      "sugar_g": -6,
      "sodium_mg": null,
      "fiber_g": null
    },
    "prioritySignals": [
      {
        "priority": "Gula",
        "nutrient": "sugar_g",
        "direction": "lower",
        "preferredDirection": "lower"
      },
      {
        "priority": "Protein",
        "nutrient": "protein_g",
        "direction": "lower",
        "preferredDirection": "higher"
      }
    ],
    "summary": "Pilihan B punya gula lebih sedikit, tapi proteinnya juga lebih sedikit. Ini masih perkiraan yang perlu diperiksa.",
    "ttsSummary": "Pilihan B punya gula lebih sedikit, tapi proteinnya juga lebih sedikit. Ini masih perkiraan yang perlu diperiksa.",
    "ttsSummarySource": "model",
    "warnings": [
      "Contoh sintetis, bukan nutrisi produk nyata."
    ],
    "model": "configured-provider-model",
    "promptVersion": "compare-2026-11-v1"
  },
  "timestamp": "2026-11-08T00:00:00.000Z"
}
```
