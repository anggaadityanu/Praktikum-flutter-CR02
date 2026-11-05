# TabungKu Cloud: Kerangka Backend

Mini proyek Pemrograman Mobile, Pertemuan 8: Docker Compose, MySQL, dan API
pertama dengan FastAPI, lalu aplikasi Flutter memeriksa status server.

## Identitas

| | |
|---|---|
| Nama | Angga Aditya Nugraha |
| NIM | 20240801165 |
| Program Studi | Teknik Informatika, Universitas Esa Unggul |
| Mata Kuliah | Pemrograman Mobile (CIE511) |
| Tugas | Pertemuan 8: Docker Compose dan Kerangka Backend TabungKu Cloud |

## Apa itu TabungKu Cloud?

Pada Pertemuan 7, TabungKu menyimpan semua data di SQLite di dalam HP. Cara itu
sederhana, tetapi data hilang bila HP rusak dan tidak bisa dibuka dari
perangkat lain. **TabungKu Cloud** memindahkan data ke server, sehingga
aplikasi terdiri atas tiga bagian yang berbagi satu database:

```
+--------------+   HTTP/JSON    +---------------+      +-----------+
| Flutter app  | -------------> | FastAPI :8000 | ---> | MySQL 8.4 |
+--------------+                +---------------+      +-----------+
                                                             ^
+--------------+   browser                                   |
| Adminer      | --------------------------------------------+
| :8081        |
+--------------+
        semua layanan server dijalankan dengan docker-compose.yml
```

Pertemuan 8 baru membangun **kerangkanya**: server dapat dijalankan dengan satu
perintah, API dapat dihubungi, dan aplikasi Flutter dapat memeriksa apakah API
dan database dalam keadaan sehat. Fitur pencatatan kegiatan dan keuangan
tetap memakai SQLite lokal seperti Pertemuan 7, lalu dipindahkan ke server
pada pertemuan berikutnya.

## Fitur

### Backend

- `docker compose up` menjalankan tiga layanan: MySQL, API FastAPI, dan Adminer
- MySQL memakai *volume* sehingga data tidak hilang saat container dibuat ulang
- API baru menyala setelah MySQL benar-benar siap (`healthcheck` dan `depends_on`)
- Kode API di laptop langsung dipakai container (*auto-reload*)
- Password disimpan di `.env` yang tidak ikut ke GitHub
- `GET /health` benar-benar memeriksa database dan membalas **503** bila database tidak dapat dihubungi
- Adminer di port 8081 untuk melihat isi database lewat browser

### Aplikasi Flutter

- Halaman **Status Server** yang memisahkan status **API** dan **Database**
- Kode 503 dibaca sebagai "API hidup, database bermasalah", bukan galat jaringan
- Alamat API dapat diubah dari halaman Pengaturan lewat dialog dengan validasi
  format URL, dan tersimpan walaupun aplikasi ditutup
- Unit test dengan `MockClient` untuk tiga kasus: sehat, 503, dan kode lain

## Endpoint API

| Metode | Alamat | Fungsi |
|---|---|---|
| GET | `/` | Pesan selamat datang |
| GET | `/info` | Nama, versi, dan zona waktu server |
| GET | `/health` | Status API dan database. `200` bila sehat, `503` bila database mati |
| GET | `/docs` | Dokumentasi Swagger yang dibuat otomatis |

Contoh balasan `GET /health` saat sehat (`200`):

```json
{"status": "ok", "waktu_server": "2026-10-30T10:18:42", "database": "ok", "mysql_version": "8.4.13"}
```

Saat database mati (`503`):

```json
{"status": "degraded", "waktu_server": "2026-10-30T10:18:02", "database": "error", "mysql_version": null, "detail": "Tidak dapat terhubung ke database MySQL."}
```

## Tampilan

<table>
  <tr>
    <td align="center"><img src="img/gambar1.png" width="360"><br><sub>Dokumentasi Swagger (/docs) TabungKu API</sub></td>
    <td align="center"><img src="img/gambar2.png" width="200"><br><sub>Status Server (versi praktikum)</sub></td>
    <td align="center"><img src="img/gambar3.png" width="200"><br><sub>Status Server (versi tugas): API dan Database terpisah</sub></td>
  </tr>
