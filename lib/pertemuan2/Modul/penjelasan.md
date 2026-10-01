# Doc Tugas - Pertemuan 2: Layout, ListView, dan Navigasi

## Widget Layout
- `Container` : kotak serbaguna (ukuran, warna, border, radius, padding, margin)
- `Padding` : memberi jarak di sekeliling widget anak
- `Row` : menyusun anak horizontal (main axis horizontal, cross axis vertikal)
- `Column` : menyusun anak vertikal (main axis vertikal, cross axis horizontal)
- `Expanded` : membuat anak mengisi sisa ruang di Row/Column, mencegah overflow
- `SizedBox` : memberi jarak kosong (`width` / `height`)
- `CircleAvatar` : avatar berbentuk lingkaran, bisa berisi ikon atau teks

## Properti Layout
- `padding` : jarak di dalam widget
- `margin` : jarak di luar widget
- `EdgeInsets.all()` : jarak sama di semua sisi
- `EdgeInsets.symmetric()` : jarak horizontal / vertikal
- `decoration` + `BoxDecoration` : mengatur tampilan Container (warna, sudut)
- `BorderRadius.circular()` : membuat sudut membulat
- `mainAxisAlignment` : perataan pada sumbu utama
- `crossAxisAlignment` : perataan pada sumbu silang

## List & Data
- `class Makanan` : model data sederhana (nama, harga, deskripsi)
- `final` : properti yang nilainya tidak bisa diubah setelah dibuat
- `List` (`daftarMenu`) : kumpulan objek data
- `ListView.builder` : daftar yang dirender sesuai kebutuhan, efisien untuk data banyak
- `itemCount` : jumlah item dalam daftar
- `itemBuilder` : fungsi pembuat tiap item berdasarkan `index`
- `Card` : kartu dengan bayangan dan sudut membulat
- `ListTile` : baris standar (`leading`, `title`, `subtitle`, `trailing`)
- `onTap` : fungsi yang dijalankan saat item diketuk
- `'Rp ${item.harga}'` : string interpolation untuk menyisipkan nilai variabel

## Navigasi
- `Navigator.push()` : membuka halaman baru (menambah ke stack)
- `Navigator.pop()` : menutup halaman saat ini (kembali)
- `MaterialPageRoute` : membuat rute halaman dengan transisi Material
- `builder` : fungsi yang mengembalikan halaman tujuan
- `context` : posisi widget, dipakai Navigator untuk tahu stack-nya
- `required` : parameter constructor yang wajib diisi
- Kirim data : lewat constructor, contoh `DetailPage(makanan: item)`

## Widget Lain
- `ThemeData` : mengatur tema aplikasi (`colorSchemeSeed`, `useMaterial3`)
- `ElevatedButton` : tombol dengan efek timbul, aksi lewat `onPressed`
- `Icons.xxx` : ikon bawaan Flutter

## Troubleshooting
- Garis kuning-hitam (overflow) : bungkus dengan `Expanded` atau `SingleChildScrollView`
- ListView di dalam Column error : bungkus ListView dengan `Expanded`
- Navigator error : pastikan halaman ada di bawah `MaterialApp`
- Perubahan tidak muncul : gunakan hot restart (Shift+R) jika mengubah `main()` atau data `const`

## Jawaban Refleksi
- **ListView vs ListView.builder:** ListView biasa membuat semua item sekaligus, builder hanya membuat item yang terlihat (lebih efisien)
- **Overflow di Row:** teks panjang melebihi lebar layar; `Expanded` membatasi teks mengisi sisa ruang dan membungkusnya
- **Kirim data ke detail:** lewat constructor `DetailPage(makanan: item)` saat `Navigator.push`