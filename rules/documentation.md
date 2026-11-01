# Aturan Dokumentasi NutriLens AI

Aturan ini menjelaskan cara menjaga dokumentasi NutriLens tetap selaras dengan produk dan implementasi. Terapkan pada perubahan dokumentasi, produk, aplikasi, backend, model, data, maupun cara kerja agent.

## Sumber rujukan

Gunakan setiap dokumen untuk cakupannya:

| Sumber | Menjadi rujukan untuk |
|---|---|
| [AGENTS.md](../AGENTS.md) | Aturan kerja agent, batas MVP, keamanan, dan keselamatan produk. |
| [docs/SUMMARY.md](../docs/SUMMARY.md) | Konteks brainstorming, keputusan sementara, rekomendasi, serta addendum pembaruan konsep. |
| [docs/PRD.md](../docs/PRD.md) | Tujuan produk, pengguna, ruang lingkup, dan ukuran keberhasilan. |
| [docs/FRD.md](../docs/FRD.md) | Kebutuhan fungsional dan kriteria penerimaan. |
| [docs/DESIGN.md](../docs/DESIGN.md) | Arahan dan keputusan desain UI/UX. |
| [docs/DECISIONS.md](../docs/DECISIONS.md) | Register keputusan, status, konflik, serta hal yang belum final. |
| [docs/architecture.md](../docs/architecture.md) | Pembagian tanggung jawab komponen dan alur data. |
| [docs/WORKSPACE.md](../docs/WORKSPACE.md) | Struktur repository dan alur kerja workspace. |
| [rules/ui.md](ui.md) | Aturan UI untuk implementasi dan review layar Flutter. |
| [app/README.md](../app/README.md) | Setup dan penggunaan proyek Flutter. |
| [server/README.md](../server/README.md) | Setup dan penggunaan backend Node.js. |
| [CHANGELOG.md](../CHANGELOG.md) | Catatan perubahan penting yang sudah dibuat. |
| Kode dan konfigurasi aktual | Bukti keadaan implementasi saat ini; rencana di dokumen bukan bukti fitur sudah ada. |

Jika sumber bertentangan, ikuti instruksi terbaru yang diberikan pengguna dan batas keselamatan di AGENTS. Pertahankan konteks historis yang berguna, tandai konflik, dan jangan mengubah rekomendasi lama menjadi keputusan final secara diam-diam.

## Prinsip pemeliharaan dokumen

1. Perbarui sumber yang terdampak dalam pekerjaan yang sama; jangan mengubah semua dokumen tanpa alasan.
2. Pertahankan perbedaan antara **sudah disepakati**, **rekomendasi**, **belum final**, dan **sudah diimplementasikan**. Gunakan kata yang eksplisit, misalnya “direncanakan” untuk fitur yang belum ada.
3. Tambahkan hasil brainstorming baru sebagai addendum bertanggal atau pembaruan yang jelas. Jangan menghapus keputusan lama hanya agar riwayat tampak selalu konsisten.
4. Gunakan satu sumber utama untuk setiap aturan. Dokumen lain merujuk sumber itu alih-alih menyalin spesifikasi panjang yang mudah berbeda.
5. Buat dokumen baru hanya bila kebutuhan proyek memerlukannya. Jangan menambah dokumen spekulatif atau menduplikasi spesifikasi yang sudah dipelihara di PRD, FRD, dan architecture.
6. Gunakan tautan relatif dan kapitalisasi nama file yang persis sesuai repository. Pastikan target tautan lokal memang tersedia.
7. Jangan mengklaim bahwa fitur, model, data, API, pengujian, atau validasi telah tersedia jika belum dibuktikan oleh kode atau hasil pemeriksaan.

## Matriks perubahan dan dokumen yang perlu diperiksa

