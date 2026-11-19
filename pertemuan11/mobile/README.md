# TabungKu Cloud: Integrasi Flutter dengan API

Mini proyek Pemrograman Mobile, Pertemuan 11: aplikasi TabungKu kini memakai
data dari server lewat **repository pattern**, lengkap dengan penanganan
galat, target tabungan yang tersimpan di akun, dan mode offline sederhana.

## Identitas

| | |
|---|---|
| Nama | Angga Aditya Nugraha |
| NIM | 20240801165 |
| Program Studi | Teknik Informatika, Universitas Esa Unggul |
| Mata Kuliah | Pemrograman Mobile (CIE511) |
| Tugas | Pertemuan 11: Integrasi Flutter dengan API (Repository Pattern) |

## Apa yang dibangun?

Pada Pertemuan 7 semua halaman memanggil SQLite (`DbHelper`) secara langsung,
dan pada Pertemuan 9 sampai 10 server serta lapisan `KegiatanApi`,
`LaporanApi`, dan login sudah ada tetapi belum dipakai layar. Pertemuan 11
menyambungkan keduanya tanpa menyebarkan detail HTTP ke seluruh tampilan:

- halaman hanya mengenal satu **kontrak abstrak** `KegiatanRepository`,
- dua implementasinya: `ApiKegiatanRepository` (server) dan `SqliteKegiatanRepository` (SQLite pertemuan 7), yang dipilih dengan `--dart-define=MODE_DATA=lokal`,
- setiap halaman menangani tiga keadaan: **memuat**, **galat** (dengan tombol *Coba lagi*), dan **data**, ditambah tarik untuk menyegarkan,
- operasi tulis yang gagal **tidak menutup form** sehingga isian tidak hilang,
- **target tabungan harian** pindah dari HP ke akun di server,
- **mode offline** *network first*: data terakhir yang berhasil dimuat tetap tampil saat server tidak terjangkau, lengkap dengan banner.

```
UI (Hari Ini, Laporan, Form, Cari)
        |  hanya mengenal kontrak
        v
abstract class KegiatanRepository
   /                              \
ApiKegiatanRepository        SqliteKegiatanRepository
 KegiatanApi + LaporanApi         DbHelper (SQLite)
        |
   CacheClient  (cadangan saat offline)
        |
   ApiClient    (header Authorization + pembaruan token otomatis)
        |
     FastAPI
```

## Fitur

### Repository dan penanganan galat (bagian A sampai E)

- Kontrak `KegiatanRepository` dan dua implementasi yang dapat ditukar tanpa mengubah halaman
- Komponen `GalatView` yang dipakai ulang: galat dari server menampilkan pesan server, galat lain dianggap masalah koneksi
- Halaman Hari Ini dan Laporan mengambil dua data sekaligus dengan `Future.wait`; Laporan kini cukup **2 request** (dulu 9 query SQLite)
- Tarik untuk menyegarkan (`RefreshIndicator`) di Hari Ini dan Laporan
- Operasi tulis (centang, hapus, simpan) yang gagal menampilkan SnackBar; form tetap terbuka, dan tombol Simpan tidak bisa ditekan dua kali
- `versiData` hanya dinaikkan **setelah** server menjawab berhasil

### Latihan mandiri

1. Garis progres tipis di atas daftar saat data **dimuat ulang**
2. *Optimistic update* pada centang (tampilan berubah dulu, dikembalikan bila server menolak)
3. Tombol ukur waktu di Laporan: membandingkan dua request berurutan dengan `Future.wait`
4. Kolom cari judul di Hari Ini yang mengirim parameter `q` ke server

### Tugas

- **(a) Target tabungan di server.** `PATCH /users/me` di backend; slider Pengaturan menyimpan ke server (dikembalikan bila gagal); `targetHarian` mengikuti akun yang login, jadi dua akun di satu HP punya target sendiri
- **(b) Mode offline *network first*.** `CacheStore` (SQLite dan memori), `CacheClient` yang membungkus `ApiClient`, kunci cache yang memuat id pengguna, cache dihapus saat keluar, dan banner "Offline" di atas halaman utama

