# BLUEPRINT DATABASE & API: Reservasi PAA

Dokumen acuan tunggal untuk backend **Node.js (Express) + PostgreSQL** dan klien **Flutter**. Semua nama tabel, kolom, endpoint, dan format response di sini harus diikuti secara konsisten oleh semua fitur.

---

## 1. Konvensi Umum

- **Base URL:** `http://10.0.2.2:3000/api` (emulator Android). Perangkat fisik: pakai IP LAN laptop, misal `http://192.168.x.x:3000/api`.
- **Auth:** JWT (Bearer token). Header: `Authorization: Bearer <token>`. Token berlaku 7 hari.
- **Role:** `user` dan `admin`. Route `/admin/*` dilindungi middleware `admin`.
- **Nilai enum di DB memakai kode bahasa Inggris**; label Indonesia hanya ada di UI Flutter.
- **Tanggal:** `YYYY-MM-DD`. **Waktu:** `HH:mm`. Zona waktu bisnis `Asia/Jakarta` (hitung "hari ini" dengan zona ini, bukan UTC server).
- **Nama kolom di DB `snake_case`**, nama field JSON di response juga `snake_case`.

### Pemetaan kode ke label UI
| Kode DB | Label UI |
|---|---|
| `pending` | Menunggu Persetujuan |
| `approved` | Disetujui |
| `rejected` | Ditolak |
| `cancelled` | Dibatalkan |
| `completed` | Selesai |
| `available` | Tersedia |
| `maintenance` | Perawatan |
| `inactive` | Nonaktif |
| slot `empty` / `pending` / `booked` | Kosong / Menunggu / Dipesan |

### Format response
Sukses:
```json
{ "success": true, "message": "OK", "data": { } }
```
Sukses berpaginasi (`data` berupa array + `meta`):
```json
{ "success": true, "message": "OK", "data": [ ],
  "meta": { "current_page": 1, "last_page": 3, "per_page": 15, "total": 40 } }
```
Error validasi (HTTP 422):
```json
{ "success": false, "message": "Data tidak valid.",
  "errors": { "email": ["Email sudah terdaftar."] } }
```
Error lain: `401` (belum login/token salah), `403` (bukan admin / akun nonaktif / bukan pemilik), `404`, `409` (konflik slot), `500`. Semuanya memakai bentuk `{ "success": false, "message": "..." }`.

---

## 2. Skema Database (PostgreSQL)

Rekomendasi akses data: **Prisma ORM** (model memakai `@@map` / `@map` agar tabel dan kolom tetap `snake_case`). Semua `id` bertipe `serial` (integer auto-increment). Timestamp memakai `timestamptz`.

### `users`
| Kolom | Tipe | Catatan |
|---|---|---|
| id | serial PK | |
| name | varchar(100) | |
| email | varchar(150) | unique |
| password | varchar(255) | hash bcrypt |
| role | enum `user_role` ('user','admin') | default `user` |
| is_active | boolean | default `true` |
| created_at, updated_at | timestamptz | |

### `vehicles`
| Kolom | Tipe | Catatan |
|---|---|---|
| id | serial PK | |
| name | varchar(100) | contoh "Forklift 2 Ton - Unit 1" (1 record = 1 unit fisik) |
| type | varchar(100) | Jenis PAA, contoh "Forklift 2 Ton" |
| status | enum `vehicle_status` ('available','maintenance','inactive') | default `available` |
| photo_path | varchar(255) null | path relatif file foto |
| created_at, updated_at | timestamptz | |
| deleted_at | timestamptz null | **soft delete** agar riwayat reservasi tetap utuh. Semua query kendaraan harus memfilter `deleted_at IS NULL` |

### `batches`
| Kolom | Tipe | Catatan |
|---|---|---|
| id | serial PK | |
| name | varchar(50) | "Batch 1" |
| start_time | varchar(5) | format `HH:mm` (sengaja bukan tipe `time` agar mudah di Prisma) |
| end_time | varchar(5) | harus > start_time |
| is_active | boolean | default `true` |
| created_at, updated_at | timestamptz | |

Seeder awal: Batch 1 (07:30-09:30, aktif), Batch 2 (09:30-11:30, aktif), Batch 3 (13:00-15:00, nonaktif), Batch 4 (15:00-17:00, nonaktif).

### `work_units` (untuk autocomplete Unit Kerja)
| Kolom | Tipe | Catatan |
|---|---|---|
| id | serial PK | |
| name | varchar(150) | unique |

