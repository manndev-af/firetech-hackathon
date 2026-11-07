# Assistant API - handoff Flutter

POST `{API_PREFIX}/v1/assistant/messages`, prefix default `/api`. Backend-only; frontend belum terhubung. Mode compare, gambar/OCR, streaming, TTS dan histori permanen tidak termasuk kontrak.

## Request

Gunakan `application/json`, maksimal 64 KiB UTF-8 termasuk transfer tanpa Content-Length, tanpa kompresi.

```json
{"mode":"pattern","message":"Bagaimana pola gula di catatanku?","history":[]}
```

`mode` wajib general/pattern; `message` wajib nonblank maksimal 2000 Unicode code points. `history` opsional default [], maksimal sepuluh pesan berupa pasangan selesai user/assistant bergantian, dimulai user dan berakhir assistant. Setiap item tepat `{role,text}`, text nonblank maksimal 2000 karakter. Total teks message+history maksimal 12000 karakter. Pesan saat ini tidak diduplikasi dalam history. Field asing, userId/owner, system/tool role, compareSnapshot dan nutrisi klien ditolak. Server memakai dummy user terkonfigurasi.

HTTP: 200 sukses; 400 input/JSON/owner; 404 demo disabled; 413 body terlalu besar; 415 Content-Type/encoding/kompresi; 422 PATTERN_LIMIT_EXCEEDED; 429 SCAN_BUSY kapasitas bersama; 502 provider/output/citation; 503 konfigurasi/profil/database/context budget; 504 timeout 45 detik. Error memakai `{success:false,message,data:{code},timestamp}`. Tidak ada retry atau replay otomatis; submission baru dapat menimbulkan panggilan berbayar baru.

## Privasi dan sesi

Riwayat chat hidup di state Flutter; backend tidak menyimpan atau cache pesan, file maupun conversationId. DeepSeek tidak otomatis mengingat chat sebelumnya. Pertanyaan/history serta profil allowlist, referensi dan agregasi catatan yang diperlukan dikirim ke provider eksternal; jangan masukkan informasi pribadi yang tidak diperlukan. Nama/email/password/usia/tinggi/berat tidak ditambahkan oleh backend. History klien tetap data tidak tepercaya, bukan evidence konsumsi.

Body request/response dan query assistant dihilangkan dari log development termasuk error parsing; metadata operasional status/durasi tetap ada. Tidak ada retensi chat aplikasi; kebijakan retensi provider eksternal terpisah. Tidak menulis profil, FoodEntry, ScanRequest atau hasil compare. Perubahan frontend dan penghapusan navigasi compare dilakukan tim Flutter terpisah.

## Mode dan konteks pola

General mengirim hanya profil preferensi, pertanyaan/history dan maksimal tiga referensi reviewed. Jurnal tidak disertakan. Pattern menambahkan seluruh catatan pada tujuh tanggal kalender lokal (hari ini dan enam sebelumnya), dari tengah malam awal window sampai snapshotAt, bukan tujuh kali 24 jam. Hari ini belum penuh. Future entries dikeluarkan; lebih dari 1000 entri menghasilkan 422 tanpa dispatch, bukan sampel yang mengaku lengkap.

`contextSummary.patternEvidence` berisi dateFrom/dateTo inklusif, windowEndExclusive ISO, entryCount, daysWithEntries, recordedIntakeOnly=true, periodSummary, tujuh dailySummaries dan maksimal lima frequentFoods. Masing-masing summary berisi entryCount, recordedIntakeOnly dan delapan nutrients dengan knownTotal, knownCount, missingCount, complete dan provenanceCounts. Unknown tetap null, angka nol tetap nol; complete menunjukkan field terisi pada seluruh entri tercatat, bukan diet lengkap atau data terverifikasi.

Key/unit sama dengan scanner: calories_kcal (kcal), sodium_mg (mg), protein_g/total_fat_g/saturated_fat_g/carbohydrates_g/sugar_g/fiber_g (g). Porsi disesuaikan quantity/baseQuantity dengan Decimal, round enam desimal. Hari kosong punya total null, bukan nol. frequentFoods mengelompokkan title trim/lowercase persis, frekuensi adalah jumlah catatan, bukan jumlah porsi; urutan count turun lalu title naik. Lima contoh history retrieval tidak dipakai sebagai total window.

Fixture tes sintetis: satu catatan gula 12 g dengan quantity 0.5, satu catatan gula null, dan satu catatan gula 0 g memberi knownTotal=6, knownCount=2, missingCount=1 dan complete=false. Ini bukan data produk nyata.

## Respons

HTTP 200 memakai envelope `{success,message,data,timestamp}`. `data` berisi reply (plain text nonblank <=4000 karakter), sources, warnings, contextSummary, model dan promptVersion. Sumber dipilih dari citationIds valid lalu URL/title/version/reviewedAt dibentuk server; tidak berasal dari URL buatan model. `contextSummary` berisi mode, snapshotAt, timezone, historyMessageCount, referencesAvailable dan patternEvidence (null untuk general).