## Endpoint baru

| Metode | Alamat | Fungsi | Kode |
|---|---|---|---|
| PATCH | `/users/me` | Ubah `nama` dan/atau `target_harian` (0 sampai 10.000.000); nilai `null` dianggap tidak dikirim | 200, 401, 422 |

Endpoint lain tidak berubah dari Pertemuan 10.

## Sintaks yang Digunakan

### 1. Kontrak repository dan pemilihan sumber data

```dart
const modeData = String.fromEnvironment('MODE_DATA', defaultValue: 'api');

abstract class KegiatanRepository {
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''});
  Future<Ringkasan> ringkasan(String tanggal);
  Future<LaporanHarian> laporanHarian(String tanggal);
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai);
  Future<void> tambah(Kegiatan k);
  Future<void> setSelesai(Kegiatan k, bool selesai);
  Future<void> hapus(int id);
  // ...
}

KegiatanRepository repo = modeData == 'lokal'
    ? SqliteKegiatanRepository()
    : ApiKegiatanRepository();
```

- `abstract class` menetapkan daftar pekerjaan tanpa isinya; kelas yang `implements` wajib mengisi semuanya, dan `flutter analyze` memberi galat bila ada yang terlewat.
- Halaman hanya memanggil `repo`, tidak tahu apakah di baliknya SQLite atau HTTP (*polimorfisme*).
- `String.fromEnvironment` membaca nilai dari `flutter run --dart-define=MODE_DATA=lokal`, sehingga sumber data bisa ditukar tanpa mengubah kode.
- `repo` adalah variabel biasa, jadi test bisa menggantinya dengan repository palsu.

### 2. Dua implementasi dan `versiData`

```dart
class ApiKegiatanRepository implements KegiatanRepository {
  final KegiatanApi _kegiatan;
  final LaporanApi _laporan;

  ApiKegiatanRepository({KegiatanApi? kegiatan, LaporanApi? laporan})
      : _kegiatan = kegiatan ?? KegiatanApi(),
        _laporan = laporan ?? LaporanApi();

  @override
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai) =>
      _laporan.rentang(kunciTanggal(mulai), kunciTanggal(sampai));

  @override
  Future<void> tambah(Kegiatan k) async {
    await _kegiatan.tambah(k);
    versiData.value++;
  }
}
```

- Konstruktor menerima `KegiatanApi` dan `LaporanApi` opsional (*dependency injection*) agar bisa diuji dengan `MockClient`.
- API memakai **satu request** `/laporan/rentang` untuk 7 hari, sedangkan `SqliteKegiatanRepository` menjalankan satu query per hari.
- `versiData` adalah `ValueNotifier<int>`; halaman mendengarkannya dan memuat ulang data. Kenaikannya diletakkan **setelah** `await` berhasil, sehingga bila server menolak, pengecualian dilempar lebih dulu dan tampilan tidak dimuat ulang tanpa alasan.

### 3. Tiga keadaan data jaringan

```dart
FutureBuilder<DataHari>(
  future: _future,
  builder: (context, snapshot) {
    final belumSelesai = snapshot.connectionState != ConnectionState.done;
    if (belumSelesai && !snapshot.hasData) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: GalatView(galat: snapshot.error!, onCobaLagi: _muat),
      );
    }
    final data = snapshot.data!;
    // ... tampilkan data
  },
)
```

- Pola tiga keadaan: **memuat**, **galat**, dan **data**.
- `FutureBuilder` mempertahankan data lama selama `Future` baru berjalan, jadi memuat pertama kali (belum ada data, lingkaran penuh) dapat dibedakan dari memuat ulang (data ada tetapi belum selesai).
- Syarat `belumSelesai && !hasData` didahulukan agar tombol *Coba lagi* langsung memberi umpan balik: yang tampil adalah lingkaran, bukan galat lama yang masih tersimpan di snapshot.
- `GalatView` menerima `Object galat`: bila `ApiException`, pesan server ditampilkan; selain itu dianggap masalah koneksi.

