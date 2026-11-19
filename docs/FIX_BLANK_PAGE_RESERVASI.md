# Perbaikan Halaman Blank: Riwayat Reservasi (User) dan Kelola Reservasi (Admin)

## Masalah

Halaman `/#/riwayat` (user) dan `/#/admin/reservasi` (admin) masih blank putih di area tengah. Hanya AppBar dan BottomNav yang tampil. Terminal `dart app` mengeluarkan error berulang `rendering/mouse_tracker.dart:199:12`.

`dart analyze` sudah bersih, jadi ini adalah **runtime layout error**, bukan static error.

**Aturan utama:** jangan menyatakan selesai hanya karena `dart analyze` lolos. Perbaikan baru dianggap selesai jika sudah terbukti di runtime (dijalankan di browser dan terminal bebas error).

## File yang terkait

- `reservation_history_screen.dart`
- `admin_reservation_screen.dart`
- `reservation_repository.dart`
- `admin_reservation_repository.dart`
- `reservation_model.dart`

---

## Langkah 0: Bersihkan sesi lama

- Hentikan **semua** proses `flutter run` / `dart` yang masih berjalan. Browser sebelumnya membuka port `58182`, sedangkan AI menyebut `54860`, sehingga kemungkinan ada instance lama.
- Jalankan ulang dengan port tetap:

```bash
flutter run -d chrome --web-port=54860
```

- Backend Node tetap di port `3000`.
- Pengujian hanya dilakukan di `http://localhost:54860`.

## Langkah 1: Tangkap penyebab pasti (tanpa menebak)

1. Buka `/#/riwayat` dan `/#/admin/reservasi` di instance baru.
2. Ambil **error merah pertama** di terminal, yaitu yang muncul sebelum rentetan `mouse_tracker`. Contoh yang dicari:
   - `The following assertion was thrown during performLayout()`
   - `RenderBox was not laid out`
   - `Vertical viewport was given unbounded height`
   - `RenderFlex overflowed`
3. Tampilkan kutipan error apa adanya beserta baris `The relevant error-causing widget was ...`.
4. Cek **Console** dan **Network** di DevTools Chrome (F12) untuk error CORS, `XMLHttpRequest`, status 401/404/500, atau gagal parsing JSON.
5. Tulis penyebab pasti berdasarkan log tersebut **sebelum** mengubah kode apa pun.

## Langkah 2: Perbaiki struktur layout

File: `reservation_history_screen.dart` dan `admin_reservation_screen.dart`.

Cari kombinasi constraint yang bermasalah:

- `Expanded` atau `ListView` di dalam `Column` yang berada di dalam `SingleChildScrollView` (tinggi tak terbatas).
- `Expanded` atau `Flexible` di dalam `SingleChildScrollView` horizontal (lebar tak terbatas).
- `ListView` di dalam `ListView` atau `Column` tanpa `shrinkWrap: true` dan `physics: NeverScrollableScrollPhysics()`.
- `DataTable` atau `Row` lebar tanpa pembungkus scroll horizontal.
- `Expanded` yang bukan child langsung dari `Row`, `Column`, atau `Flex`.

Terapkan struktur yang aman:

- **Mobile (< 700px):** daftar kartu per reservasi, memakai `Column` dengan `Expanded(child: ListView.builder(...))`. Bukan tabel.
- **Desktop (>= 700px):** tabel lebar dengan pola berikut, **tanpa** `Expanded` di dalamnya:

```dart
LayoutBuilder(
  builder: (context, constraints) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: ConstrainedBox(
      constraints: BoxConstraints(minWidth: constraints.maxWidth),
      child: DataTable(columns: [...], rows: [...]),
    ),
  ),
)
```

- Pilih **satu** pola scroll vertikal per halaman. Jangan menggabungkan `SingleChildScrollView` dengan `Expanded(ListView)`.
- State **Loading**, **Kosong**, dan **Error** harus selalu menampilkan widget yang terlihat dengan ukuran jelas (misalnya `Center` di dalam `Expanded`, atau `SizedBox`). Area tengah tidak boleh kosong.

## Langkah 3: Pastikan data backend masuk ke UI

File: `reservation_repository.dart`, `admin_reservation_repository.dart`, `reservation_model.dart`.

- Verifikasi endpoint di `http://localhost:3000` mengembalikan data. Uji dengan `curl` atau browser, lalu tampilkan hasilnya.
- Pastikan CORS di backend Node mengizinkan origin `http://localhost:54860`.
- Pastikan header Authorization/token terkirim.
- Perbaiki null-safety di `fromJson`:
  - Field yang bisa null memakai `?` atau `??` dengan nilai default.
  - Tanggal diparsing dengan aman (`DateTime.tryParse` atau `try/catch`).
  - Angka memakai `(v as num?)`.
- Tangkap exception di repository dan teruskan ke state Error agar UI menampilkan pesan, bukan blank.

## Langkah 4: Tampilan target

**Halaman user, "Riwayat Reservasi"**

Kolom: Tanggal, Batch, Kendaraan (nama - unit + jenis), Unit Kerja, Jenis Kebutuhan, Status (badge berwarna), Catatan Admin, Aksi (Struk / Batalkan).

**Halaman admin, "Kelola Reservasi"**

Filter: Status, Tanggal, Unit Kerja, tombol Filter dan Reset.

Kolom: Pemohon (nama + email), Unit Kerja, Kendaraan, Tanggal/Batch, Jenis Kebutuhan, Status, Aksi (Setujui/Tolak, Selesai, Struk).

**Mobile:** setiap baris menjadi kartu yang memuat informasi yang sama.

## Langkah 5: Verifikasi (wajib)

- Jalankan ulang `flutter run -d chrome --web-port=54860`.
- Buka kedua halaman di lebar desktop **dan** lebar mobile (resize jendela browser).
- Pastikan **tidak ada** error merah di terminal `dart app` dan tidak ada error di Console Chrome.
- Laporkan:
  1. Penyebab pasti dari log error pertama.
  2. File dan baris yang diubah.
  3. Bukti data tampil (jumlah baris yang termuat).
  4. Hasil verifikasi runtime.
- Jika masih ada error, lanjutkan memperbaiki sampai bersih. Jangan berhenti di `dart analyze`.
- Setelah semuanya terbukti, baru lakukan commit dan push.
