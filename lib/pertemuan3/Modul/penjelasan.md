# Doc Tugas - Pertemuan 3: Form Input dan State Management

## Input Dasar
- `TextField` : kolom input teks
- `TextEditingController` : membaca dan mengontrol isi TextField (`.text`)
- `dispose()` : melepas controller saat halaman ditutup agar tidak terjadi kebocoran memori
- `InputDecoration` : mengatur tampilan input (`labelText`, `border`)
- `OutlineInputBorder` : border kotak di sekeliling input
- `keyboardType` : jenis keyboard (misal `TextInputType.emailAddress`, `number`)
- `autofocus` : langsung fokus ke input saat halaman terbuka
- `onSubmitted` : dijalankan saat pengguna menekan enter/selesai

## Form & Validasi
- `Form` : pembungkus beberapa input agar divalidasi sekaligus
- `GlobalKey<FormState>` : kunci untuk mengakses state Form
- `validate()` : menjalankan semua validator, mengembalikan `true` jika valid
- `TextFormField` : TextField yang bisa divalidasi di dalam Form
- `validator` : mengembalikan pesan error, atau `null` jika valid
- `DropdownButtonFormField` : dropdown dengan validasi
- `DropdownMenuItem` : satu pilihan di dropdown (`value`, `child`)
- `onChanged` : dijalankan saat nilai input berubah
- `CheckboxListTile` : checkbox dengan label
- `ScaffoldMessenger` + `SnackBar` : menampilkan pesan singkat di bawah layar
- `onPressed: null` : membuat tombol nonaktif
- `??` : null-aware operator, memberi nilai default jika null (`_jurusan ?? '-'`)

## State
- **State** : data yang bisa berubah dan memengaruhi tampilan
- **Ephemeral state** : state lokal satu widget, cukup `setState`
- **App state** : state yang dipakai banyak halaman, butuh Provider
- Keterbatasan `setState` : sulit berbagi data antar halaman (harus oper lewat constructor/callback)

## Provider
- `flutter pub add provider` : memasang paket provider
- `ChangeNotifier` : class model yang bisa memberi tahu perubahan datanya
- `notifyListeners()` : memberi tahu widget yang berlangganan agar rebuild
- `ChangeNotifierProvider` : menyimpan model di atas widget tree
- `create` : fungsi pembuat objek model
- `context.watch<T>()` : membaca data dan ikut rebuild saat berubah (dipakai di `build()`)
- `context.read<T>()` : membaca sekali tanpa rebuild (dipakai di callback seperti `onPressed`)
- `get` : getter, properti yang nilainya dihitung (`jumlahSelesai`)
- `List.unmodifiable()` : mengembalikan list yang tidak bisa diubah dari luar model

## Widget & Method Lain
- `Checkbox` : kotak centang (`value`, `onChanged`)
- `IconButton` : tombol berbentuk ikon
- `TextDecoration.lineThrough` : mencoret teks
- `Navigator.push()` / `Navigator.pop()` : pindah dan kembali antar halaman
- `where()` : menyaring list berdasarkan kondisi
- `removeWhere()` : menghapus item list yang memenuhi kondisi
- `removeAt()` : menghapus item pada index tertentu
- `actions` (AppBar) : daftar tombol di sisi kanan AppBar

## Troubleshooting
- `Could not find the correct Provider` : pastikan `ChangeNotifierProvider` ada di atas `MaterialApp`
- Tampilan tidak berubah : cek `notifyListeners()` dan pemakaian `context.watch`
- Package provider tidak ditemukan : `flutter pub get` lalu restart aplikasi (bukan hot reload)
- `validate()` tidak bereaksi : pastikan `key: _formKey` terpasang dan memakai `TextFormField`
- Layar tertutup keyboard : gunakan `ListView` atau `SingleChildScrollView` sebagai induk form

## Jawaban Refleksi
- **Kenapa controller harus di-dispose:** agar memori yang dipakai dilepas dan tidak bocor
- **setState vs Provider:** `setState` cukup untuk state satu widget; pakai Provider jika data dipakai banyak halaman
- **Lupa `notifyListeners()`:** data berubah tapi tampilan tidak ikut update, karena widget tidak diberi tahu
- **Kenapa `context.read` di `onPressed`:** callback hanya perlu mengakses model sekali, tidak perlu rebuild