### 4. `Future.wait` dan tarik untuk menyegarkan

```dart
Future<DataHari> _ambil() async {
  final tanggal = kunciTanggal(DateTime.now());
  final hasil = await Future.wait([
    repo.pada(tanggal, q: _kata),
    repo.ringkasan(tanggal),
  ]);
  return DataHari(hasil[0] as List<Kegiatan>, hasil[1] as Ringkasan);
}

Future<void> _tarikSegarkan() async {
  _muat();
  try {
    await _future;
  } catch (_) {}
}

RefreshIndicator(
  onRefresh: _tarikSegarkan,
  child: CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [...],
  ),
)
```

- `Future.wait` mengirim dua request yang tidak saling bergantung **bersamaan**; waktu tunggunya sekitar waktu yang terlama, bukan jumlah keduanya.
- Hasilnya bertipe `List<Object>`, jadi tiap elemen harus di-*cast* (`as`).
- `RefreshIndicator` menampilkan indikator selama `Future` yang dikembalikan `onRefresh` belum selesai, sehingga `_tarikSegarkan` menunggu `_future`.
- `AlwaysScrollableScrollPhysics` membuat layar tetap bisa ditarik walau isinya sedikit.

### 5. Operasi tulis yang aman

```dart
Future<void> _jalankan(Future<void> Function() aksi) async {
  try {
    await aksi();
  } catch (e) {
    if (mounted) tampilkanGalat(context, e);
  }
}

// Form: tetap terbuka bila gagal
setState(() => _menyimpan = true);
try {
  if (_modeUbah) {
    await repo.ubah(k);
  } else {
    await repo.tambah(k);
  }
  if (!mounted) return;
  Navigator.pop(context, true);
} catch (e) {
  if (mounted) tampilkanGalat(context, e);
} finally {
  if (mounted) setState(() => _menyimpan = false);
}
```

- `Future<void> Function() aksi` adalah parameter berupa fungsi, sehingga satu pembungkus bisa dipakai untuk centang dan hapus.
- `if (mounted)` dicek setiap kali sebelum memakai `context` atau `setState` setelah `await`, karena halaman bisa saja sudah ditutup.
- `finally` selalu mengembalikan tombol Simpan, baik berhasil maupun gagal. Selama `_menyimpan` bernilai `true`, tombol dinonaktifkan agar tidak terkirim dua kali (akibatnya bisa data ganda bila jaringan lambat).
- `Navigator.pop` hanya dipanggil saat berhasil, sehingga isian tidak hilang ketika gagal.

### 6. Latihan: progres tipis, *optimistic update*, pencarian, dan Stopwatch

```dart
// Latihan 1: tinggi 3 piksel selalu dicadangkan agar tampilan tidak bergeser
SizedBox(
  height: 3,
  child: memuatUlang ? const LinearProgressIndicator(minHeight: 3) : null,
)

// Latihan 2: nilai sementara menimpa data server sampai server menjawab
Future<void> _centang(Kegiatan k, bool nilai) async {
  setState(() => _optimis[k.id!] = nilai);
  try {
    await repo.setSelesai(k, nilai);
  } catch (e) {
    if (!mounted) return;
    setState(() => _optimis.remove(k.id!));
    tampilkanGalat(context, e);
  }
}

// Latihan 4: menunggu pengguna berhenti mengetik
void _ketik(String nilai) {
  _tunda?.cancel();
  _tunda = Timer(const Duration(milliseconds: 400), () {
    _kata = nilai.trim();
    _muat();
  });
}

// Latihan 3: dua cara memuat Laporan, diukur dengan Stopwatch
final jam = Stopwatch()..start();
await Future.wait([r.laporanHarian(tanggal), r.rentang(awal, basis)]);
jam.stop();
```