Seeder: Divisi Permukaan, Divisi Kapal Selam, Divisi Pemeliharaan dan Perbaikan, Divisi Rekayasa Umum, Divisi Pemasaran dan Penjualan, Divisi Rantai Pasok, Divisi Manajemen Aset, Infrastruktur & K3LH.

### `reservations`
| Kolom | Tipe | Catatan |
|---|---|---|
| id | serial PK | dipakai sebagai No. Reservasi di struk |
| user_id | int FK -> users | |
| vehicle_id | int FK -> vehicles | |
| batch_id | int FK -> batches | |
| reservation_date | date | |
| work_unit | varchar(150) | disimpan sebagai teks (snapshot) |
| purpose | text | Jenis Kebutuhan |
| status | enum `reservation_status` ('pending','approved','rejected','cancelled','completed') | default `pending` |
| admin_note | text null | Catatan Admin (misal alasan penolakan) |
| processed_by | int FK -> users null | admin yang memproses |
| processed_at | timestamptz null | |
| created_at, updated_at | timestamptz | |

Index tambahan: `(reservation_date, status)`, `(user_id, created_at)`.

**Mencegah double booking (fitur khas PostgreSQL):** pakai **partial unique index**, ditambahkan lewat file migration SQL manual (Prisma schema belum mendukung partial index):
```sql
CREATE UNIQUE INDEX uniq_active_reservation_slot
ON reservations (vehicle_id, reservation_date, batch_id)
WHERE status IN ('pending', 'approved');
```
Hanya satu reservasi aktif (`pending`/`approved`) per kendaraan + tanggal + batch. Reservasi `rejected`, `cancelled`, atau `completed` tidak menghalangi. Saat insert melanggar index ini (Prisma error `P2002` / kode Postgres `23505`), kembalikan HTTP `409` "Slot sudah dipesan". Pembuatan reservasi tetap dibungkus `prisma.$transaction`.

### `notifications`
| Kolom | Tipe | Catatan |
|---|---|---|
| id | serial PK | |
| user_id | int FK -> users | penerima |
| type | varchar(50) | `reservation_approved`, `reservation_rejected`, `reservation_completed`, `reservation_created` (untuk admin) |
| title | varchar(150) | |
| message | text | |
| reservation_id | int FK null | |
| read_at | timestamptz null | null = belum dibaca |
| created_at | timestamptz | |

Index: `(user_id, read_at)`.

### Relasi
`User 1-N Reservation`, `Vehicle 1-N Reservation`, `Batch 1-N Reservation`, `User 1-N Notification`.

---

## 3. Aturan Bisnis di Backend

- **Status slot (dashboard):** untuk kendaraan + tanggal + batch: tidak ada reservasi aktif -> `empty`; ada `pending` -> `pending`; ada `approved`/`completed` -> `booked`.
- **Kendaraan `maintenance`/`inactive`/terhapus** tidak bisa direservasi dan tidak muncul di dropdown form.
- **Batch nonaktif** tidak dikembalikan oleh `GET /batches` dan tidak muncul di slot dashboard (admin tetap melihat semua via `/admin/batches`).
- **Tanggal reservasi** tidak boleh di masa lalu (bandingkan dengan tanggal `Asia/Jakarta`).
- **Transisi status yang valid:**

| Dari | Ke | Pelaku |
|---|---|---|
| pending | approved / rejected | admin |
| pending | cancelled | pemilik reservasi |
| approved | completed | admin |

  Transisi lain -> HTTP `422`.
- **Notifikasi dibuat otomatis:**
  - Reservasi baru dibuat -> notifikasi `reservation_created` ke semua admin.
  - Admin approve/reject/complete -> notifikasi ke pemilik.
- **Akun nonaktif (`is_active = false`):** tidak bisa login (403). Middleware auth **mengecek `is_active` ke DB di setiap request**, sehingga token lama otomatis ditolak.
- Admin tidak boleh menonaktifkan atau menurunkan role **dirinya sendiri**.
- Struk (`GET /reservations/{id}`) hanya boleh diakses pemilik atau admin.
- **Logout** bersifat stateless: server membalas sukses, klien menghapus token (JWT tidak disimpan di DB agar tetap lean).

---

## 4. Daftar Endpoint