</table>

## Sintaks yang Digunakan

### 1. Docker Compose (`docker-compose.yml`)

```yaml
services:
  mysql:
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    ports:
      - "3307:3306"
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h 127.0.0.1 -uroot -p$$MYSQL_ROOT_PASSWORD --silent"]
      interval: 5s
      retries: 20

  api:
    build: ./backend
    depends_on:
      mysql:
        condition: service_healthy

volumes:
  mysql_data:
```

- `services` berisi daftar layanan; tiap layanan menjadi satu container.
- `image` memakai image jadi dari Docker Hub, sedangkan `build` membuat image dari `Dockerfile` di folder tersebut.
- `${MYSQL_ROOT_PASSWORD}` diisi otomatis dari berkas `.env`, sehingga password tidak ditulis di file yang di-commit.
- `ports: "3307:3306"` berarti port 3307 di laptop diteruskan ke port 3306 di dalam container (kiri: laptop, kanan: container).
- `volumes` dengan nama `mysql_data` menyimpan data MySQL di luar container, sehingga tetap ada walau container dihapus.
- `healthcheck` menjalankan perintah berkala untuk menandai MySQL sudah siap; `-h 127.0.0.1` memaksa koneksi TCP, dan `$$` adalah tanda `$` yang di-*escape* agar dibaca oleh shell di dalam container, bukan oleh Compose.
- `depends_on` dengan `condition: service_healthy` membuat API baru dijalankan setelah MySQL benar-benar siap, bukan sekadar container-nya menyala.

### 2. Layanan tambahan dan bind mount

```yaml
  api:
    volumes:
      - ./backend/app:/code/app

  adminer:
    image: adminer:5
    ports:
      - "8081:8080"
```

- Volume berbentuk `./folder:/path` disebut *bind mount*: folder di laptop langsung dipakai container, jadi perubahan kode terlihat tanpa build ulang.
- Adminer memakai port 8081 di laptop. Saat login, kolom *Server* diisi `mysql` (nama layanan), bukan `localhost`.

### 3. Dockerfile

```dockerfile
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /code
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

- `FROM` menentukan image dasar; varian `slim` jauh lebih kecil daripada image Python penuh.
- `WORKDIR` menentukan folder kerja di dalam container.
- `requirements.txt` disalin dan dipasang **sebelum** kode disalin. Docker menyimpan hasil tiap baris sebagai *layer*, sehingga mengubah kode tidak memicu `pip install` ulang.
- `--host 0.0.0.0` wajib agar API dapat diakses dari luar container, dan `--reload` memuat ulang server saat kode berubah.

### 4. Variabel lingkungan dan Git

```
# .env.example (contoh, ikut di-commit)
MYSQL_ROOT_PASSWORD=rahasia_root
MYSQL_USER=tabungku

# .gitignore
.env
```

- `.env.example` adalah contoh isi; berkas `.env` yang asli disalin dari situ dan **tidak** ikut ke GitHub karena masuk `.gitignore`.

### 5. FastAPI: endpoint dan kode status

```python
app = FastAPI(title="TabungKu API", version=VERSI)

@app.get("/info")
def info():
    return {"nama": "TabungKu API", "versi": VERSI, "zona_waktu": os.getenv("TZ", "UTC")}

@app.get("/health")
def health():
    try:
        with engine.connect() as koneksi:
            versi = koneksi.execute(text("SELECT VERSION()")).scalar()
    except SQLAlchemyError:
        return JSONResponse(status_code=503, content={...})
    return {"status": "ok", "database": "ok", "mysql_version": versi}
```

- Dekorator `@app.get("/info")` mendaftarkan fungsi sebagai endpoint `GET /info`.
- `dict` yang dikembalikan otomatis diubah menjadi JSON.
- `JSONResponse(status_code=503, ...)` mengatur kode status sendiri. Kode 503 (*Service Unavailable*) lebih tepat daripada 200 saat database mati, karena alat pemantau tidak akan mengira server sehat.
- `try ... except SQLAlchemyError` menangkap kegagalan database sehingga API tetap membalas, bukan error 500.
- Pesan galat sengaja generik agar detail teknis (alamat dan password) tidak bocor ke klien.

### 6. Pengaturan dengan `pydantic-settings`

```python
class Settings(BaseSettings):
    database_url: str = "mysql+pymysql://tabungku:...@localhost:3307/tabungku"

