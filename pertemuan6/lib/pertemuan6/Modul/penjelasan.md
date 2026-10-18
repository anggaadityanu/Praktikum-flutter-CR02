# Doc Tugas - Pertemuan 6: Tema, Routing dan Navigasi, serta Animasi

## Tema
- `ThemeData` : menyimpan seluruh gaya aplikasi (warna, tipografi, gaya komponen)
- `colorSchemeSeed` : satu warna dasar, Material 3 menghasilkan seluruh palet warnanya
- `useMaterial3` : mengaktifkan Material Design 3
- `brightness` : terang atau gelap (`Brightness.light` / `Brightness.dark`)
- `AppBarTheme` : mengatur gaya AppBar untuk seluruh aplikasi (`centerTitle`)
- `theme` / `darkTheme` / `themeMode` : tema terang, tema gelap, dan mode yang dipakai MaterialApp
- `ThemeMode.light` / `dark` / `system` : pilihan mode tema
- `Theme.of(context)` : membaca tema aktif sehingga widget otomatis menyesuaikan
- `textTheme` : gaya teks siap pakai (`titleMedium`, `headlineMedium`, `bodyMedium`, `displayMedium`)
- `colorScheme` : palet warna tema (`primary`, `tertiary`, `error`, `outline`, `secondaryContainer`)
- Keuntungan `Theme.of(context)` : warna konsisten dan otomatis ikut berubah saat tema/mode berganti

## State Tema
- `ValueNotifier<T>` : menyimpan satu nilai dan memberi tahu pendengar saat `.value` berubah
- `ListenableBuilder` : membangun ulang widget saat Listenable berubah
- `Listenable.merge([...])` : menggabungkan beberapa notifier jadi satu
- `ValueListenableBuilder` : membangun ulang widget saat satu ValueNotifier berubah
- `SwitchListTile` : saklar mode gelap
- `Wrap` : menyusun anak berdampingan dan turun baris otomatis bila tidak muat
- `GestureDetector` + `onTap` : mendeteksi ketukan pada widget apa pun
- `WidgetsFlutterBinding.ensureInitialized()` : wajib dipanggil di awal `main()` sebelum memakai plugin
- `void main() async` : `main` asinkron agar bisa `await` memuat preferensi sebelum `runApp()`
- `shared_preferences` : menyimpan mode gelap dan indeks warna agar tetap ada setelah aplikasi ditutup
- `clamp()` : membatasi angka dalam rentang (mencegah indeks di luar daftar)
- `List<Color>` : tipe eksplisit daftar warna agar `indexOf(Color)` valid

## Routing dan Navigasi
- `initialRoute` : rute pertama yang dibuka
- `routes` : peta nama rute ke halaman, contoh `'/': (_) => ShellPage()`
- `Navigator.pushNamed(context, '/detail', arguments: item)` : membuka halaman bernama dan membawa argumen
- `onGenerateRoute` : membuat rute secara dinamis, dipakai untuk rute yang membawa argumen
- `settings.name` / `settings.arguments` : nama rute dan argumen yang dikirim
- `settings.arguments as Item` : mengecek tipe argumen di satu tempat (lebih aman)
- `ModalRoute.of(context)!.settings.arguments` : alternatif membaca argumen di halaman tujuan
- `onUnknownRoute` : halaman cadangan untuk rute yang tidak dikenal ("404 - Halaman tidak ditemukan")
- `Navigator.pop()` : menutup halaman saat ini
- `pushReplacementNamed()` : mengganti halaman saat ini (tidak bisa kembali), misal login ke beranda
- `pushNamedAndRemoveUntil()` : membuka halaman baru sambil menghapus riwayat sebelumnya
- `go_router` : paket routing untuk aplikasi besar (deep link, web), berdasar prinsip named routes

## Hero dan Transisi Halaman
- `Hero` : elemen yang "terbang" mulus antar dua halaman
- `tag` : harus sama di kedua halaman dan unik dalam satu halaman (`'ikon-${item.nama}'`)
- `PageRouteBuilder` : rute dengan transisi buatan sendiri
- `pageBuilder` : fungsi yang mengembalikan halaman tujuan
- `transitionsBuilder` : fungsi yang membungkus halaman dengan animasi transisi
- `transitionDuration` : lama transisi
- `FadeTransition` : transisi memudar (`opacity`)