- Garis tipis hanya tampil saat memuat **ulang** (`belumSelesai` tetapi data lama masih ada).
- *Optimistic update*: `_optimis` adalah `Map<int, bool>` (id kegiatan ke nilai selesai). Tampilan memakai nilai itu lebih dulu; bila server menolak, entri dibuang sehingga tampilan kembali. Entri juga dibuang otomatis begitu data server sudah sama.
- *Debounce*: tiap ketikan membatalkan `Timer` sebelumnya dan memulai yang baru, jadi request hanya dikirim setelah pengguna berhenti mengetik 400 ms, bukan satu per huruf.
- `Stopwatch` mengukur waktu; satu pemanasan dilakukan lebih dulu supaya biaya membuka koneksi tidak ikut terhitung, lalu diambil rata-rata beberapa kali.

### 7. Tugas (a): target tabungan di server

```python
class UserUpdate(BaseModel):
    nama: str | None = Field(default=None, min_length=1, max_length=100)
    target_harian: int | None = Field(default=None, ge=0, le=10_000_000)

@router.patch("/users/me", response_model=UserOut)
def ubah_profil(data: UserUpdate, db: DbSession, user: UserAktif):
    for kolom, nilai in data.model_dump(exclude_none=True).items():
        setattr(user, kolom, nilai)
    db.commit()
    db.refresh(user)
    return user
```

```dart
Future<Pengguna> ubahTarget(int target) async {
  final res = await _klienToken
      .patch(_uri('/users/me'), headers: _json,
          body: jsonEncode({'target_harian': target}))
      .timeout(batasWaktu);
  if (res.statusCode != 200) throw ApiException.dariRespons(res);
  final p = Pengguna.fromJson(_objek(res));
  await simpanProfil(p);
  return p;
}

void ikutiTargetPengguna() {
  void sinkron() {
    final p = pengguna.value;
    if (p != null) targetHarian.value = p.targetHarian;
  }
  pengguna.addListener(sinkron);
  sinkron();
}
```

- `Field(ge=0, le=10_000_000)` membatasi nilai di server; di luar rentang dibalas 422.
- `exclude_none=True` membuat nilai `null` dianggap tidak dikirim, sehingga kolom `NOT NULL` tidak pernah diisi `None`.
- `PATCH` hanya mengubah field yang dikirim, jadi mengubah nama tidak menyentuh target, dan sebaliknya.
- `ubahTarget` memakai `ApiClient` (dua *client* di `AuthApi`: biasa untuk login/refresh, `ApiClient` untuk yang butuh token), sehingga token kedaluwarsa diperbarui otomatis.
- `ikutiTargetPengguna` memasang pendengar pada `pengguna`: login, ganti akun, dan perubahan profil otomatis menyelaraskan `targetHarian`. Di mode lokal pendengar ini tidak dipasang dan target tetap di HP.
- Bila gagal, slider dikembalikan ke `targetHarian.value` dan SnackBar tampil.

### 8. Tugas (b): `CacheClient` (*network first*)

```dart
class CacheClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final idPengguna = pengguna.value?.id;
    if (request.method != 'GET' || idPengguna == null) {
      return _inner.send(request);
    }
    final kunci = '$idPengguna|${request.url}';

    http.StreamedResponse res;
    try {
      res = await _inner.send(request).timeout(_batas);
    } catch (e) {
      if (!_galatJaringan(e)) rethrow;
      final entri = await _penyimpan.baca(kunci);
      if (entri == null) rethrow;
      statusOffline.value = entri.waktu;
      final bytes = utf8.encode(entri.isi);
      return http.StreamedResponse(Stream.value(bytes), 200, ...);
    }

    if (res.statusCode != 200) return res;
    final bytes = await res.stream.toBytes();
    await _penyimpan.simpan(kunci, utf8.decode(bytes), DateTime.now());
    statusOffline.value = null;
    return http.StreamedResponse(Stream.value(bytes), 200, ...);
  }

  bool _galatJaringan(Object e) =>
      e is IOException || e is TimeoutException || e is http.ClientException;
}
```

