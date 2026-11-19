# Perbaikan: Struk (Cetak / Simpan PDF) dan Notifikasi (Bisa Dibuka)

## Tujuan

Dua perbaikan kecil pada aplikasi yang sudah berjalan:

1. Struk reservasi bisa **dicetak** atau **disimpan sebagai PDF**.
2. Notifikasi bisa **dibuka dan dibaca isinya**, tidak hanya berubah menjadi "sudah dibaca".

Kerjakan secukupnya. Jangan mengubah desain halaman lain dan jangan menambah fitur di luar yang tertulis di sini. Gunakan halaman, model, dan endpoint yang sudah ada.

---

## 1. Struk: Cetak dan Simpan PDF

### Kondisi yang diharapkan

- Struk hanya bisa dibuka untuk reservasi berstatus **Disetujui** atau **Selesai**.
- Di halaman struk ada dua tombol: **Cetak** dan **Simpan PDF**.
- Berlaku di Flutter Web (desktop) dan di layar mobile.

### Cara kerja

- Pakai package `pdf` dan `printing` (tambahkan ke `pubspec.yaml` jika belum ada, lalu `flutter pub get`).
- Buat satu fungsi yang menyusun dokumen PDF dari data struk yang sudah ada (nomor/ID reservasi, pemohon, unit kerja, kendaraan, tanggal dan batch, jenis kebutuhan, status). Isi PDF harus sama dengan tampilan struk di layar.
- **Cetak** dan **Simpan PDF** memakai fungsi yang sama:
  - Cetak: `Printing.layoutPdf(onLayout: ...)` (membuka dialog cetak browser/perangkat; dari sana pengguna juga bisa memilih "Save as PDF").
  - Simpan PDF: `Printing.sharePdf(bytes: ..., filename: 'struk-<id>.pdf')`.
- Ukuran kertas A5 atau A4 portrait, cukup satu halaman.
- Jika ada font khusus atau teks berbahasa Indonesia yang tampil rusak, pakai font bawaan package `printing` (`PdfGoogleFonts`) atau font yang sudah ada di proyek.
- Tampilkan SnackBar jika gagal membuat PDF. Tidak perlu fitur lain.

### Cek

- Tombol Struk di halaman admin dan user membuka halaman yang sama.
- File PDF yang tersimpan bisa dibuka dan isinya lengkap.

---

## 2. Notifikasi: Bisa Dibuka dan Dibaca

### Masalah saat ini

Notifikasi ditekan hanya langsung berubah menjadi "sudah dibaca". Isinya tidak pernah terlihat, sehingga pengguna tidak tahu pesan notifikasinya apa.

### Langkah

1. **Temukan dulu penyebabnya** di kode notifikasi yang ada. Kemungkinan: `onTap` hanya memanggil fungsi "mark as read" tanpa menampilkan apa pun, atau teks pesan terpotong (`maxLines` / `ellipsis`) dan tidak ada tampilan detail. Tuliskan temuanmu sebelum mengubah kode.
2. Saat notifikasi ditekan, tampilkan **detail** dalam `AlertDialog` atau `showModalBottomSheet` (pilih salah satu yang paling mudah di kode yang ada) berisi:
   - Judul
   - Isi pesan lengkap (tanpa dipotong)
   - Waktu notifikasi (format mudah dibaca, contoh `19/11/2026 17:04`)
   - Jika notifikasi terkait reservasi yang **ditolak**, tampilkan alasan penolakan dari admin.
   - Tombol **Tutup**.
3. Tandai sebagai sudah dibaca **setelah detail terbuka**, lalu perbarui badge angka di ikon lonceng.
4. Di daftar notifikasi, pesan boleh dipotong 2 baris sebagai ringkasan. Notifikasi yang belum dibaca dibedakan secara visual (misalnya teks tebal atau titik kecil).
5. Pastikan endpoint notifikasi di backend (port 3000) mengembalikan judul, pesan lengkap, waktu, dan status baca. Jika ada field yang belum dikirim, tambahkan secukupnya dan jelaskan perubahannya.
6. Perhatikan null-safety pada model notifikasi (field boleh null, tampilkan nilai default).

### Cek

- Menekan notifikasi membuka detail dengan isi pesan lengkap.
- Badge angka berkurang setelah notifikasi dibuka.
- Notifikasi penolakan menampilkan alasan dari admin.

---

## 3. Verifikasi (wajib)

1. Hentikan semua instance lama, lalu jalankan `flutter run -d chrome --web-port=54860`.
2. Uji di lebar desktop dan mobile (sekitar 360px). Pastikan tidak ada overflow dan tidak ada error merah di terminal.
3. Uji alur:
   - Buka struk reservasi yang disetujui, tekan Cetak, lalu Simpan PDF dan buka hasilnya.
   - Admin menolak reservasi dengan alasan, lalu login sebagai user dan buka notifikasinya sampai isi dan alasan terbaca.
4. Laporkan file yang diubah, penyebab masalah notifikasi, dan hasil pengujian. Setelah terbukti, baru commit dan push.
