# PROMPT: Backend Node.js API (Reservasi PAA)

## 1. Role & Objective
Kamu adalah seorang Senior Backend Developer (Node.js). Bantu aku membuat **backend REST API** untuk aplikasi mobile **Reservasi PAA (Peralatan Angkat & Angkut)** sesuai **Blueprint Database & API** yang kulampirkan (`00_blueprint_database_api.md`). Blueprint itu adalah sumber kebenaran: jangan mengubah nama tabel, kolom, endpoint, kode status, atau format response tanpa memberi tahu aku sebagai usulan.

## 2. Tech Stack & Environment
- **Node.js LTS** + **Express**, JavaScript (ES Modules).
- **PostgreSQL** + **Prisma ORM**.
- Auth: **JWT** (`jsonwebtoken`) + **bcryptjs**.
- Validasi: **zod**. Upload file: **multer**.
- Klien: Flutter (emulator Android memakai `http://10.0.2.2:3000/api`).

## 3. Aturan Utama
- **Lean & Modular:** tanpa over-engineering. Controller tipis, validasi dengan zod di middleware, hindari lapisan abstraksi yang tidak perlu. Logika yang dipakai berulang (cek slot, buat notifikasi) boleh di satu file service kecil.
- **Struktur Feature-Based** (selaras dengan Flutter):
```
src/
├── app.js, server.js
├── config/        (env)
├── lib/           (prisma client, response helper, date helper Asia/Jakarta)
├── middleware/    (auth, admin, validate, upload, errorHandler)
└── modules/
    ├── auth/  profile/  batches/  vehicles/  reservations/  notifications/
    └── admin/ (dashboard, reservations, vehicles, users, batches, reports)
        # tiap modul: routes.js, controller.js, schema.js (zod), service.js bila perlu
prisma/ (schema.prisma, seed.js, migrations/)
```
- Semua response memakai format `{success, message, data}` / `{success:false, message, errors}`; buat helper kecil dan error handler terpusat (validasi zod -> 422, Prisma `P2002` pada reservasi -> 409, dst.).
- Seluruh aturan bisnis di Bagian 3 blueprint harus terimplementasi: partial unique index + transaksi untuk double booking, transisi status, notifikasi otomatis, akun nonaktif ditolak di middleware auth (cek DB tiap request), admin tidak bisa mengubah dirinya sendiri.
- Pesan error dan validasi dalam bahasa Indonesia.
- Field di JSON response `snake_case` (petakan dari Prisma camelCase bila perlu, lewat `@map` atau fungsi serializer sederhana).

## 4. Tugas yang Harus Dikerjakan (kerjakan berurutan)
1. **Setup:** inisialisasi project, daftar dependency, script `package.json` (`dev`, `start`, `seed`), `.env.example`, bind server ke `0.0.0.0`, `express.static` untuk `/uploads`.
2. **Prisma schema** semua tabel dan enum sesuai blueprint (gunakan `@@map`/`@map` agar nama tabel dan kolom `snake_case`), plus **migration SQL manual** untuk partial unique index reservasi.
3. **Seed:** 4 batch awal, work units, akun admin `admin@paa.local`, satu akun user, beberapa kendaraan contoh (Forklift 10 Ton, 2 Ton, 7 Ton, Lift Truck, Trailer 22 Ton, Trailer 32 Ton).
4. **Middleware:** auth (verifikasi JWT + cek `is_active`), admin, validate (zod), upload (multer: jpg/png/webp, maks 3 MB), error handler.
5. **Modul dan routes** lengkap sesuai blueprint. Urutan pengerjaan yang disarankan:
   - Auth + Profil
   - Batch, Work unit, Vehicle availability
   - Reservasi pengguna + Notifikasi
   - Admin: reservasi (approve/reject/complete), kendaraan (upload foto, soft delete), pengguna, batch
   - Admin: dashboard dan laporan (laporan boleh versi sederhana sesuai usulan blueprint)
6. **Pengujian cepat:** contoh 1-2 tes (misal double booking ditolak, transisi status tidak valid) dengan Vitest/Jest + Supertest, serta kumpulan contoh request `curl` atau file `.http` untuk mencoba endpoint utama.

## 5. Format Jawaban
- Penjelasan dalam bahasa Indonesia; kode dan nama variabel dalam bahasa Inggris.
- Tiap file di code block terpisah dengan path di atasnya.
- Kalau jawaban terlalu panjang, berhenti di akhir salah satu langkah dan tulis "Lanjut ke langkah N" agar aku bisa meminta kelanjutannya.

---

## LAMPIRAN: Blueprint Database & API
Tempel isi file `00_blueprint_database_api.md` di sini (atau lampirkan sebagai file terpisah).