- `extends http.BaseClient` dengan method `send` adalah pola *decorator*: membungkus `ApiClient` dan menambah perilaku cadangan tanpa mengubah `KegiatanApi` atau `LaporanApi` selain *client* bawaannya.
- *Network first*: server dicoba lebih dulu; cache hanya dipakai bila jaringan gagal (galat I/O, koneksi, atau waktu habis 8 detik).
- Hanya **GET berstatus 200** yang disimpan; POST, PUT, PATCH, DELETE diteruskan apa adanya sehingga operasi tulis tidak pernah "berhasil" dari cache. Jawaban 401 atau 500 juga tidak disimpan.
- Galat yang bukan galat jaringan (misalnya `ArgumentError` karena bug) dilempar lagi (`rethrow`) supaya bug tidak tersembunyi oleh cache.
- Isi respons dibaca penuh (`stream.toBytes()`) karena `StreamedResponse` hanya bisa dibaca sekali; sesudah disimpan, respons baru dibuat dari bytes yang sama.
- Kunci cache `idPengguna|URL` mencegah akun yang berbeda di satu HP saling melihat data.
- `statusOffline` (`ValueNotifier<DateTime?>`) berisi waktu data cache saat offline dan `null` saat online; `ShellPage` mendengarkannya dengan `ValueListenableBuilder` untuk menampilkan banner.
- `hapusSesi()` mengosongkan cache dan `statusOffline`; kegagalan membersihkan cache dibungkus `try/catch` agar tidak menggagalkan proses keluar.

### 9. Cache di SQLite

```dart
await db.insert(
  'cache',
  {'kunci': kunci, 'isi': isi, 'waktu': waktu.toIso8601String()},
  conflictAlgorithm: ConflictAlgorithm.replace,
);

CREATE TABLE cache (
  kunci TEXT PRIMARY KEY,
  isi TEXT NOT NULL,
  waktu TEXT NOT NULL
)
```

- `CacheStore` adalah kelas abstrak dengan dua implementasi: `SqliteCacheStore` (berkas `tabungku_cache.db`, terpisah dari database kegiatan lokal) dan `MemoryCacheStore` untuk test yang tidak butuh plugin.
- `ConflictAlgorithm.replace` menimpa entri lama dengan kunci yang sama, jadi cache selalu berisi data terbaru yang berhasil dimuat.
- Waktu disimpan sebagai teks ISO 8601 (`toIso8601String`) dan dibaca kembali dengan `DateTime.parse`.

### 10. Pengujian

```dart
class FakeRepository implements KegiatanRepository {
  List<Kegiatan> daftar = [];
  Object? galat;
  int jumlahPanggil = 0;

  @override
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''}) async {
    jumlahPanggil++;
    if (galat != null) throw galat!;
    return daftar;
  }
  // ...
}

testWidgets('galat -> tombol Coba lagi -> data tampil', (tester) async {
  final fake = FakeRepository()..galat = Exception('server mati');
  repo = fake;
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  expect(find.text('Coba lagi'), findsOneWidget);

  fake.galat = null;
  await tester.tap(find.text('Coba lagi'));
  await tester.pumpAndSettle();
  expect(find.textContaining('Belum ada kegiatan'), findsOneWidget);
});
```