### Auth
| Method | Path | Akses | Keterangan |
|---|---|---|---|
| POST | `/auth/register` | publik | name, email, password, password_confirmation |
| POST | `/auth/login` | publik | email, password |
| POST | `/auth/logout` | login | |
| GET | `/auth/me` | login | data user + role |

### Profil
| Method | Path | Keterangan |
|---|---|---|
| PUT | `/profile` | name, email |
| PUT | `/profile/password` | current_password, password (min 8), password_confirmation |

### Data referensi & dashboard pengguna (login)
| Method | Path | Keterangan |
|---|---|---|
| GET | `/batches` | batch aktif saja |
| GET | `/work-units?q=` | saran autocomplete |
| GET | `/vehicles/availability?date=` | kartu dashboard: semua kendaraan + status slot per batch aktif (default hari ini) |
| GET | `/vehicles/available?date=&batch_id=` | kendaraan `available` yang slotnya kosong, untuk dropdown form |

### Reservasi pengguna (login)
| Method | Path | Keterangan |
|---|---|---|
| GET | `/reservations` | riwayat milik sendiri, urut terbaru, paginasi |
| POST | `/reservations` | vehicle_id, batch_id, reservation_date, work_unit, purpose |
| GET | `/reservations/{id}` | detail untuk struk |
| POST | `/reservations/{id}/cancel` | hanya jika `pending` |

### Notifikasi (login, user dan admin)
| Method | Path | Keterangan |
|---|---|---|
| GET | `/notifications` | paginasi, terbaru dulu |
| GET | `/notifications/unread-count` | untuk badge lonceng |
| POST | `/notifications/{id}/read` | |
| POST | `/notifications/read-all` | |

### Admin (`/admin/*`, middleware `admin`)
| Method | Path | Keterangan |
|---|---|---|
| GET | `/admin/dashboard` | ringkasan, distribusi status, daftar pending |
| GET | `/admin/reservations?status=&date=&work_unit=&page=` | filter; Reset = tanpa parameter |
| POST | `/admin/reservations/{id}/approve` | |
| POST | `/admin/reservations/{id}/reject` | admin_note (opsional) |
| POST | `/admin/reservations/{id}/complete` | hanya dari `approved` |
| GET | `/admin/vehicles` | semua kendaraan (tanpa yang terhapus) |
| POST | `/admin/vehicles` | multipart: name, type, status, photo (jpg/png/webp, maks 3 MB) |
| GET | `/admin/vehicles/{id}` | untuk form edit |
| PUT | `/admin/vehicles/{id}` | multipart (multer di Express menangani PUT multipart dengan baik) |
| DELETE | `/admin/vehicles/{id}` | soft delete (isi `deleted_at`) |
| GET | `/admin/users` | + `reservations_count` |
| PATCH | `/admin/users/{id}/role` | role = `admin`/`user` |
| PATCH | `/admin/users/{id}/active` | is_active = true/false |
| GET | `/admin/batches` | semua batch termasuk nonaktif |
| PUT | `/admin/batches/{id}` | name, start_time, end_time, is_active |
| GET | `/admin/reports?period=daily|weekly&date=` | laporan |

---

## 5. Contoh Response JSON

### POST `/auth/login`
```json
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": { "id": 5, "name": "Nahel", "email": "nahel@gmail.com", "role": "user", "is_active": true }
  }
}
```
Login gagal: `422` `{ "success": false, "message": "Email atau password salah." }`. Akun nonaktif: `403` `{ "success": false, "message": "Akun Anda dinonaktifkan. Hubungi admin." }`.

### GET `/vehicles/availability?date=2026-11-05`
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "date": "2026-11-05",
    "vehicles": [
      {
        "id": 1,
        "name": "Forklift 10 Ton - Unit 1",
        "type": "Forklift 10 Ton",
        "status": "available",
        "photo_url": "http://10.0.2.2:3000/uploads/vehicles/abc.jpg",
        "slots": [
          { "batch_id": 1, "batch_name": "Batch 1", "start_time": "07:30", "end_time": "09:30", "status": "empty" },
          { "batch_id": 2, "batch_name": "Batch 2", "start_time": "09:30", "end_time": "11:30", "status": "pending" }
        ]
      }
    ]
  }
}
```
> `photo_url` dibentuk dari env `PUBLIC_URL` + `/uploads/...`. Express menyajikan folder `uploads/` lewat `express.static`. Untuk emulator, set `PUBLIC_URL=http://10.0.2.2:3000`.

