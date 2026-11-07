# Audit Profil dan Riwayat — 7 November 2026

## Revisi setelah review pengguna

Revisi Profil terbaru menggantikan bottom sheet: Edit profil membuka informasi diri (nama/usia/tinggi/berat); Lihat detail personalisasi membuka seluruh input prioritas/pilihan makanan/alergi secara inline. Simpan/Kembali ada di akhir form. Simpan informasi diri tidak mewajibkan prioritas dan tidak mengubah preferensi; simpan personalisasi mempertahankan identitas. Setelah ditutup, scroll kembali ke ringkasan. Preview tambahan: `profile-inline.png` dan `profile-identity.png`. Riwayat dipertahankan.

Pembaruan akses contoh: pengguna meminta contoh langsung terlihat pada Riwayat. Router kini membuka tiga catatan fixture secara default tanpa flag tambahan. `flutter run` cukup untuk review; `--dart-define=UI_PREVIEW=false` menonaktifkannya. Pemisahan fixture dari penyimpanan/data asli tetap berlaku. Instruksi aktivasi manual pada catatan sebelumnya digantikan oleh pembaruan ini.

Bagian ini menggantikan perilaku filter, banner ilustrasi, serta profil panjang yang dicatat dalam audit awal di bawah.

- Profil utama menampilkan identitas, maksimal tiga prioritas, dan satu preferensi. Lihat detail membuka informasi lengkap dalam bottom sheet; tombol edit tersedia pada identitas dan detail.
- Audio analisis memiliki sakelar aktif/nonaktif. Pilihan disimpan dalam `analysisAudioSession` sehingga bertahan saat berpindah tab selama sesi. Ini adalah preferensi UI; pemutaran Android TTS dan pembacaan hasil belum terintegrasi.
- Riwayat tidak menggunakan filter. Daftar dikelompokkan menurut hari, dengan foto, nama, waktu/porsi, ringkasan pendek, dan aksi Lihat analisis. Detail menampilkan foto lebih besar serta angka per porsi.
- Sumber dan basis diganti dengan penjelasan Asal data dan Acuan perhitungan di bagian Tentang data nutrisi yang dapat dibuka. Sumber fixture tidak diisi agar tidak mengaku berasal dari database nyata.
- Label demo/ilustrasi serta tombol preview dihilangkan dari layar sesuai permintaan pengguna. Fixture tetap terpisah melalui build flag `UI_PREVIEW`, tidak tersimpan dalam riwayat atau digunakan untuk rekomendasi. Angka/foto dalam build tersebut hanya bahan review desain; tidak membuktikan capture kamera atau analisis nyata.
- `ScanHistoryEntry.photoPath` mendukung foto file lokal dari integrasi kamera berikutnya; `photoAsset` digunakan fixture. File hilang atau gagal dibaca menampilkan fallback gambar, bukan foto makanan lain.
- Inter dipertahankan. Ukuran konsisten menurut peran: judul halaman/detail 24, bagian 18, judul item 16, isi/keterangan 14. Pembesaran teks tetap didukung, bukan dikunci pada ukuran fisik tertentu.
- Pengujian tambahan memeriksa detail progresif, sakelar audio lintas tab, kesamaan font/ukuran antarlayar, penghapusan filter/banner, serta pemisahan fixture. Modal memakai root navigator supaya tombol tidak tertutup navigasi bawah; tautan analisis membungkus saat teks besar.

Jalankan tampilan berisi melalui `flutter run --dart-define=UI_PREVIEW=true` dari `app/`. Build biasa tetap menampilkan riwayat kosong sampai integrasi menyediakan catatan nyata. Ekspor PNG memakai perintah yang sama seperti bagian preview di bawah, tanpa banner. Perintah lama Riwayat → Lihat contoh riwayat tidak berlaku lagi.

### Foto untuk review desain

Verifikasi revisi: `flutter analyze --no-pub` bersih; seluruh 24 tes lulus, termasuk pemuatan file foto lokal, fallback file hilang, font/ukuran setara, dan sakelar audio lintas tab. Enam PNG diekspor dan tampilan utama Profil/Riwayat diperiksa ulang. Pemeriksaan ini belum mencakup TTS atau kamera perangkat fisik.