- `FakeRepository` adalah repository palsu: isi, galat, dan hitungan panggilannya bisa diatur test, sehingga halaman diuji **tanpa server dan tanpa database**.
- `testWidgets` merender widget; `pumpAndSettle` menunggu semua animasi dan `Future` selesai sebelum memeriksa layar.
- `find.descendant(of: ..., matching: ...)` membatasi pencarian pada satu bagian layar bila teks yang sama muncul di beberapa tempat.
- `Completer` dipakai pada repository palsu untuk **menahan** jawaban, sehingga keadaan di tengah proses (sedang memuat ulang, menunggu server) dapat diperiksa.
- `MockClient` menguji lapisan HTTP: tes memeriksa permintaan yang dikirim (metode, jalur, query, isi) dan efek sampingnya, misalnya `versiData` naik hanya saat berhasil.
- Untuk `CacheClient`, server palsu dapat dimatikan, diperlambat, atau diganti jawabannya, sehingga setiap skenario offline dapat diulang.

## Hasil Uji

### `PATCH /users/me` (tugas a, backend)

| No | Skenario | Hasil yang diharapkan | Hasil |
|----|----------|-----------------------|-------|
| 1 | Ubah `target_harian` menjadi 35000 | 200, target 35000 | [Lulus] |
| 2 | Baca profil lagi | target 35000 tersimpan | [Lulus] |
| 3 | Ubah `nama` saja | 200, target tetap 35000 | [Lulus] |
| 4 | `nama` hanya spasi | 422 | [Lulus] |
| 5 | Body kosong `{}` | 200, tidak ada perubahan | [Lulus] |
| 6 | `target_harian` 0 (batas bawah) | 200 | [Lulus] |
| 7 | `target_harian` 10000000 (batas atas) | 200 | [Lulus] |
| 8 | `target_harian` 10000001 | 422 | [Lulus] |
| 9 | `target_harian` -1 | 422 | [Lulus] |
| 10 | Tanpa token | 401 | [Lulus] |

### Aplikasi di emulator (checkpoint E)

| No | Skenario | Hasil yang diharapkan | Hasil |
|----|----------|-----------------------|-------|
| 1 | Login, tambah beberapa kegiatan | Tampil di Hari Ini beserta ringkasannya | [Lulus] |
| 2 | Periksa tabel `kegiatan` di Adminer | Data tersimpan dengan `user_id` yang benar | [Lulus] |
| 3 | Login dengan akun lain di HP yang sama | Daftar Hari Ini kosong | [Lulus] |
| 4 | Tarik layar Hari Ini ke bawah | Indikator berputar, data diperbarui | [Lulus] |
| 5 | `docker compose stop api`, lalu tarik layar | Tampilan galat dengan tombol Coba lagi | [Lulus] |
| 6 | Server mati, simpan form | SnackBar galat, form tetap terbuka | [Lulus] |
| 7 | `docker compose start api`, tekan Coba lagi | Data kembali tampil | [Lulus] |
| 8 | Buka tab Laporan | Ringkasan, kategori, dan 7 hari tampil | [Lulus] |
| 9 | Jalankan dengan `MODE_DATA=lokal` | Aplikasi memakai SQLite tanpa mengubah kode halaman | [Lulus] |

### Target tabungan di server (tugas a, aplikasi)

| No | Skenario | Hasil yang diharapkan | Hasil |
|----|----------|-----------------------|-------|
| 1 | Geser slider ke Rp 50.000 | Tersimpan di `users.target_harian` | [Lulus] |
| 2 | Lihat kartu ringkasan Hari Ini | Target Rp 50.000 | [Lulus] |
| 3 | Tutup lalu buka aplikasi | Slider tetap Rp 50.000 | [Lulus] |
| 4 | Keluar, login akun lain | Target akun itu sendiri (bukan 50.000) | [Lulus] |
| 5 | Server mati, geser slider | Slider dikembalikan, SnackBar galat | [Lulus] |
| 6 | Mode lokal | Target tersimpan di HP seperti pertemuan 7 | [Lulus] |

### Mode offline (tugas b)

