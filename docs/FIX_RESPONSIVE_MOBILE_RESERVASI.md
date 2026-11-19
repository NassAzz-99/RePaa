# Tampilan Mobile Responsif: Kelola Reservasi (Admin) dan Riwayat Reservasi (User)

## Tujuan

Tampilan desktop (tabel) sudah benar dan **tidak boleh diubah**. Yang perlu dibuat adalah tampilan mobile untuk dua halaman:

- `/#/admin/reservasi` (admin)
- `/#/riwayat` (user)

Kerjakan secukupnya. Jangan menambah fitur atau abstraksi di luar yang tertulis di sini.

## 1. Responsif

- Pakai `LayoutBuilder` dengan breakpoint **700px**.
- Lebar >= 700px: tabel seperti sekarang.
- Lebar < 700px: daftar kartu memakai `ListView.builder` di dalam `Expanded`, padding 12 px, jarak antar kartu 12 px.
- Tidak boleh ada overflow di lebar 360px.

## 2. Kartu Admin (mobile)

Satu reservasi = satu `Card`. Isinya berurutan ke bawah dengan format `label: nilai`:

- Pemohon (nama dan email)
- Unit Kerja
- Kendaraan
- Tanggal dan Batch
- Jenis Kebutuhan
- Status (badge berwarna seperti di tabel)
- Alasan Penolakan (hanya tampil jika status Ditolak)

Bagian **Aksi** di bagian bawah kartu, sesuai status:

| Status | Aksi |
|---|---|
| Menunggu Persetujuan | Tombol **Setujui** dan **Tolak**, sejajar dan sama lebar |
| Disetujui | Tombol **Struk** dan **Selesai** |
| Selesai | Tombol **Struk** |
| Ditolak | Tanpa tombol, tampilkan alasan penolakan |

## 3. Setujui

- Tombol Setujui memanggil API yang sudah ada.
- Setelah berhasil, status berubah menjadi Disetujui dan daftar diperbarui.
- Tombol **Struk** muncul di kartu. **Jangan** membuka struk otomatis dan jangan menambah SnackBar aksi. Struk dibuka hanya saat tombol Struk ditekan.

## 4. Tolak dengan Alasan

- Tombol Tolak membuka `AlertDialog` berisi `TextField` multiline "Alasan penolakan".
- Alasan wajib diisi (minimal 5 karakter). Jika kosong, tombol kirim tidak bisa ditekan.
- Setelah dikirim: status menjadi Ditolak, alasan tersimpan, daftar diperbarui.
- Cegah klik ganda saat request berjalan.

## 5. Backend (Node, port 3000)

- Cek endpoint tolak yang sudah ada. Pastikan menerima dan menyimpan alasan penolakan.
- Jika field alasan belum ada di database, tambahkan sesuai struktur proyek dan jelaskan perubahannya.
- Pastikan data list reservasi (admin dan user) menyertakan field alasan tersebut.
- Perbarui model Flutter dengan null-safety (alasan boleh null).

## 6. Kartu User (mobile, `/#/riwayat`)

Satu reservasi = satu `Card`, format `label: nilai` berurutan ke bawah:

- Tanggal
- Batch
- Kendaraan
- Unit Kerja
- Jenis Kebutuhan
- Status (badge)
- Catatan Admin (jika Ditolak, tampilkan alasan dari admin dengan jelas)

Aksi:

- Menunggu Persetujuan: tombol **Batalkan**
- Disetujui dan Selesai: tombol **Struk**

## 7. State

Loading, Kosong, dan Error harus tetap menampilkan widget yang terlihat (`Center` di dalam `Expanded`) agar area tengah tidak blank. Fitur filter dan refresh yang sudah ada tetap dipertahankan.

## 8. Verifikasi (wajib)

1. Hentikan semua instance lama, lalu jalankan `flutter run -d chrome --web-port=54860`.
2. Uji di lebar 360px dan desktop. Pastikan tidak ada overflow dan tidak ada error merah di terminal.
3. Uji alur berikut:
   - Admin menyetujui reservasi, tombol Struk muncul di kartu.
   - Admin menolak reservasi, alasan wajib diisi dan tersimpan.
   - Login sebagai user, alasan penolakan tampil di Riwayat.
4. Laporkan file yang diubah dan hasil pengujian. Setelah terbukti, baru commit dan push.
