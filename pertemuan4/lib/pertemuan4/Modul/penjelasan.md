# Doc Tugas - Pertemuan 4: Mengambil Data dari REST API (HTTP, Async, dan FutureBuilder)

## Asinkron di Dart
- `Future<T>` : objek yang berisi hasil yang baru tersedia nanti (misal data dari internet)
- `async` : menandai fungsi sebagai asinkron, otomatis mengembalikan Future
- `await` : menunggu hasil Future tanpa memblokir UI, hanya boleh dipakai di dalam fungsi `async`
- `Future.delayed()` : mensimulasikan proses yang butuh waktu (dipakai di `ambilSalam()`)
- `Duration` : durasi waktu, contoh `Duration(seconds: 2)`
- `late` : variabel yang diisi nanti, tapi sebelum dipakai (`late Future<String> _future`)
- `initState()` : dipanggil sekali saat State dibuat, tempat yang tepat untuk membuat Future
- `catchError()` : menangkap galat pada Future agar tidak dilempar ke atas (dipakai di `_muatUlang` pada RefreshIndicator)

## FutureBuilder
- `FutureBuilder<T>` : widget yang membangun UI berdasarkan status sebuah Future
- `future` : Future yang dipantau oleh FutureBuilder
- `builder` : fungsi pembuat UI, menerima `context` dan `snapshot`
- `snapshot` : berisi status (`connectionState`), data (`data`), dan galat (`error`)
- `ConnectionState.waiting` : Future masih berjalan, saatnya menampilkan loading
- `snapshot.hasError` / `snapshot.error` : apakah Future gagal, dan isi galatnya
- `snapshot.hasData` / `snapshot.data` : apakah data sudah ada, dan isinya (`snapshot.data!` bila pasti ada)
- `CircularProgressIndicator` : indikator loading berputar
- Tiga keadaan yang wajib ditangani : loading, galat (dengan tombol "Coba lagi"), dan data

## HTTP dan JSON
- `flutter pub add http` : memasang paket http
- `import 'package:http/http.dart' as http` : memuat paket http dengan alias `http`
- `import 'dart:convert'` : library bawaan Dart yang berisi `jsonDecode`
- `Uri.parse()` : mengubah teks URL menjadi objek `Uri`
- `http.get(uri)` : mengirim permintaan GET, mengembalikan `Future<Response>`
- `.timeout()` : batas waktu tunggu respons, melempar galat bila terlampaui
- `response.statusCode` : kode status HTTP (200 sukses, 404 tidak ditemukan, 500 galat server)
- `response.body` : isi respons berupa teks JSON
- `jsonDecode()` : mengubah teks JSON menjadi `Map` atau `List` Dart
- `throw Exception()` : melempar galat agar ditangkap oleh `snapshot.error`
- `android.permission.INTERNET` : izin internet di `AndroidManifest.xml` agar build release bisa mengakses jaringan
- Endpoint JSONPlaceholder : `/users` (praktikum), `/posts` dan `/posts/{id}/comments` (tugas)

## Model Data
- `class Pengguna` / `Post` / `Komentar` : model yang membungkus data hasil JSON
- `final` : properti yang tidak bisa diubah setelah objek dibuat
- `required` : parameter constructor yang wajib diisi
- `factory Pengguna.fromJson()` : constructor factory yang mengubah `Map` menjadi objek model
- `Map<String, dynamic>` : tipe hasil `jsonDecode` untuk satu objek JSON
- `json['name'] as String` : mengambil nilai berdasarkan kunci sekaligus memastikan tipenya
- `json['address']['city']` : mengambil data bersarang (objek di dalam objek)
- `List<dynamic>` : tipe hasil `jsonDecode` untuk array JSON
- `.map((e) => Pengguna.fromJson(e)).toList()` : mengubah setiap item JSON menjadi objek model

## Widget dan Method Lain
- `RefreshIndicator` + `onRefresh` : tarik ke bawah untuk memuat ulang data (harus mengembalikan Future)
- `IconButton` + `Icons.refresh` : tombol muat ulang di `actions` AppBar
- `Icons.error_outline` : ikon tanda galat
- `maxLines` + `TextOverflow.ellipsis` : membatasi baris teks dan memotongnya dengan titik-titik
- `isThreeLine` : memberi ruang tiga baris pada `ListTile`
- `Divider` : garis pemisah
- `mainAxisSize: MainAxisSize.min` : Column hanya setinggi isinya
- `textAlign: TextAlign.center` : meratakan teks ke tengah
- `SizedBox.shrink()` : widget kosong tanpa ukuran
- `data.isEmpty` : mengecek daftar kosong untuk menampilkan "Tidak ada data"
- `widget.post` : mengakses properti StatefulWidget dari dalam class State

## Pola Kode
- Pemisahan : model (class), layanan (fungsi `ambilXxx()`), dan UI (widget halaman)
- Future dibuat di `initState()`, bukan di `build()`
- `_muatUlang()` : mengisi `_future` dengan Future baru di dalam `setState`
- Dua Future terpisah : daftar postingan dan komentar (`ambilKomentar(postId)`)
- Kirim data ke halaman detail lewat constructor, contoh `DetailPostinganPage(post: post)`

## Percobaan Galat (Bagian F)
- URL diubah ke `/userz` : muncul galat kode 404 dan tombol "Coba lagi"
- Internet dimatikan lalu refresh : muncul galat jaringan (`SocketException: Failed host lookup`)
- Setelah URL/internet dikembalikan, tombol "Coba lagi" memuat ulang data

## Troubleshooting
- `SocketException` / `Failed host lookup` : periksa koneksi internet emulator, pastikan izin INTERNET ada
- Package http tidak ditemukan : `flutter pub get` lalu restart aplikasi (bukan hot reload)
- Data dimuat ulang setiap layar berubah : pindahkan pembuatan Future ke `initState()`
- `type 'Null' is not a subtype` : nama kunci JSON salah atau bernilai null, cek respons asli di browser
- API publik lambat atau tidak tersedia : tunggu lebih lama atau coba lagi nanti

## Jawaban Refleksi
- **Future dibuat di `build()`:** setiap kali layar dibangun ulang, permintaan ke internet diulang dan loading muncul terus; `initState()` hanya berjalan sekali
- **`snapshot.hasError` vs `statusCode`:** `statusCode` mengecek respons server (404/500) setelah permintaan sampai; `hasError` menangkap semua galat, termasuk jaringan putus dan `Exception` yang kita lempar. Keduanya diperlukan karena kegagalan bisa terjadi sebelum atau sesudah server merespons
- **JSON jadi class model:** tipe data jelas dan aman, kesalahan nama kunci ketahuan di satu tempat (`fromJson`), kode UI lebih rapi dan ada autocomplete
- **Wajib ada status loading dan error:** jaringan tidak instan dan bisa gagal; tanpa keduanya layar tampak kosong atau macet dan pengguna tidak tahu apa yang terjadi