settings = Settings()
```

- `BaseSettings` membaca nilai dari *environment variable* dengan nama yang sama (`DATABASE_URL`, tidak peka huruf besar/kecil). Nilai di kode hanya cadangan.
- Di dalam Compose, nilainya diisi `docker-compose.yml`, dengan host `mysql` (nama layanan).

### 7. SQLAlchemy: koneksi dan query

```python
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 3},
)

with engine.connect() as koneksi:
    versi = koneksi.execute(text("SELECT VERSION()")).scalar()
```

- `create_engine` menyiapkan koneksi ke database.
- `pool_pre_ping=True` mengecek koneksi sebelum dipakai, berguna bila MySQL sempat restart.
- `connect_timeout` membuat API menyerah dalam 3 detik bila MySQL mati, sehingga `/health` cepat membalas 503.
- `with ... as` menutup koneksi otomatis setelah selesai.
- `text()` membungkus teks SQL, dan `.scalar()` mengambil satu nilai dari baris pertama.

### 8. Flutter: alamat API dari `--dart-define`

```dart
const apiUrlBawaan = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

final ValueNotifier<String> alamatApi = ValueNotifier<String>(apiUrlBawaan);
```

- `String.fromEnvironment` membaca nilai dari `flutter run --dart-define=API_URL=...`, sehingga alamat bisa diganti tanpa mengubah kode.
- `10.0.2.2` adalah alamat khusus emulator Android untuk menuju `localhost` laptop. `localhost` di emulator berarti emulator itu sendiri.
- `ValueNotifier` menyimpan alamat yang sedang dipakai dan memberi tahu tampilan setiap kali berubah.
- `AndroidManifest.xml` perlu izin `INTERNET` dan `android:usesCleartextTraffic="true"` (khusus pengembangan) karena server memakai HTTP biasa.

### 9. Flutter: validasi dan penyimpanan alamat

```dart
String? validasiUrl(String? nilai) {
  final teks = (nilai ?? '').trim();
  if (teks.isEmpty) return 'Alamat API wajib diisi';
  final uri = Uri.tryParse(teks);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
    return 'Format tidak valid. Contoh: http://10.0.2.2:8000';
  }
  return null;
}

String rapikanUrl(String nilai) => nilai.trim().replaceAll(RegExp(r'/+$'), '');

final prefs = await SharedPreferences.getInstance();
await prefs.setString('api_url', bersih);
```

- Fungsi validator mengembalikan pesan galat, atau `null` bila isian benar.
- `Uri.tryParse` mengembalikan `null` (bukan melempar error) bila teks bukan URL yang valid.
- `RegExp(r'/+$')` membuang garis miring di akhir alamat agar tidak menjadi `//health`.
- `SharedPreferences` menyimpan pengaturan sederhana sehingga alamat tetap ada setelah aplikasi ditutup.

### 10. Flutter: memanggil API dan membaca kode status

```dart
Future<StatusServer> cekServer({http.Client? client}) async {
  final c = client ?? http.Client();
  final jam = Stopwatch()..start();
  try {
    final res = await c.get(Uri.parse('${alamatApi.value}/health')).timeout(batasWaktu);
    jam.stop();
    if (res.statusCode != 200 && res.statusCode != 503) {
      throw Exception('Server membalas kode ${res.statusCode}');
    }
    // 200 = sehat, 503 = API hidup tetapi database mati
  } finally {
    if (client == null) c.close();
  }
}
```

- Fungsi `async` mengembalikan `Future`, dan `await` menunggu balasan server.
- `.timeout(batasWaktu)` membatalkan permintaan bila server tidak membalas dalam 10 detik.
- `Stopwatch` mengukur latensi, yaitu lama server membalas.
- Parameter `client` bersifat opsional agar fungsi bisa diuji memakai `MockClient` tanpa server asli.
- Kode 200 dan 503 sama-sama berarti **API hidup** (server membalas), jadi 503 tidak dianggap galat. Kode lain dilempar sebagai `Exception`.
- `finally` memastikan `http.Client` yang dibuat sendiri selalu ditutup, baik berhasil maupun gagal.