## Navigasi Tab dan Drawer
- `NavigationBar` : bar navigasi di bawah layar
- `NavigationDestination` : satu tab (`icon`, `selectedIcon`, `label`)
- `selectedIndex` / `onDestinationSelected` : tab aktif dan fungsi saat tab dipilih
- `IndexedStack` : menampilkan satu dari beberapa halaman tanpa membuang state yang lain
- `static const _halaman = [...]` : daftar halaman tab yang konstan
- `Drawer` + `DrawerHeader` : menu geser dari tepi kiri layar
- `Navigator.pop(context)` di Drawer : menutup Drawer setelah memilih menu
- `ShellPage` : halaman induk yang menampung semua tab

## Animasi Implisit
- `AnimatedContainer` : Container yang menganimasikan perubahan ukuran, warna, dan sudut
- `duration` / `curve` : lama animasi dan kurva geraknya (`Curves.easeInOut`)
- `AnimatedSwitcher` : menganimasikan pergantian child
- `transitionBuilder` : efek pergantian (`ScaleTransition`)
- `ValueKey` : kunci agar AnimatedSwitcher tahu child sudah berubah
- `AnimatedOpacity` : memudarkan dan memunculkan widget lewat `opacity`
- `AnimatedScale` : membesar atau mengecil lewat `scale`
- Cukup ubah nilai lewat `setState`, Flutter yang menganimasikan

## Animasi Eksplisit
- `AnimationController` : mengendalikan animasi (jalan, berhenti, ulang)
- `vsync: this` : sinkron dengan refresh layar, butuh `SingleTickerProviderStateMixin`
- `with SingleTickerProviderStateMixin` : penyedia ticker untuk satu controller
- `repeat()` / `stop()` / `forward()` : mengulang, menghentikan, dan menjalankan animasi sekali
- `isAnimating` : apakah animasi sedang berjalan
- `RotationTransition` : memutar widget (`turns`)
- `CurvedAnimation` : memberi kurva gerak pada animasi
- `Tween<Offset>` : rentang nilai awal dan akhir animasi
- `SlideTransition` : menggeser widget lewat `position`
- `dispose()` pada controller : wajib dipanggil saat halaman ditutup

## Widget dan Method Lain
- `class Item` / `Destinasi` : model data dengan nama, `IconData`, dan warna
- `IconData` : tipe data ikon
- `Set<int>` : kumpulan nilai unik tanpa urutan (dipakai untuk id favorit)
- `Chip` : label kecil berbentuk pil
- `SingleChildScrollView` : membuat isi bisa di-scroll
- `where()` : menyaring list (menampilkan hanya yang favorit)
- `Card` + `ListTile` : kartu berisi baris standar

## Troubleshooting
- `Could not find a generator for route` : nama rute salah ketik atau belum ada di `routes` / `onGenerateRoute`
- Hero tidak beranimasi : tag harus sama di kedua halaman dan unik di halaman yang sama
- Tema tidak berubah saat saklar digeser : MaterialApp harus dibungkus `ListenableBuilder` dan nilai diubah lewat `themeMode.value`
- Sebagian warna tidak ikut mode gelap : warna ditulis manual, ganti dengan `Theme.of(context).colorScheme`
- `AnimatedContainer` tidak beranimasi : nilai harus berubah di dalam `setState` dan bertipe sama
- `AnimatedSwitcher` tidak beranimasi : child harus punya `key` yang berbeda tiap perubahan
- Error `vsync` / `TickerProvider` : tambahkan `with SingleTickerProviderStateMixin` pada class State
- Error `Color can't be assigned to MaterialColor` : beri tipe `List<Color>` pada daftar warna

## Jawaban Refleksi
- **Implisit vs eksplisit:** implisit (`AnimatedContainer`, `AnimatedSwitcher`) cukup ubah nilai lewat `setState` dan Flutter yang menganimasikan, cocok untuk kasus sederhana; eksplisit (`AnimationController`) dipakai bila butuh kontrol penuh (ulang, berhenti, urutan, sinkronisasi)
- **Tag Hero harus sama:** agar Flutter tahu kedua widget adalah objek yang sama yang berpindah halaman; bila tag yang sama muncul dua kali di halaman yang sama, Flutter melempar galat karena tag harus unik dalam satu halaman
- **Keuntungan `Theme.of(context)`:** warna dan gaya teks konsisten, otomatis ikut berubah saat mode terang/gelap atau warna tema berganti, tanpa mengubah widget satu per satu
- **IndexedStack vs Navigator:** `IndexedStack` menampilkan satu halaman dan menjaga state semua tab tetap hidup, cocok untuk tab sejajar; `Navigator` menumpuk halaman baru di atas halaman lama, cocok untuk alur masuk lebih dalam lalu kembali
- **Kenapa AnimationController di-dispose:** controller memakai ticker yang terus berjalan; bila tidak dilepas, resource tetap terpakai (kebocoran memori) dan bisa menimbulkan galat setelah halaman ditutup