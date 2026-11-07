# Services

Letakkan logika bisnis dan orkestrasi akses data backend di folder ini. Service tidak membaca atau menulis `Request`/`Response` Express; controller memvalidasi request, memanggil service, lalu membentuk response API.

Gunakan Prisma Client dari `../config/prisma` saat suatu fitur membutuhkan database. Buat file service ketika kontrak dan logika fitur sudah ada; jangan menambahkan service contoh atau placeholder.