### POST `/reservations` (sukses, HTTP 201)
```json
{
  "success": true,
  "message": "Reservasi berhasil diajukan.",
  "data": {
    "id": 7,
    "status": "pending",
    "reservation_date": "2026-08-28",
    "work_unit": "Divisi Pemeliharaan dan Perbaikan",
    "purpose": "Pengiriman Material",
    "admin_note": null,
    "vehicle": { "id": 4, "name": "Lift Truck - Unit 1", "type": "Lift Truck", "photo_url": null },
    "batch": { "id": 2, "name": "Batch 2", "start_time": "09:30", "end_time": "11:30" },
    "user": { "id": 5, "name": "Nahel" },
    "created_at": "2026-08-20T08:10:00+07:00"
  }
}
```
Slot bentrok: `409` `{ "success": false, "message": "Slot sudah dipesan. Pilih batch atau kendaraan lain." }`.

Objek reservasi yang sama dipakai oleh `GET /reservations`, `GET /reservations/{id}` (struk), dan `/admin/reservations` (admin juga mendapat `user.email`).

### GET `/notifications/unread-count`
```json
{ "success": true, "message": "OK", "data": { "unread": 2 } }
```

### GET `/admin/dashboard`
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "summary": { "pending": 3, "approved": 3, "vehicles_available": 5, "total_users": 6 },
    "status_distribution": { "pending": 3, "approved": 3, "rejected": 1, "cancelled": 0, "completed": 0 },
    "pending_reservations": [ { "id": 12, "user": { "name": "Nahel" }, "work_unit": "Divisi Rantai Pasok",
      "vehicle": { "name": "Forklift 10 Ton - Unit 1" }, "reservation_date": "2026-08-19",
      "batch": { "name": "Batch 1" } } ],
    "recent_activity": []
  }
}
```
`recent_activity` dan data chart tambahan (misal reservasi per hari 7 hari terakhir) adalah **[Rencana]**.

### GET `/admin/reports?period=weekly&date=2026-11-05` (usulan, masih **[Rencana]**)
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "period": "weekly",
    "range": { "from": "2026-11-02", "to": "2026-11-08" },
    "status_summary": { "pending": 3, "approved": 2, "rejected": 1, "completed": 1 },
    "trend": [ { "date": "2026-11-02", "total": 2 }, { "date": "2026-11-03", "total": 0 } ],
    "vehicle_utilization": [ { "vehicle": "Forklift 10 Ton - Unit 1", "reservations": 4 } ],
    "by_work_unit": [ { "work_unit": "Divisi Rantai Pasok", "total": 3 } ],
    "vehicle_status": { "available": 5, "maintenance": 1, "inactive": 0 }
  }
}
```
`period=daily` memakai `date` tunggal dan `trend` berupa per batch/jam. Metrik pengganti final masih diputuskan di fitur Laporan.

---

## 6. Setup Development (Node.js + PostgreSQL)

1. Pasang **Node.js LTS** dan **PostgreSQL** (installer resmi, atau Docker `postgres:16`). Buat database `reservasi_paa` (pakai pgAdmin atau `createdb reservasi_paa`).
2. File `.env`:
   ```
   PORT=3000
   DATABASE_URL="postgresql://postgres:PASSWORD@localhost:5432/reservasi_paa?schema=public"
   JWT_SECRET=ganti-dengan-string-acak-panjang
   JWT_EXPIRES_IN=7d
   PUBLIC_URL=http://10.0.2.2:3000
   TZ=Asia/Jakarta
   ```
3. Paket: `express`, `@prisma/client`, `prisma` (dev), `jsonwebtoken`, `bcryptjs`, `zod`, `multer`, `cors`, `dotenv`, `nodemon` (dev).
4. `npx prisma migrate dev` (lalu tambahkan migration SQL manual untuk partial unique index), lalu `npx prisma db seed`.
5. Jalankan: `npm run dev`. Server mendengarkan di `0.0.0.0` agar bisa diakses emulator/perangkat fisik.
6. Android: izinkan HTTP non-HTTPS untuk development (`android:usesCleartextTraffic="true"` di `AndroidManifest.xml`). Jika memakai perangkat fisik, pastikan firewall mengizinkan port 3000.
7. Akun seed: `admin@paa.local` (role admin) dan satu akun `user` untuk uji. Ganti password default sebelum produksi.
