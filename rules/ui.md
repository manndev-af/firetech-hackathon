# Aturan Mutu UI NutriSee

Aturan ini berlaku untuk desain, implementasi, dan review antarmuka Flutter NutriSee. Gunakan [DESIGN.md](../docs/DESIGN.md) untuk pola dan arahan visual, [FRD.md](../docs/FRD.md) untuk perilaku/kriteria penerimaan, dan [DECISIONS.md](../docs/DECISIONS.md) untuk status keputusan. Ikuti pula [AGENTS.md](../AGENTS.md) dan [aturan dokumentasi](documentation.md).

## Prinsip produk pada UI

- Mulai dari tugas pengguna: mengenali makanan, memeriksa hasil, menentukan porsi, dan memahami trade-off nutrisi.
- Jadikan Scan tindakan utama dalam rancangan Home; jangan menambah dashboard atau statistik tanpa data dan kebutuhan yang jelas.
- Tampilkan kelebihan serta kekurangan sesuai prioritas pengguna. Hindari skor universal atau cap mutlak “sehat/tidak sehat”.
- Nutrition Profile mengubah fokus penjelasan/perbandingan, bukan nilai nutrisi sumber.
- Jangan menyajikan aplikasi sebagai layanan dokter atau menampilkan diagnosis, pengobatan, atau perubahan obat.

## Pengenalan dan konfirmasi

- Tampilkan kandidat top-k dan confidence model sebagai estimasi klasifikasi, bukan jaminan kebenaran.
- Sediakan tindakan koreksi, pencarian manual, dan foto ulang sesuai flow.
- Jangan menyebut foto sebagai sumber nilai kalori, berat, porsi, atau komposisi nutrisi.
- Pengguna harus dapat mengonfirmasi kelas makanan dan porsi sebelum analisis.
- Confidence dan kepastian nutrition database adalah dua hal berbeda; jangan satukan menjadi satu status.

## Porsi dan informasi nutrisi

- Pilih kontrol dan label unit sesuai konfigurasi terstruktur untuk makanan (misalnya buah, butir, potong, gram/porsi, atau volume).
- Tampilkan nilai default dan unit dengan jelas; sediakan increment/decrement atau slider bila sesuai. Jangan meminta ketikan untuk perubahan sederhana bila kontrol langsung tersedia.
- Jangan mengarang default, konversi, atau berat per unit. Bila mapping tidak ada, jelaskan bahwa hasil belum dapat dihitung.
- Tampilkan sumber data, basis nilai (per porsi/per 100 g/ml), porsi pengguna, serta nutrisi yang tidak tersedia.
- Nilai yang hilang tidak boleh digambarkan sebagai nol. Jangan membulatkan hingga menimbulkan kesan presisi palsu.
- Bandingkan pilihan pada basis setara atau tunjukkan perbedaan basisnya secara jelas.

## Bahasa, hirarki, dan state

- Gunakan bahasa Indonesia yang ringkas, ramah, dan tidak menghakimi.
- Satu tindakan utama per konteks; label tombol harus cocok dengan hasil aksinya.
- Jangan mengandalkan warna saja untuk status. Gunakan teks dan label yang jelas.
- Rancang loading, kosong/tidak ditemukan, confidence rendah, error, offline, dan retry sesuai kondisi alur.
- Kegagalan LLM/TTS tidak boleh menyembunyikan kalkulasi deterministik yang tersedia.
- Jangan tampilkan nilai nutrisi, confidence, atau contoh makanan ilustratif seolah berasal dari model/data aktual.

## Aksesibilitas dan pemeriksaan UI

- Beri nama aksesibel pada tombol ikon, input, slider, dan stepper; pastikan urutan fokus dan pembesaran teks tetap dapat digunakan.
- Pastikan kontras teks/status dan ukuran kontrol dapat digunakan; status memiliki label selain warna.
- Periksa layar sempit, teks panjang, state kosong/error, interaksi satu tangan untuk porsi, serta screen reader yang tersedia.
- Evaluasi hanya layar/state yang benar-benar diperiksa. Screenshot tidak membuktikan seluruh alur, aksesibilitas, atau integrasi berjalan.
- Jangan menetapkan palet, ukuran, atau library ikon baru tanpa sinkronisasi [DESIGN.md](../docs/DESIGN.md) dan persetujuan bila mengubah arah visual.

## Sinkronisasi dokumen

Jika perubahan UI mengubah perilaku pengguna atau kriteria penerimaan, perbarui FRD. Jika mengubah arah visual, alur layar, atau komponen utama, perbarui DESIGN. Jika perubahan memengaruhi scope atau keputusan produk, periksa PRD dan DECISIONS. Terapkan [aturan dokumentasi](documentation.md) dan catat perubahan material di CHANGELOG.