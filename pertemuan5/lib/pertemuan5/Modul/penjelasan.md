# Doc Tugas - Pertemuan 5: Penyimpanan Lokal (SharedPreferences dan SQLite)

## Konsep Penyimpanan
- **Persistence** : data disimpan di penyimpanan perangkat agar tetap ada setelah aplikasi ditutup
- **Key-value** : untuk pengaturan kecil (tema, nama, hitungan), paket `shared_preferences`
- **Database SQLite** : untuk data terstruktur dan banyak (catatan, transaksi), paket `sqflite` dan `path`
- **Berkas** : untuk dokumen, gambar, ekspor data (`path_provider`, `dart:io`)
- Data di memori (variabel, State) hilang begitu aplikasi ditutup

## SharedPreferences
- `flutter pub add shared_preferences` : memasang paket
- `SharedPreferences.getInstance()` : mengambil objek penyimpanan (asinkron, perlu `await`)
- `getString()` / `getBool()` / `getInt()` : membaca nilai berdasarkan kunci
- `setString()` / `setBool()` / `setInt()` : menyimpan nilai berdasarkan kunci
- `?? ''` : nilai bawaan bila kunci belum ada (`prefs.getString('nama') ?? ''`)
- `mounted` : apakah widget masih terpasang di layar
- `if (!mounted) return;` : dicek setelah setiap `await` sebelum memakai `context` atau `setState`
- `Theme` + `ThemeData(brightness: ...)` : mengganti tema terang/gelap di satu bagian UI
- `Brightness.dark` / `Brightness.light` : mode gelap dan terang
- `SwitchListTile` : saklar dengan label (`value`, `onChanged`)

## SQLite (sqflite)
- `flutter pub add sqflite path` : memasang paket
- `import 'package:path/path.dart' as p` : memuat paket path, `p.join()` menyambung lokasi folder dan nama berkas
- `getDatabasesPath()` : lokasi folder database di perangkat
- `openDatabase()` : membuka (atau membuat) database
- `version` : nomor versi skema database
- `onCreate` : dijalankan sekali saat database pertama kali dibuat
- `onUpgrade` : dijalankan saat `version` dinaikkan, dipakai untuk migrasi skema
- `db.execute()` : menjalankan perintah SQL mentah
- `CREATE TABLE` : membuat tabel
- `INTEGER PRIMARY KEY AUTOINCREMENT` : kolom id yang terisi otomatis dan unik
- `TEXT NOT NULL` : kolom teks yang wajib diisi
- `ALTER TABLE ... ADD COLUMN` : menambah kolom pada tabel yang sudah ada
- `db.rawQuery()` : menjalankan query SQL mentah, contoh `SELECT SUM(jumlah)`

## CRUD
- Create : `INSERT` -> `db.insert()`
- Read : `SELECT` -> `db.query()`
- Update : `UPDATE` -> `db.update()`
- Delete : `DELETE` -> `db.delete()`
- `where: 'id = ?'` + `whereArgs: [id]` : syarat query dengan placeholder `?`, nilainya diisi terpisah
- `orderBy` : mengurutkan hasil (`'id DESC'` terbaru dulu, `'id ASC'` terlama dulu)
- `LIKE ?` + `'%$kata%'` : pencarian teks yang mengandung kata tertentu
- `SUM()` : fungsi SQL penjumlahan, dipakai untuk total pengeluaran
- **SQL injection** : serangan lewat teks pengguna yang disambung ke query, dicegah dengan placeholder `?`

## Model dan Akses Data
- `class Catatan` / `Pengeluaran` : model data satu baris tabel
- `int? id` : id boleh `null` saat objek baru, lalu diisi otomatis oleh SQLite
- `toMap()` : mengubah objek menjadi `Map` untuk disimpan ke database
- `fromMap()` : mengubah `Map` hasil query menjadi objek model
- `Map<String, Object?>` : tipe satu baris data dari database
- `class DbHelper` : kelas pembantu yang mengumpulkan semua operasi database
- `static` : anggota milik class, bisa dipanggil tanpa membuat objek (`DbHelper.semua()`)
- `static Database? _db` + `get database` : membuka database sekali lalu dipakai ulang
- `rows.map(Catatan.fromMap).toList()` : mengubah semua baris hasil query menjadi list objek

## Form dan UI
- `FormCatatanPage(catatan: ...)` : satu halaman form untuk tambah (catatan `null`) dan ubah (catatan terisi)
- `late final TextEditingController` + `TextEditingController(text: ...)` : controller dengan isi awal
- `widget.catatan` : mengakses data yang dikirim ke StatefulWidget
- `await Navigator.push()` lalu `_muat()` : menunggu halaman form ditutup, lalu memuat ulang daftar
- `showDialog<bool>()` + `AlertDialog` : dialog konfirmasi, hasilnya `true`/`false` lewat `Navigator.pop(context, nilai)`
- `TextButton` : tombol teks datar
- `DropdownButtonFormField(value: ...)` : dropdown dengan nilai awal
- `DateTime.now()` : tanggal dan waktu saat ini
- `ValueChanged<bool>` : tipe callback yang membawa satu nilai (dipakai meneruskan pengaturan tema)
- `Expanded` di dalam Column : daftar mengisi sisa layar di bawah kolom pencarian

## Troubleshooting
- `MissingPluginException` : hentikan aplikasi sepenuhnya lalu `flutter run` ulang (hot reload/restart tidak memuat plugin baru)
- Data baru tidak muncul : pastikan `_muat()` dipanggil setelah tambah/ubah/hapus
- `no such table` / `no such column` : skema diubah tanpa menaikkan `version`; saat pengembangan uninstall aplikasi atau Clear data
- Bernilai `null` pada pembacaan awal : pakai nilai bawaan `prefs.getString('x') ?? ''`
- sqflite tidak jalan di web/Windows/Linux : pakai emulator Android
- Peringatan `use_build_context_synchronously` : cek `if (!mounted) return;` setelah `await`

## Jawaban Refleksi
- **Kenapa shared_preferences kurang cocok untuk ratusan catatan:** hanya menyimpan pasangan key-value sederhana, tidak bisa mencari, memfilter, dan mengurutkan data; pilihan lebih baik adalah database SQLite (sqflite)
- **Kenapa pakai placeholder `?` dan `whereArgs`:** nilai dipisah dari perintah SQL sehingga teks dari pengguna tidak bisa menyusup sebagai perintah (mencegah SQL injection)
- **Kenapa daftar dimuat ulang setelah form:** `FutureBuilder` tidak tahu data di database berubah; pada kode ini `await Navigator.push(...)` lalu memanggil `_muat()` yang membuat Future baru lewat `setState`
- **`onCreate` dan `onUpgrade`:** `onCreate` dijalankan sekali saat database pertama dibuat; `onUpgrade` dijalankan saat `version` dinaikkan, untuk mengubah skema (misal menambah kolom). Bila `version` tidak dinaikkan, `onUpgrade` tidak jalan dan kolom baru tidak ada