Foto disimpan lokal agar preview bisa dibuka tanpa jaringan. Foto bukan hasil kamera pengguna atau bukti nilai nutrisi. Ketiga halaman sumber menyatakan lisensi Unsplash:

- `history_yogurt.jpg`: [Joanna Stołowicz](https://unsplash.com/photos/a-bowl-of-yogurt-with-strawberries-on-top-Qze7zeiMz0A).
- `history_rice.jpg`: [khloe arledge](https://unsplash.com/photos/person-holding-rice-bowl--Uca3SGlOag).
- `history_tea.jpg`: [Katrin Hauf](https://unsplash.com/photos/two-cup-of-tea-TaJkaQ_yBW0).

## Catatan audit awal

## Cakupan dan bukti

Audit dan implementasi dibatasi pada Profil, editor personalisasi, dan Riwayat Flutter. Router hanya disesuaikan untuk menjaga field profil ketika onboarding diperbarui dan menghindari pesan simpan menutupi aksi editor. Tema global, dashboard, backend, dan file Figcraft tidak didesain ulang.

Rujukan produk: [SUMMARY](SUMMARY.md), [PRD](PRD.md), [FRD](FRD.md), [DESIGN](DESIGN.md), serta brainstorming dan palet eksternal yang diberikan pengguna. Artboard `07 Nutrition Profile`, `09 History`, dan `10 Profile & Settings` menjadi acuan struktur. Dua referensi sushi/ice cream digunakan untuk hierarki judul, ruang kosong, bentuk kartu, dan aksi utama; warna tetap teal/mint aplikasi dan font tetap Inter.

Review menggunakan skill lokal pengguna: anti-ui-slop, better-interface-ui, design-critique-ai-reviewer, anti-ai-writing, brand, serta design-critique/accessibility-review/ux-copy dari paket Design. Tidak ada penelitian pengguna atau pengujian klinis dalam audit ini.

## Isi personalisasi

| Bagian | Isi dan alasan | Perilaku saat ini |
|---|---|---|
| Prioritas | Gula, natrium, protein, kalori, keseimbangan; boleh jamak | Minimal satu; ringkasan menjelaskan maksud setiap pilihan |
| Pilihan makanan | Preferensi keseharian, pola makan, preferensi halal | Opsional; halal bukan hasil sertifikasi produk |
| Alergi | Belum diisi, tidak diketahui ada alergi, atau daftar bahan; bahan lain dapat ditulis | Opsional; pencocokan bahan belum tersedia |
| Tentang pengguna | Nama dan usia | Opsional; nama maksimal 60 karakter, usia bilangan bulat 1–120 |
| Ukuran tubuh | Tinggi cm dan berat kg | Opsional; desimal titik/koma diterima; kosong tetap null |

Tinggi/berat hanya dicatat, tanpa BMI atau target kalori otomatis. Batas input positif hingga 300 cm/700 kg merupakan penjagaan format, bukan rentang klinis. Riwayat penyakit, obat, dan aktivitas fisik tidak ditambahkan. Semua data masih dalam memori sesi; belum dikirim ke engine maupun disimpan permanen. Persetujuan pengguna untuk melengkapi personalisasi tidak dianggap sebagai persetujuan membuat integrasi medis.

## Temuan dan perbaikan

| Prioritas | Temuan berdasarkan kode/render | Perbaikan dan bukti |
|---|---|---|
| Tinggi | Profil awal belum mencakup field opsional yang diminta pengguna | Editor lima bagian dan ringkasan aktual; tes simpan, kosongkan, serta pemeliharaan field setelah onboarding |
| Tinggi | Riwayat kosong belum memberi gambaran hasil yang tersimpan | Aksi Lihat contoh riwayat, daftar terkelompok tanggal, filter aktif, dan detail modal; fixture terpisah dan berlabel ilustrasi |
| Tinggi | Data alergi kosong dapat disalahartikan sebagai tidak ada alergi | Status eksplisit; daftar bahan diwajibkan jika memilih status berisi; batas pencocokan terlihat |
| Sedang | Pembatalan draft memerlukan kesempatan pemulihan | Kembali/Batal saat berubah membuka konfirmasi; pengguna dapat melanjutkan mengedit |
| Sedang | Form panjang menyulitkan menemukan error dan aksi simpan | Scroll ke bagian invalid; footer simpan pada layar cukup tinggi, kembali ke alur scroll saat keyboard/layar pendek |
| Sedang | Pengelompokan visual berulang mengurangi hierarki | Satu kartu identitas mint, daftar prioritas dengan deskripsi, kartu preferensi berkelompok, latar putih dan garis ringan |
| Sedang | Nilai tidak diketahui dapat terbaca sebagai nol | Formatter membedakan null dari nol; detail mempertahankan sumber, porsi, dan basis nilai |

Keyakinan tinggi untuk perilaku yang tercakup tes/kode. Dampak terhadap kemudahan pengguna merupakan penilaian heuristik, belum hasil studi usability.

## Verifikasi

- `flutter analyze --no-pub`: tidak ada issue.
- `flutter test --no-pub`: 21 tes lulus, termasuk 11 tes Profil/Riwayat; satu tes ekspor hanya aktif dengan flag tersendiri.
- Pengujian mencakup validasi, perubahan draft, navigasi tab, filter jenis/tanggal, detail preview, pemisahan fixture, null versus nol, keyboard, serta lebar 320 px dengan skala teks 2 dan keyboard tampil.
- Ekspor PNG dari widget Flutter pada 390 × 844, memakai font Inter dan Material Icons sebenarnya; ringkasan profil, editor, alergi, riwayat kosong/berisi, dan detail diperiksa secara visual.
- Perhitungan kontras sRGB pasangan utama: teks utama `#173638`/putih 12,95:1; teks sekunder `#5E7172`/putih 5,15:1; sekunder/mint `#E6F4F3` 4,56:1; putih/teal `#0D6E6B` 6,07:1. Ini bukan sertifikasi aksesibilitas seluruh aplikasi.

Belum diuji dengan TalkBack/perangkat fisik atau partisipan pengguna. Navigasi bawah lama masih memiliki label bahasa Inggris dan bentuk kamera yang berbeda dari kontrol baru; perubahan global tersebut di luar cakupan. Penyimpanan, penghapusan riwayat nyata, kamera, TTS, pencocokan alergen, dan integrasi personalisasi ke engine belum tersedia.

## Membuka dan menghasilkan preview

Di aplikasi: Riwayat → Lihat contoh riwayat. Data contoh tidak dimasukkan ke catatan pengguna. Angka dan sumber dalam fixture hanya ilustrasi UI, bukan referensi nutrisi yang dapat digunakan untuk keputusan makan.

Dari `app/`:

```bash
flutter test --no-pub test/profile_history_preview_test.dart --dart-define=EXPORT_UI_PREVIEWS=true
```

Hasil berada di `app/build/ui-audit/after/` (diabaikan Git). Nama Naya pada ekspor adalah fixture, bukan default profil aplikasi.

## Dasar review

- [W3C: Forms Tutorial](https://www.w3.org/WAI/tutorials/forms/): label, instruksi, dan pembatasan pertanyaan pada data yang diperlukan; field pelengkap dibuat opsional.
- [W3C: Validating Input](https://www.w3.org/WAI/tutorials/forms/validation/): error yang dapat dipahami dan panduan memperbaiki input.
- [Nielsen Norman Group: Recognition and Recall](https://www.nngroup.com/articles/recognition-and-recall/): pilihan prioritas diberi uraian yang terlihat.

Dokumentasi terkait diperbarui di DESIGN, FRD, DECISIONS, architecture, README aplikasi, dan CHANGELOG. PRD/SUMMARY tetap menjadi konteks produk/historis; tidak ada perubahan tujuan produk atau API backend.