### 11. Flutter: halaman Status Server

```dart
FutureBuilder<StatusServer>(
  future: _future,
  builder: (context, snapshot) {
    final memuat = snapshot.connectionState != ConnectionState.done;
    final data = (!memuat && snapshot.hasData) ? snapshot.data : null;
    final galat = (!memuat && snapshot.hasError) ? snapshot.error : null;
    // tampilkan kartu API dan kartu Database sesuai kondisi
  },
)

if (e is TimeoutException) { ... }
if (e is SocketException || e is http.ClientException) { ... }
```

- `FutureBuilder` menangani tiga kondisi: memuat, berhasil, dan galat.
- Kondisi API dan database dihitung terpisah: API *Hidup/Mati*, database *Terhubung/Bermasalah/Tidak diketahui* (bila API sendiri tidak terjangkau).
- Banner di atas merangkum tiga keadaan: semua normal (hijau), API hidup tetapi database bermasalah (oranye), dan server tidak terjangkau (merah).
- Pesan galat dipilih berdasarkan jenis exception, sehingga pengguna tahu apakah masalahnya waktu habis atau tidak dapat terhubung.
- Tombol **Periksa lagi** mengganti `_future` di dalam `setState`.

### 12. Flutter: dialog dengan validasi

```dart
final berubah = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    content: Form(key: kunci, child: TextFormField(controller: c, validator: validasiUrl)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
      FilledButton(
        onPressed: () async {
          if (!kunci.currentState!.validate()) return;
          await simpanAlamatApi(c.text);
          if (ctx.mounted) Navigator.pop(ctx, true);
        },
        child: const Text('Simpan'),
      ),
    ],
  ),
);
```

- `showDialog<bool>` menunggu pengguna menekan tombol dan mengembalikan hasilnya (`true`, `false`, atau `null`).
- `validate()` menjalankan validator; bila gagal, pesan merah muncul dan dialog tidak menutup.
- `ctx.mounted` dicek sebelum memakai `context` setelah `await`, agar tidak terjadi error pada widget yang sudah ditutup.

### 13. Unit test dengan `MockClient`

```dart
test('503: API hidup, database mati (bukan galat)', () async {
  final client = MockClient((req) async {
    return http.Response(jsonEncode({'database': 'error', 'detail': '...'}), 503);
  });
  final s = await cekServer(client: client);
  expect(s.databaseOk, isFalse);
});

test('kode lain (500): dianggap galat', () async {
  final client = MockClient((req) async => http.Response('galat', 500));
  expect(cekServer(client: client), throwsException);
});
```

- `MockClient` membalas permintaan dengan jawaban buatan, sehingga fungsi diuji tanpa server dan Docker.
- `expect(nilai, pencocok)` memeriksa hasil; `isFalse`, `isNull`, dan `throwsException` adalah pencocok bawaan.
- Tiga kasus yang diuji: sehat (200), database mati (503), dan kode lain (500).

## Jawaban Latihan Mandiri

**1. Endpoint `GET /info`.** Ditambahkan di `main.dart`; mengembalikan nama aplikasi, versi, dan zona waktu server dari environment variable `TZ` (`Asia/Jakarta`), dan terlihat di `/docs`.

**2. Mengganti port API menjadi 9000.** Yang diubah hanya port sisi laptop di `docker-compose.yml`, yaitu `"9000:8000"` (angka kiri). Port di dalam container tetap 8000 karena `uvicorn` di `Dockerfile` mendengarkan port 8000. Di Flutter kode tidak diubah, cukup alamatnya lewat `--dart-define=API_URL=http://10.0.2.2:9000` (atau dari dialog di Pengaturan).

**3. `down` dan `down -v`.** Setelah `docker compose down` lalu `up -d`, tabel uji **masih ada**, karena data MySQL ada di volume `mysql_data`, di luar container. Setelah `docker compose down -v`, tabel **hilang**, karena opsi `-v` ikut menghapus volume.

