# Proposal

Status: apply disetujui pengguna dan diimplementasikan pada 8 November 2026. Chat selama sesi tanpa persistensi adalah baseline MVP; hasil verifikasi aktual tercatat di tasks.md.

## Why

AssistantScreen masih menampilkan percakapan contoh dan jawaban lokal berbasis kata kunci, sehingga belum menjawab dari profil atau catatan konsumsi sebenarnya. Backend sudah memiliki DeepSeek, profil, jurnal dan retrieval; komponen ini dapat dipakai untuk percakapan nutrisi tanpa model AI baru.

## What Changes

- Tambahkan POST `{API_PREFIX}/v1/assistant/messages` dengan mode `general` dan `pattern`, pertanyaan serta riwayat chat terbatas; pemilik tetap dummy user server, tanpa login.
- Gunakan model DeepSeek terkonfigurasi dan transport JSON yang ada, dengan prompt assistant terpisah, input teks, satu dispatch maksimal per request dan tanpa retry/repair otomatis.
- Ambil profil allowlist dan referensi reviewed dari retrieval yang ada. Mode pattern menambahkan agregasi lengkap tujuh tanggal lokal terakhir sampai waktu request: jumlah catatan, total nutrisi diketahui, kelengkapan dan makanan sering tercatat. Backend menghitung dengan Decimal; LLM menjelaskan, bukan menghitung atau menyimpulkan diagnosis.
- Pertahankan null, provenance dan batas catatan konsumsi. Jawaban harus menyebut keterbatasan/cold start; tidak mengarang tren, nilai pangan spesifik atau batas klinis dari memori model.
- Kembalikan reply, sources, warnings dan metadata konteks terstruktur dalam envelope domain; sumber hanya hasil retrieval server. Prompt dan kontrak tidak menerima compare, gambar atau snapshot klien.
- Tidak menyimpan chat, tidak membuat tabel/model Prisma, migration, seed, cache atau session server. Flutter kelak menyimpan pesan selama sesi dan mengirim konteks terbatas; frontend tidak diubah dalam change ini.
- Hilangkan payload assistant dari log development, batasi request/konteks/output serta gunakan kapasitas provider bersama scanner/compare. Lengkapi OpenAPI, dokumentasi handoff dan tes regresi.

## Capabilities

### New Capabilities

- `personalized-nutrition-conversation`: percakapan general/pattern berbasis profil dan catatan, konteks sesi terbatas, agregasi deterministik, sumber dan batas bukti, tanpa persistensi chat atau konsumsi.

### Modified Capabilities

Tidak ada. Inventory `openspec/specs` masih kosong; change scanner/compare yang sudah ada tetap menjadi rujukan kompatibilitas. Integrasi compare ke assistant secara eksplisit dikeluarkan dari scope baru ini.

## Impact

- Baru: `server/src/validation/assistant.ts`, `services/assistant.service.ts`, `controllers/assistant.controller.ts`, `routes/assistant.routes.ts`, `routes/assistant.openapi.ts`, `server/test/assistant.test.cjs`, `server/ASSISTANT_API.md`.
- Diubah saat apply: app.ts untuk parser assistant, route registry, assembler OpenAPI, requestLogger, tes OpenAPI/logger, README backend, FRD, architecture, WORKSPACE, DECISIONS dan CHANGELOG. DECISIONS mencatat persetujuan/scope terbaru setelah apply diizinkan, termasuk arah compare yang sudah dibatalkan; kontrak API compare tidak berubah.
- Reuse tanpa perubahan kontrak: demoOwner, scanSlot, getProfile, retrieveContext, dayBounds/localDate/summarize/totals dan requestVision. Tidak perlu dependency, env, model AI, schema database atau infrastruktur baru.
- Tidak mengubah `app/**`, `server/prisma/**`, scanner/compare/jurnal, tidak menghapus tombol Flutter atau mengklaim frontend sudah terhubung. Riwayat chat permanen, upload foto, TTS assistant dan streaming di luar scope.
