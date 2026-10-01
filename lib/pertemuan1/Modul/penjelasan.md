# Doc Tugas - Pertemuan 1: Pengenalan Flutter

## Perintah Flutter (Terminal)
- `flutter doctor` : cek instalasi Flutter, Android toolchain, dan editor
- `flutter doctor --android-licenses` : menerima lisensi Android SDK
- `flutter create <nama>` : membuat proyek Flutter baru
- `flutter run` : menjalankan aplikasi di emulator/perangkat
- `flutter devices` : melihat daftar perangkat yang terdeteksi
- **Hot Reload** : perubahan kode langsung tampil tanpa restart aplikasi

## Fungsi & Class Dasar
- `main()` : titik masuk program, pertama kali dijalankan
- `runApp()` : menjalankan widget utama sebagai aplikasi
- `MyApp` : widget root aplikasi buatan sendiri
- `build(BuildContext context)` : fungsi yang menyusun dan mengembalikan tampilan widget
- `BuildContext` : posisi widget di dalam widget tree
- `@override` : menandai method yang menimpa method bawaan class induk
- `const` : membuat widget konstan sehingga lebih hemat performa
- `super.key` : meneruskan key widget ke class induk

## Jenis Widget
- `StatelessWidget` : widget yang tampilannya tidak berubah
- `StatefulWidget` : widget yang tampilannya bisa berubah
- `State<T>` : class pasangan StatefulWidget, tempat menyimpan data yang berubah
- `createState()` : membuat objek State untuk StatefulWidget
- `setState()` : memberi tahu Flutter bahwa data berubah sehingga tampilan di-rebuild

## Widget Struktur
- `MaterialApp` : pembungkus aplikasi dengan gaya Material Design (judul, halaman `home`)
- `Scaffold` : kerangka halaman (appBar, body, floatingActionButton)
- `AppBar` : bar judul di bagian atas halaman
- `FloatingActionButton` : tombol bulat melayang, aksinya lewat `onPressed`

## Widget Isi & Layout
- `Text` : menampilkan teks
- `TextStyle` : mengatur gaya teks (`fontSize`, `color`, `fontWeight`)
- `Icon` : menampilkan ikon (`Icons.xxx`), bisa atur `size` dan `color`
- `Center` : menaruh child di tengah
- `Column` : menyusun child vertikal ke bawah
- `children` : daftar widget di dalam Column
- `mainAxisAlignment` : mengatur posisi child sepanjang sumbu utama (misal `center`)
- `SizedBox` : kotak kosong untuk memberi jarak (`height` / `width`)

## Properti Umum
- `title` : judul (di AppBar atau MaterialApp)
- `home` : halaman pertama yang tampil
- `body` : isi utama Scaffold
- `child` : satu widget di dalam widget lain
- `backgroundColor` : warna latar
- `foregroundColor` : warna teks/ikon
- `onPressed` : fungsi yang dijalankan saat tombol ditekan
- `Colors` : kumpulan warna bawaan (`Colors.blue`, dll.)

## Struktur Folder
- `lib/main.dart` : kode utama aplikasi
- `pubspec.yaml` : konfigurasi proyek, dependensi, aset
- `android/`, `ios/` : kode platform native
- `test/` : berkas pengujian

## Widget Tree Praktikum
`MaterialApp` -> `Scaffold` -> `AppBar` + `Center` -> `Column` -> `Icon` / `SizedBox` / `Text`

## Jawaban Refleksi
- **Stateless vs Stateful:** Stateless statis, Stateful bisa berubah lewat `setState()`
- **Kenapa pakai `setState()`:** agar Flutter tahu ada data berubah dan menggambar ulang tampilan
- **Untung hot reload:** perubahan langsung terlihat, tidak perlu rebuild penuh