| No | Skenario | Hasil yang diharapkan | Hasil |
|----|----------|-----------------------|-------|
| 1 | Muat Hari Ini dan Laporan saat online | Data tampil, tanpa banner | [Lulus] |
| 2 | Matikan server, tarik layar Hari Ini | Data tetap tampil, banner Offline dengan jam | [Lulus] |
| 3 | Buka Laporan saat offline | Laporan tetap tampil, banner sama | [Lulus] |
| 4 | Simpan form saat offline | SnackBar galat, form tetap terbuka | [Lulus] |
| 5 | Buka tanggal yang belum pernah dimuat | Tampilan galat (tidak ada cache) | [Lulus] |
| 6 | Nyalakan server, tarik layar | Data diperbarui, banner hilang | [Lulus] |

### Unit dan widget test

Hasil `flutter test`: [isi jumlah] tes lulus. Cakupannya:

- `repository_test.dart`: halaman Hari Ini dengan `FakeRepository` (galat lalu Coba lagi, daftar tampil, hapus memicu muat ulang, centang, gagal centang), `GalatView`, dan `ApiKegiatanRepository` (`versiData` naik hanya saat berhasil, `rentang` satu request, `cari`, `ringkasan`)
- `latihan_test.dart`: garis progres tipis, *optimistic update* (berhasil dan dikembalikan), `Future.wait` lebih cepat dari berurutan, dan pencarian dengan jeda ketik
- `target_server_test.dart`: `ubahTarget` (berhasil, token kedaluwarsa, ditolak 422, server mati) dan `targetHarian` yang mengikuti pengguna
- `cache_client_test.dart`: online menyimpan, offline memakai cache, offline tanpa cache melempar galat, timeout, POST tidak di-cache, akun lain tidak memakai cache, keluar menghapus cache, dan banner di `ShellPage`
- tes lama dari Pertemuan 8 sampai 10 tetap berjalan

## Jawaban Latihan Mandiri

**1. Garis progres tipis saat memuat ulang.** `FutureBuilder` mempertahankan data lama selama `Future` baru berjalan, sehingga memuat pertama kali (belum ada data, lingkaran penuh) bisa dibedakan dari memuat ulang (data ada, `connectionState` belum selesai, garis tipis di atas daftar). Tingginya selalu dicadangkan 3 piksel agar tampilan tidak bergeser saat garis muncul dan hilang.

**2. *Optimistic update* pada centang.** Tampilan memakai nilai sementara (`_optimis`) yang menimpa data server, lalu `PATCH` dikirim. Bila server menolak, nilai sementara dibuang sehingga tampilan kembali dan galat ditampilkan. Imbalannya: terasa instan, tetapi harus ada jalur pengembalian dan pemberitahuan ke pengguna.

**3. Waktu muat Laporan dengan dan tanpa `Future.wait`.** Dua request berurutan butuh sekitar **jumlah** waktunya, sedangkan `Future.wait` butuh sekitar waktu **yang terlama**. Hasil pengukuran (rata-rata beberapa kali, setelah satu pemanasan):

**4. Pencarian judul di Hari Ini.** Kolom cari mengirim parameter `q` ke server (`GET /kegiatan?tanggal=...&q=...`) setelah pengguna berhenti mengetik 400 ms (*debounce*), supaya tidak ada satu request per huruf. Hasil kosong menampilkan pesan khusus pencarian, dan kartu ringkasan tetap menghitung seluruh kegiatan hari itu.

## Jawaban Pertanyaan Refleksi

