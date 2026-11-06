# PROMPT: Dashboard Admin

## 1. Role & Objective
Kamu adalah seorang Senior Mobile & Backend Developer. Bantu aku membuat kode untuk **satu fitur saja**: **Dashboard Admin** pada aplikasi mobile **Reservasi PAA (Peralatan Angkat & Angkut)**, yang diadaptasi dari versi web milikku. Kerjakan hanya fitur ini, jangan membuat fitur lain.

## 2. Tech Stack & Environment
- **Mobile Frontend:** Flutter (State Management: Riverpod / Provider, pilih yang paling modular dan clean).
- **Backend API:** Node.js + Express (RESTful API, autentikasi JWT).
- **Database:** PostgreSQL (akses data via Prisma).
- **Arsitektur:** Feature-First.
- **Base URL API:** `http://10.0.2.2:3000/api` (emulator Android). Gunakan Dio atau http.

## 3. Aturan Utama
- **Lean & Modular:** jangan over-engineered, minim abstraksi yang tidak perlu, mudah dibaca, tetap standar produksi.
- **Feature-First:** fitur berdiri sendiri di `lib/features/admin_dashboard/` dengan `data/` (model, repository), `domain/` (jika perlu), `presentation/` (screens, widgets, providers).
- **Asumsikan sudah tersedia** (tidak perlu dibuat ulang): `core/network` (Dio client + interceptor token), `core/routes`, dan fitur `auth` (token tersimpan, data user + role tersedia lewat provider).
- **Wajib mengikuti Blueprint Database & API** (`00_blueprint_database_api.md`): nama tabel/kolom, endpoint, kode status (`pending`, `approved`, dst.), dan format response `{success, message, data}`.
- Jangan menambahkan fitur di luar deskripsi di bawah. Poin bertanda **[Rencana]** cukup disiapkan strukturnya.

## 4. Konteks Umum Aplikasi (ringkas)
- Role: **Pengguna** dan **Admin**.
- Reservasi dilakukan per **tanggal + batch** (slot waktu harian yang diatur admin). Data awal batch: Batch 1 (07:30-09:30, aktif), Batch 2 (09:30-11:30, aktif), Batch 3 (13:00-15:00, nonaktif), Batch 4 (15:00-17:00, nonaktif). Batch nonaktif tidak tampil di dashboard dan form reservasi.
- **Status kendaraan:** `Tersedia`, `Perawatan`, `Nonaktif`.
- **Status slot batch di dashboard:** `Kosong` (hijau), `Menunggu` (kuning), `Dipesan` (merah).
- **Status reservasi:** `Menunggu Persetujuan` -> `Disetujui` / `Ditolak`; `Disetujui` -> `Selesai`; `Dibatalkan` (oleh pengguna, hanya saat masih menunggu).
- **Navigasi mobile:** sidebar web diganti **bottom navigation**. Pengguna: Dashboard, Form Reservasi, Riwayat, Profil. Admin: Dashboard, Kelola Reservasi, Kelola (hub: Kendaraan, Pengguna, Batch), Laporan.
- Tabel versi web diubah menjadi **list berbasis card** di mobile.

---

## 5. Spesifikasi Fitur: Dashboard Admin

### Deskripsi
Halaman utama admin: ringkasan dan persetujuan cepat.

### Detail
- **Kartu ringkasan:** Menunggu Persetujuan, Disetujui, Kendaraan Tersedia, Total Pengguna.
- **Distribusi Status Reservasi:** chart donut (Menunggu, Disetujui, Ditolak, Dibatalkan, Selesai) beserta legenda dan jumlahnya.
- **Reservasi Menunggu Persetujuan:** list card (Pemohon, Unit Kerja, Kendaraan, Tanggal/Batch) dengan tombol **Setuju** dan **Tolak** langsung dari dashboard, dan tautan "Lihat semua" ke Kelola Reservasi.
- **[Rencana]** Tambahkan visualisasi selain donut (misal bar chart reservasi per hari, kendaraan paling sering dipakai). Cukup beri 1 contoh tambahan yang paling berguna dan sediakan struktur agar mudah ditambah.
- **[Rencana]** Notifikasi saat ada reservasi baru (dikerjakan di fitur Notifikasi).
- Gunakan paket chart ringan (misal `fl_chart`).
- Satu endpoint ringkasan (`/admin/dashboard`) sebaiknya mengembalikan seluruh data di atas agar request minimal.

---

## 6. Tugas yang Harus Dikerjakan
1. **Struktur folder** fitur ini (`lib/features/admin_dashboard/`) beserta daftar file.
2. **Kode lengkap**, tiap file di code block terpisah dengan path di atasnya:
   - Model data Flutter.
   - Repository/Service untuk komunikasi ke API Node.js.
   - State management sederhana (loading, success, error).
   - UI Screen/Widget.
3. **Kesesuaian dengan Blueprint:** Ikuti Blueprint Database & API yang kulampirkan (`00_blueprint_database_api.md`). Sebutkan tabel dan endpoint yang dipakai fitur ini. Jika ada kekurangan di blueprint, tandai sebagai **usulan perubahan**, jangan diam-diam mengubah nama tabel, endpoint, atau format response. Kode backend Node.js dikerjakan terpisah lewat prompt backend.
4. **Integrasi:** cara fitur ini didaftarkan ke routing dan bottom navigation, serta dependensi ke fitur lain.

## 7. Format Jawaban
- Penjelasan dalam bahasa Indonesia; kode dan nama variabel dalam bahasa Inggris.
- Jelaskan singkat setiap keputusan arsitektur yang penting.