| Perubahan | Dokumen yang diperiksa atau diperbarui |
|---|---|
| Tujuan, target pengguna, prioritas, atau scope produk | SUMMARY dan PRD; FRD bila perilaku fungsional ikut berubah. |
| Flow atau perilaku pengguna, termasuk onboarding/porsi/insight | FRD; PRD bila scope atau sasaran berubah; architecture bila alur komponen berubah. |
| Layout, hierarki, navigasi, konten, aksesibilitas, atau state UI | DESIGN dan aturan UI; FRD bila perilaku/kriteria penerimaan berubah; DECISIONS jika arah yang disepakati berubah. |
| Struktur proyek atau cara menjalankan app/backend | WORKSPACE dan README subproyek terkait; AGENTS bila aturan agent atau struktur yang ditetapkan berubah. |
| Endpoint, request/response, atau validasi API | FRD dan architecture; README server bila setup/perintah berubah. Dokumentasikan kontrak API sebelum implementasi bila belum ada sumber kontrak. |
| Nutrisi, sumber data, unit, atau aturan kalkulasi | SUMMARY/FRD/architecture sesuai dampak; cantumkan sumber dan basis yang dapat diverifikasi. Jangan mengubah null menjadi nol. |
| Model, dataset, preprocessing, split, atau metrik | SUMMARY dan architecture; dokumentasikan hasil aktual dan keterbatasan. Jangan mengarang kelas, skema dataset, atau angka evaluasi. |
| LLM, privasi, keamanan, atau Nutrition Profile | AGENTS dan dokumen produk yang terdampak; jelaskan batas pemrosesan data dan jangan membuat kemampuan klinis. |
| Aturan agent, skill/rules, atau changelog | AGENTS, rule terkait, dan README bila navigasinya perlu diperbarui. |
| Perubahan format atau ignore file | WORKSPACE dan konfigurasi relevan; perbarui changelog jika berdampak material. |

## Aturan khusus NutriLens AI

- Nutrition Profile dapat menyoroti penjelasan, perbandingan, dan alternatif; profil tidak mengubah nilai nutrisi sumber.
- Nilai nutrisi harus berasal dari sumber yang dapat diverifikasi dan mempertahankan sumber, basis, serta satuannya. Nilai yang tidak tersedia tetap tidak diketahui, bukan nol.
- Perhitungan nutrisi dan aturan trade-off bersifat deterministik. LLM hanya menjelaskan hasil terstruktur; bukan kalkulator, sumber nutrisi, atau otoritas medis.
- MobileNetV3-Large yang direncanakan hanya mengklasifikasikan makanan dan mengembalikan top-k/confidence. Jangan mengklaim model mengukur porsi, berat, kalori, atau nutrisi secara langsung.
- Pengguna mengonfirmasi jenis makanan dan porsi. Satuan serta konversi harus berasal dari konfigurasi terstruktur yang ditinjau.
- Hindari diagnosis, konsultasi dokter, rekomendasi pengobatan, dan perubahan dosis obat. Field profil opsional dan alergi harus dijelaskan sesuai status konsep serta keterbatasan data.

## Changelog

Untuk perubahan material pada fitur, perilaku, API, data/model, setup/dependency, keamanan/privasi, atau dokumentasi utama:

- Tambahkan ringkasan singkat pada bagian `## [Unreleased]` dalam [CHANGELOG.md](../CHANGELOG.md) pada pekerjaan yang sama.
- Gunakan kategori `Added`, `Changed`, `Fixed`, `Removed`, atau `Security` yang sesuai.
- Catat dampak nyata; tandai fitur yang baru berupa rencana sebagai rencana.
- Lewati perubahan typo/format kecil dan perubahan internal yang tidak terlihat pengguna.
- Jangan membuat versi atau tanggal rilis tanpa keputusan rilis tim.

## Penutupan pekerjaan dokumentasi

Sebelum menyelesaikan task, periksa tautan dan nama path yang disentuh, konsistensi requirement dengan sumber rujukan, dan apakah ada dokumentasi lain yang terdampak. Dalam laporan akhir, sebutkan dokumen yang diperbarui, dokumen penting yang tidak terdampak beserta alasan singkat, serta verifikasi yang benar-benar dijalankan. Untuk task dokumentasi saja, jangan menyatakan bahwa aplikasi atau pengujian runtime telah tervalidasi.