1. **Bila backend diganti (misalnya ke Firebase), bagian mana yang berubah?** Cukup lapisan data: dibuat `FirebaseKegiatanRepository implements KegiatanRepository`, lalu inisialisasi `repo` diarahkan ke sana. Halaman tidak berubah karena hanya mengenal kontrak abstrak. `KegiatanApi`, `LaporanApi`, dan `ApiClient` tidak lagi dipakai untuk data (autentikasi ikut berganti bila login juga pindah ke Firebase).
2. **Kenapa `versiData` dinaikkan setelah request berhasil?** Bila dinaikkan sebelum atau tanpa mengecek hasil, halaman memuat ulang data yang sebenarnya tidak berubah, atau menampilkan perubahan yang sebenarnya ditolak server. Dengan menaikkannya setelah `await` sukses, pengecualian saat gagal dilempar lebih dulu dan tampilan tetap sesuai keadaan server.
3. **Risiko bila tombol Simpan bisa ditekan dua kali saat jaringan lambat.** Dua permintaan `POST` terkirim sehingga terbentuk **data ganda**. Karena itu tombol dinonaktifkan selama `_menyimpan` bernilai `true`, dan dikembalikan di blok `finally`.
4. **Kapan data *network first* bisa usang, dan bagaimana pengguna tahu?** Data cache usang bila ada perubahan di server (misalnya dari perangkat lain) sejak data itu disimpan, dan selama offline pengguna tidak melihatnya. Pengguna tahu lewat banner "Offline: menampilkan data tersimpan (terakhir diperbarui pukul HH:mm)", yang menyebut kapan data itu terakhir berhasil dimuat.
5. **Kenapa cache dihapus saat pengguna keluar?** Cache berisi data pribadi pengguna. Bila tidak dihapus, data itu tertinggal di perangkat setelah keluar dan bisa terbaca orang lain yang memakai HP itu. Kunci cache yang memuat id pengguna menjadi lapisan pengaman tambahan agar akun lain tidak melihat data akun sebelumnya.

## Cara Menjalankan

**Backend** (di folder `pertemuan11`, Docker Desktop harus menyala):

```
cp .env.example .env
```

Isi `JWT_SECRET` di `.env` dengan kunci acak (misalnya hasil
`python3 -c "import secrets; print(secrets.token_hex(32))"`). Berkas `.env`
**tidak** ikut ke GitHub. Lalu:

```
docker compose up -d --build
docker compose ps
```

| Alamat | Isi |
|---|---|
| `http://localhost:8000/docs` | Swagger |
| `http://localhost:8000/health` | Status API dan database |
| `http://localhost:8081` | Adminer |

**Aplikasi Flutter** (di folder `pertemuan11/mobile`, emulator dan server menyala):

```
flutter pub get
flutter test
flutter run -d emulator-5554
```

| Mode | Perintah |
|---|---|
| Server (bawaan) | `flutter run -d emulator-5554` |
| SQLite lokal | `flutter run -d emulator-5554 --dart-define=MODE_DATA=lokal` |

Emulator mengakses server lewat `http://10.0.2.2:8000` (alamat bawaan, bisa
diubah di Pengaturan).

## Struktur Folder

```
pertemuan11/
  docker-compose.yml         MySQL + API + Adminer
  .env.example               contoh variabel lingkungan (.env tidak di-commit)
  backend/
    app/
      routers/auth.py        ditambah PATCH /users/me
      schemas.py             ditambah UserUpdate
      ...                    (lainnya sama seperti pertemuan 10)
  mobile/
    lib/
      data/
        kegiatan_repository.dart         kontrak, versiData, dan repo
        api_kegiatan_repository.dart     implementasi server
        sqlite_kegiatan_repository.dart  implementasi SQLite
        db_helper.dart                   akses SQLite (hanya dipakai repository)
      services/
        kegiatan_api.dart, laporan_api.dart, auth_api.dart
        api_client.dart                  header Authorization + pembaruan token
        cache_client.dart                cadangan saat offline (network first)
        cache_store.dart                 cache SQLite dan memori, statusOffline
      widgets/galat_view.dart            tampilan galat + tombol Coba lagi
      pages/                             beranda, laporan, form, cari, pengaturan, shell
      utils/ukur_waktu.dart              pengukur waktu muat (Latihan 3)
    test/                    unit dan widget test (FakeRepository, MockClient)
  Docs/
    readme.md                berkas ini
```