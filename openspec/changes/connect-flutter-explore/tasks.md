# Tasks

## 1. Network & Services Scaffolding

- [x] 1.1 Daftarkan path endpoint `comparisons` (`$apiPrefix/comparisons`) dan `assistantMessages` (`$apiPrefix/assistant/messages`) pada `app/lib/core/network/api_endpoints.dart`.
- [x] 1.2 Implementasikan DTO respons dan service `CompareApi` pada `app/lib/services/compare_api.dart` untuk request multipart `POST /api/v1/comparisons` (`imageA`, `imageB`, string JSON `metadata`).
- [x] 1.3 Implementasikan DTO respons dan service `AssistantApi` pada `app/lib/services/assistant_api.dart` untuk request JSON `POST /api/v1/assistant/messages` (`mode`, `message`, `history`).

## 2. UI Integration

- [x] 2.1 Hubungkan `CompareScreen` (`app/lib/features/explore/compare_screen.dart`) ke `CompareApi`: kirim foto makanan A dan B saat pengguna menekan "Lihat ringkasan", tampilkan loading status inferensi, dan render hasil 8 nutrisi komparatif, selisih B-minus-A, sinyal prioritas, dan kesimpulan trade-off riil backend.
- [x] 2.2 Hubungkan `AssistantScreen` (`app/lib/features/explore/assistant_screen.dart`) ke `AssistantApi`: kirim pesan pengguna sesuai mode aktif (`general` atau `pattern`), sertakan riwayat sesi yang valid, tampilkan indikator loading, dan tangani error jaringan/kapasitas tanpa menghilangkan draft pengguna.

## 3. Testing & Verification

- [x] 3.1 Buat unit test pada `app/test/explore_services_test.dart` untuk memverifikasi pemanggilan `CompareApi` (multipart) dan `AssistantApi` (JSON) secara terisolasi dengan mock HTTP client.
- [x] 3.2 Perbarui pengujian widget `app/test/explore_test.dart` untuk memverifikasi integrasi roomchat asisten, fallback cerdas, dan interaksi UI.
- [x] 3.3 Jalankan seluruh suite pengujian Flutter (`flutter test`) dan pastikan seluruh pengujian lulus 100% tanpa regresi.
