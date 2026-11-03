    
# Changelog

Semua perubahan penting pada NutriLens AI dicatat di dokumen ini. Format mengikuti prinsip [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versi menggunakan [Semantic Versioning](https://semver.org/spec/v2.0.0.html) setelah proyek mulai membuat rilis; sebelum itu, perubahan dicatat pada bagian **Unreleased**.

## [Unreleased]

### Added

- Dokumentasi produk terintegrasi: ringkasan brainstorming, PRD, FRD, dan arsitektur.
- Konsep Nutrition Profile terbaru: prioritas nutrisi, preferensi makanan, serta field usia, tinggi/berat badan, dan alergi dengan status opsional sesuai dokumen.
- Aturan konteks proyek dan alur pemeliharaan changelog untuk AI agent.
- Mekanisme CHANGELOG untuk melacak perubahan penting dalam bagian Unreleased sebelum rilis.

### Changed

- Seluruh 14 artboard FigCraft diselaraskan ke palet teal/mint dengan frame lebih membulat dan kartu berbayang lembut; lima layar navigasi utama menggunakan instance bottom navigation lima tab.
- Prototipe FigCraft menerima master component Card Base, Data Ring, dan navigasi lima tab; DESIGN.md mencatat arah redesign teal/cyan dan susunan konten layar tanpa menghapus 14 layar yang sudah ada.
- DESIGN.md diperbarui agar mencerminkan token visual dan pola tata letak pada prototipe FigCraft, serta mencantumkan 14 layar dan alur navigasinya. Login/Daftar ditandai sebagai eksplorasi UI, bukan komitmen autentikasi MVP.
- Dokumentasi menegaskan batas personalisasi: profil memengaruhi fokus insight/perbandingan, bukan nilai nutrisi sumber; kalkulasi dilakukan deterministik dan LLM hanya menjelaskan hasil.
- Struktur repository pada panduan agent dan summary diselaraskan dengan proyek Flutter di `app/` dan backend di `server/`, termasuk README lokal masing-masing.
- Panduan workspace lama yang merujuk proyek lain diganti dengan layout NutriLens AI, rujukan dokumen, dan alur kolaborasi `main`/`development`.
- Aturan sinkronisasi dokumentasi disesuaikan dengan dokumen aktif, komponen, serta batas produk NutriLens AI.
- Dokumen desain UI, register keputusan, dan aturan mutu UI yang sebelumnya berisi konteks proyek lain diselaraskan dengan NutriLens AI.

### Fixed

### Removed

### Security

- Aturan ignore root mencakup file konfigurasi rahasia lokal, dataset unduhan, cache, dan bobot model; file `.env.example` tetap dapat dibagikan.