**4. Ukuran image.** Isi dengan angka dari `docker images`:

| Image | Ukuran |
|---|---|
| `tabungku-api` dengan `python:3.12-slim` | [isi] |
| `tabungku-api` dengan `python:3.12` | [isi] |

Varian `slim` jauh lebih kecil karena hanya berisi Python dan komponen minimal, sedangkan image penuh membawa banyak alat yang tidak dibutuhkan. Image kecil lebih cepat diunduh dan lebih hemat disk.

## Jawaban Pertanyaan Refleksi

1. **Data MySQL saat container dihapus.** Data tetap ada karena disimpan di volume `mysql_data`, bukan di dalam container. Data baru hilang bila volumenya dihapus (`docker compose down -v` atau `docker volume rm`).
2. **Host `mysql` vs `localhost:3307`.** Di dalam jaringan Compose, layanan saling memanggil lewat nama layanan dan port internalnya (`mysql:3306`). Dari laptop, harus lewat port yang dipublikasikan ke luar (`localhost:3307`, hasil `3307:3306`).
3. **`depends_on` tanpa `service_healthy`.** Compose hanya menunggu container MySQL *dimulai*, bukan *siap*. API bisa mencoba terhubung saat MySQL masih inisialisasi, sehingga koneksi gagal dan API bisa crash.
4. **`localhost` di emulator.** `localhost` di emulator menunjuk ke emulator itu sendiri, bukan laptop. Emulator menyediakan alamat khusus `10.0.2.2` yang menuju `localhost` laptop.
5. **503 vs 200 saat database mati.** Kode 200 berarti semuanya baik, sehingga alat pemantau dan load balancer akan menganggap server sehat padahal tidak. Kode 503 memberi sinyal jelas bahwa sebagian layanan tidak tersedia, sementara isi JSON menjelaskan bagian yang rusak.

## Cara Menjalankan

**Backend** (di folder `pertemuan8`, Docker Desktop harus menyala):

```
cp .env.example .env
docker compose up -d --build
docker compose ps
```

Tunggu `mysql` berstatus *healthy*, lalu buka:

| Alamat | Isi |
|---|---|
| `http://localhost:8000/docs` | Swagger API |
| `http://localhost:8000/health` | Status API dan database |
| `http://localhost:8081` | Adminer (Server `mysql`, user dan password sesuai `.env`) |

Perintah dasar: `docker compose logs -f api` (lihat log), `docker compose stop mysql` (mematikan database untuk menguji kode 503), `docker compose down` (hentikan, data tetap ada), dan `docker compose down -v` (hentikan dan **hapus seluruh data database**).

**Aplikasi Flutter** (di folder `pertemuan8/mobile`):

```
flutter pub get
flutter run -d emulator-5554
flutter test
```

| Perangkat | Alamat API |
|---|---|
| Emulator Android | `http://10.0.2.2:8000` (bawaan) |
| HP fisik (satu Wi-Fi dengan laptop) | `http://IP-LAPTOP:8000`, diatur dari Pengaturan atau `--dart-define=API_URL=...` |

Port yang dipakai: **8000** (API), **3307** (MySQL dari laptop), dan **8081** (Adminer).

## Struktur Folder

```
pertemuan8/
  docker-compose.yml         MySQL + API + Adminer
  .env.example               contoh variabel lingkungan (.env tidak di-commit)
  backend/
    Dockerfile               langkah membuat image API
    requirements.txt         dependensi Python (versi dikunci)
    app/
      main.py                endpoint /, /info, /health
      config.py              pengaturan dari environment variable
      database.py            koneksi SQLAlchemy ke MySQL
  mobile/                    aplikasi Flutter TabungKu
    lib/
      config/api_config.dart       alamat API, validasi, penyimpanan
      services/health_service.dart pemanggilan GET /health
      pages/status_server_page.dart halaman Status Server
      pages/pengaturan_page.dart   pengaturan + dialog alamat API
    test/                    unit test MockClient
  Docs/
    readme.md                berkas ini
    img/                     tangkapan layar
```