Prompt/model sama provider terkonfigurasi tetapi prompt assistant terpisah dari scanner/compare. Satu dispatch teks maksimal, 2048 max tokens, output maksimum 64 KiB, timeout 45 detik. Dua slot dibagi scanner/compare/assistant. Input/deskripsi/history/referensi adalah data tidak tepercaya. Validasi schema dan ID sumber tidak membuktikan seluruh makna prosa model; angka evidence tetap acuan. Tidak membuat jawaban palsu saat provider gagal.

Contoh general tanpa referensi:

```json
{"success":true,"message":"Jawaban assistant tersedia.","data":{"reply":"Cek porsi dan kandungan gizi sesuai prioritasmu. Referensi khusus untuk pertanyaan ini belum tersedia.","sources":[],"warnings":["Referensi reviewed yang relevan belum tersedia; informasi umum tidak menggantikan data terverifikasi."],"contextSummary":{"mode":"general","snapshotAt":"2026-11-08T05:00:00.000Z","timezone":"Asia/Jakarta","historyMessageCount":0,"referencesAvailable":false,"patternEvidence":null},"model":"configured-provider-model","promptVersion":"assistant-2026-11-v1"},"timestamp":"2026-11-08T05:00:00.000Z"}
```

Contoh pattern cold start: `reply` menjelaskan belum ada catatan; `entryCount=0`, `daysWithEntries=0`, dateFrom=2026-11-02, dateTo=2026-11-08, windowEndExclusive=2026-11-08T05:00:00.000Z. Ketujuh dailySummaries memiliki entryCount=0 dan semua knownTotal=null, knownCount/missingCount=0, complete=false serta provenanceCounts={}. frequentFoods=[]. Contoh JSON lengkap general/pattern tersedia pada response examples OpenAPI, dibentuk dari fixture sintetis yang sama dan diperiksa tes schema.

Contoh error batas pola:

```json
{"success":false,"message":"Catatan tujuh hari melebihi 1000 entri.","data":{"code":"PATTERN_LIMIT_EXCEEDED"},"timestamp":"2026-11-08T05:00:00.000Z"}
```

## Contoh pemanggilan dan integrasi Flutter

Dari PowerShell, gunakan file JSON request agar quoting stabil. `question.json` berisi request contoh di atas; file tidak perlu masuk Git:

```powershell
curl.exe -X POST http://localhost:3000/api/v1/assistant/messages `
  -H "Content-Type: application/json" `
  --data-binary "@question.json"
```

Port mengikuti PORT lokal. Swagger di `{API_PREFIX}/docs/`; JSON OpenAPI di `{API_PREFIX}/openapi.json`. Tidak ada endpoint membuat conversation, GET chat lama atau Idempotency-Key wajib.

Contoh follow-up:

```json
{"mode":"general","message":"Kalau porsinya lebih kecil, apa yang perlu diperhatikan?","history":[{"role":"user","text":"Apa yang perlu dilihat saat memilih camilan?"},{"role":"assistant","text":"Cek porsi dan kandungan gizi sesuai prioritasmu."}]}
```

| Kebutuhan UI | Field/perilaku |
|---|---|
| Bubble jawaban | `data.reply`; simpan bersama pesan user setelah request sukses |
| Sumber pendukung | `data.sources`; URL dari server, tanpa parsing reply |
| Keterbatasan | `data.warnings` |
| Periode dan kelengkapan pola | `data.contextSummary.patternEvidence` |
| General greeting | Teks lokal, belum perlu request sebelum user bertanya |
| Lihat pola catatanku | Mode pattern dan pertanyaan awal eksplisit; ganti chat contoh |
| Loading | Satu respons nonstream; cegah submit berulang selama request aktif |
| Error/timeout | Tampilkan error; pertahankan draft dan pasangan terakhir selesai, tanpa fake jawaban |
| Follow-up | Maksimal lima pasangan terakhir, total <=12000 code points termasuk pesan baru |
| Retry | Aksi eksplisit user; request baru dapat memicu biaya baru |

History tidak dipotong otomatis server; frontend memilih pasangan yang muat. Jangan kirim pesan saat ini dua kali. Untuk mode baru, mulai history baru agar konteks jelas. Setelah restart tidak ada riwayat server. General tidak membaca pola secara implisit; gunakan pattern untuk konsumsi tercatat. Pattern memakai tujuh tanggal tetap, tanpa rentang custom.

Flutter belum diubah/terhubung dalam change ini. Mode compare tidak diterima API assistant; penghapusan tombol compare dilakukan tim Flutter terpisah. Tidak ada TTS assistant atau audio baru.

## Verifikasi aktual - 8 November 2026

35 tes backend: 34 lulus, satu integration database dilewati tanpa TEST_DATABASE_URL terisolasi; build lulus. HTTP sukses/error, read-only Prisma, kapasitas bersama, disconnect, batas input, agregasi, sumber dan privasi diperiksa memakai provider mock. Service live dengan konteks sintetis tanpa database: general 6030 ms dan pattern 2286 ms, satu dispatch teks masing-masing, reply/citation tervalidasi. Pattern menjelaskan total fixture gula 6 g dan keterbatasan data; bukan pengukuran makanan nyata atau bukti akurasi umum. HTTP end-to-end dengan database nyata dan provider live bersama belum diuji.
