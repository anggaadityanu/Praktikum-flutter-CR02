# TabungKu Cloud: REST API Kegiatan dan Laporan

Mini proyek Pemrograman Mobile, Pertemuan 9: REST API CRUD dengan FastAPI,
SQLAlchemy, Pydantic, dan Alembic, ditambah endpoint laporan dan lapisan
layanan API di Flutter.

## Identitas

| | |
|---|---|
| Nama | Aga |
| NIM | 20240801165 |
| Program Studi | Teknik Informatika, Universitas Esa Unggul |
| Mata Kuliah | Pemrograman Mobile (CIE511) |
| Tugas | Pertemuan 9: REST API CRUD, Migrasi Alembic, dan Endpoint Laporan |

## Apa yang dibangun?

Pada Pertemuan 8, server TabungKu baru bisa menjawab "apakah saya hidup?"
(`/health`). Pertemuan 9 membuat server benar-benar **menyimpan dan mengelola
data kegiatan**:

- tabel `kegiatan` di MySQL, dibuat lewat **migrasi Alembic** (bukan SQL manual),
- API REST untuk membuat, membaca, mengganti, mengubah sebagian, dan menghapus kegiatan,
- **aturan bisnis TabungKu** dari Pertemuan 7 dipindahkan ke server dengan Pydantic,
- **endpoint laporan** harian dan rentang yang seluruh angkanya dihitung di SQL,
- di Flutter, **lapisan layanan** (`KegiatanApi`, `LaporanApi`) yang diuji
  dengan `MockClient`. Tampilan aplikasi belum diubah (masih SQLite); lapisan
  ini baru dipasang ke UI pada Pertemuan 11.

```
Flutter (KegiatanApi, LaporanApi)
        |  HTTP/JSON
        v
FastAPI  --  routers: /kegiatan, /laporan, /health
        |    schemas (Pydantic): validasi aturan bisnis
        |    models (SQLAlchemy): pemetaan tabel
        v
MySQL 8.4  <--  skema dikelola Alembic (revisi bernomor)
```

## Fitur

### Backend

- CRUD lengkap `/kegiatan`: `GET` (daftar dan detail), `POST`, `PUT`, `PATCH`, `DELETE`
- Filter daftar: `tanggal`, `tipe`, `selesai`, `q` (cari judul), urutan `urut`, dan pagination `limit`/`offset`
- Header `X-Total-Count` berisi jumlah seluruh data sebelum dipotong `limit`
- Validasi aturan bisnis di server; data yang melanggar dibalas **422**
- `PATCH` memvalidasi ulang data gabungan agar aturan bisnis tetap berlaku
- Migrasi Alembic otomatis dijalankan saat container API menyala (`start.sh`)
- Laporan harian dan laporan rentang dihitung di SQL, bukan dengan perulangan Python

### Flutter

- `Kegiatan.toJson/fromJson` dan `Ringkasan.fromJson`
- `ApiException` yang menerjemahkan galat FastAPI menjadi pesan siap tampil
- `KegiatanApi` (daftar, tambah, ubah, setSelesai, hapus) dan `LaporanApi` (harian, rentang)
- 21 unit test dengan `MockClient`, tanpa server dan tanpa Docker

## Aturan bisnis (divalidasi di server)

| Jenis | `nominal` | `kategori` |
|---|---|---|
| `tanpa` | dibersihkan menjadi `0` | dibersihkan menjadi `-` |
| `pemasukan` | wajib lebih dari 0 | dibersihkan menjadi `-` |
| `pengeluaran` | wajib lebih dari 0 | wajib salah satu: Makan, Transport, Belajar, Hiburan, Lainnya |

Selain itu `judul` wajib diisi (spasi saja ditolak) dan `tanggal` harus berformat `YYYY-MM-DD`.

## Endpoint API

### Kegiatan

| Metode | Alamat | Fungsi | Kode sukses |
|---|---|---|---|
| GET | `/kegiatan` | Daftar kegiatan (filter dan pagination) | 200 |
| GET | `/kegiatan/{id}` | Detail satu kegiatan | 200 |
| POST | `/kegiatan` | Tambah kegiatan | 201 |
| PUT | `/kegiatan/{id}` | Ganti seluruh isi kegiatan | 200 |
| PATCH | `/kegiatan/{id}` | Ubah sebagian field | 200 |
| DELETE | `/kegiatan/{id}` | Hapus kegiatan | 204 |

Parameter `GET /kegiatan`:

| Parameter | Isi |
|---|---|
| `tanggal` | `YYYY-MM-DD`, hanya kegiatan pada tanggal itu |
| `tipe` | `tanpa`, `pemasukan`, atau `pengeluaran` |
| `selesai` | `true` atau `false` |
| `q` | kata yang dicari di judul |
| `urut` | `terbaru` atau `terlama` (menurut tanggal lalu id). Kosong: belum selesai di atas |
| `limit`, `offset` | pagination (`limit` 1 sampai 200, bawaan 50) |

### Laporan

| Metode | Alamat | Fungsi |
|---|---|---|
| GET | `/laporan/harian?tanggal=YYYY-MM-DD` | Ringkasan satu hari dan pengeluaran per kategori |
| GET | `/laporan/rentang?mulai=...&sampai=...` | Ringkasan setiap hari dalam rentang, termasuk hari tanpa kegiatan (bernilai 0) |

`/laporan/rentang` membalas **400** bila `sampai` lebih awal dari `mulai` atau rentang lebih dari 31 hari.

Contoh balasan `GET /laporan/harian?tanggal=2026-10-06` untuk data "Contoh Skenario Satu Hari":

```json
{
  "tanggal": "2026-10-06",
  "jumlah_kegiatan": 4,
  "selesai": 2,
  "pemasukan": 50000,
  "pengeluaran": 25000,
  "tabungan": 25000,
  "per_kategori": [
    {"kategori": "Makan", "total": 15000},
    {"kategori": "Transport", "total": 10000}
  ]
}
```

### Lainnya

| Metode | Alamat | Fungsi |
|---|---|---|
| GET | `/health` | `200` bila API dan database sehat, `503` bila database mati |
| GET | `/info` | Nama, versi, dan zona waktu server |
| GET | `/docs` | Dokumentasi Swagger |

## Sintaks yang Digunakan

### 1. Model SQLAlchemy 2 (`models.py`)

```python
class Tipe(str, enum.Enum):
    tanpa = "tanpa"
    pemasukan = "pemasukan"
    pengeluaran = "pengeluaran"


class Kegiatan(Base):
    __tablename__ = "kegiatan"

    id: Mapped[int] = mapped_column(primary_key=True)
    judul: Mapped[str] = mapped_column(String(100))
    tanggal: Mapped[date] = mapped_column(Date, index=True)
    selesai: Mapped[bool] = mapped_column(default=False)
    tipe: Mapped[Tipe] = mapped_column(Enum(Tipe), default=Tipe.tanpa)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
```

- Tiap kelas model mewakili satu tabel, dan tiap atribut mewakili satu kolom, sehingga `db.add(k)` menggantikan `INSERT` manual.
- `Mapped[tipe]` menyatakan tipe Python kolom; `mapped_column(...)` menambahkan detail (panjang teks, indeks, nilai bawaan).
- `Tipe(str, enum.Enum)` membatasi jenis kegiatan pada tiga nilai dan tersimpan sebagai kolom `ENUM` di MySQL.
- `index=True` pada `tanggal` mempercepat query yang menyaring per tanggal.
- `server_default=func.now()` membuat database yang mengisi waktu saat baris dibuat, dan `onupdate` memperbarui `updated_at` setiap kali baris diubah lewat ORM.

### 2. Session per request (`database.py`)

```python
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 3},
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


class Base(DeclarativeBase):
    """Kelas induk semua model tabel."""


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

- `get_db` adalah fungsi *generator*: kode sebelum `yield` menyiapkan session, dan blok `finally` selalu menutupnya walau terjadi galat.
- Endpoint memakainya lewat `db: Session = Depends(get_db)`, sehingga FastAPI menyiapkan satu session baru untuk setiap request.
- `expire_on_commit=False` membuat objek tetap bisa dibaca setelah `commit()`.
- `connect_timeout` membuat API cepat menyerah (3 detik) bila MySQL mati.

### 3. Validasi dengan Pydantic (`schemas.py`)

```python
class KegiatanBase(BaseModel):
    judul: str = Field(min_length=1, max_length=100)
    tanggal: date
    nominal: int = Field(default=0, ge=0)


class KegiatanInput(KegiatanBase):
    @field_validator("judul")
    @classmethod
    def judul_tidak_kosong(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("judul wajib diisi")
        return v

    @model_validator(mode="after")
    def cek_aturan_bisnis(self):
        if self.tipe == Tipe.tanpa:
            self.nominal = 0
            self.kategori = "-"
            return self
        if self.nominal <= 0:
            raise ValueError("nominal wajib lebih dari 0 untuk pemasukan/pengeluaran")
        ...


class KegiatanOut(KegiatanBase):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
```

- `Field(min_length=..., ge=0)` memberi batasan sederhana pada satu field.
- `@field_validator` memeriksa **satu field** (judul tidak boleh hanya spasi).
- `@model_validator(mode="after")` memeriksa **gabungan beberapa field** setelah semuanya valid, yaitu aturan bisnis yang bergantung pada `tipe`.
- `ValueError` di dalam validator otomatis menjadi balasan **422** dengan pesan yang bisa dibaca.
- Skema dibagi tiga: `KegiatanInput` (data masuk dari klien), `KegiatanOut` (data keluar, ditambah `id` dan cap waktu dari database), dan `KegiatanPatch` (semua field opsional).
- `from_attributes=True` membuat Pydantic bisa membaca objek model SQLAlchemy secara langsung.

### 4. Router dan kode status (`routers/kegiatan.py`)

```python
router = APIRouter(prefix="/kegiatan", tags=["kegiatan"])


def _ambil_atau_404(db: Session, kegiatan_id: int) -> Kegiatan:
    k = db.get(Kegiatan, kegiatan_id)
    if k is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Kegiatan tidak ditemukan")
    return k


@router.post("", response_model=KegiatanOut, status_code=status.HTTP_201_CREATED)
def tambah_kegiatan(data: KegiatanInput, db: Session = Depends(get_db)):
    k = Kegiatan(**data.model_dump())
    db.add(k)
    db.commit()
    db.refresh(k)
    return k


@router.delete("/{kegiatan_id}", status_code=status.HTTP_204_NO_CONTENT)
def hapus_kegiatan(kegiatan_id: int, db: Session = Depends(get_db)):
    db.delete(_ambil_atau_404(db, kegiatan_id))
    db.commit()
```

- `APIRouter(prefix, tags)` mengelompokkan endpoint sejenis, lalu didaftarkan di `main.py` dengan `app.include_router(...)`.
- `response_model` memilih bentuk data yang dikirim ke klien dan menyaring field lain.
- `status_code=201` untuk data baru dibuat dan `204` untuk berhasil tanpa isi balasan; `HTTPException(404)` menandai data yang tidak ada.
- `db.get` mengambil satu baris menurut kunci utama, `db.add` menandai objek baru, `db.commit` menyimpan permanen, dan `db.refresh` membaca ulang baris karena `id` dan `created_at` diisi database.
- `Kegiatan(**data.model_dump())` mengubah data tervalidasi menjadi objek model.
- Fungsi pembantu `_ambil_atau_404` dipakai bersama oleh GET detail, PUT, PATCH, dan DELETE agar tidak ada kode yang berulang.

### 5. Daftar dengan filter dan pagination

```python
stmt = select(Kegiatan)
if tanggal:
    stmt = stmt.where(Kegiatan.tanggal == tanggal)
if selesai is not None:
    stmt = stmt.where(Kegiatan.selesai == selesai)
if q:
    stmt = stmt.where(Kegiatan.judul.contains(q))

total = db.scalar(select(func.count()).select_from(stmt.subquery()))
response.headers["X-Total-Count"] = str(total)

stmt = stmt.order_by(Kegiatan.selesai, Kegiatan.id.desc()).limit(limit).offset(offset)
return db.scalars(stmt).all()
```

- `select(...)` membangun query bertahap; tiap `.where(...)` menambah satu syarat hanya bila filter itu dikirim.
- `selesai is not None` (bukan `if selesai`) dipakai agar nilai `false` tetap diproses sebagai filter.
- Jumlah seluruh data dihitung dari *subquery* sebelum `limit` diterapkan, lalu dikirim lewat header `X-Total-Count`.
- `limit` dan `offset` memotong hasil per halaman, dan `Query(50, ge=1, le=200)` membatasi nilainya agar klien tidak meminta terlalu banyak.
- Parameter `urut` bertipe `Literal["terbaru", "terlama"]`, sehingga nilai lain otomatis ditolak 422.

### 6. PATCH dengan validasi ulang

```python
gabungan = KegiatanOut.model_validate(k).model_dump()
gabungan.update(data.model_dump(exclude_unset=True))
try:
    valid = KegiatanInput.model_validate(gabungan)
except ValidationError as e:
    raise RequestValidationError(
        e.errors(include_url=False, include_context=False)
    ) from e
```

- `exclude_unset=True` hanya mengambil field yang benar-benar dikirim klien.
- Data lama dan data baru digabung, lalu divalidasi ulang sebagai `KegiatanInput`, sehingga aturan bisnis tetap berlaku pada hasil akhirnya.
- `RequestValidationError` membuat kegagalan ini dibalas 422 dengan format yang sama seperti validasi bawaan FastAPI. Opsi `include_context=False` membuang bagian yang tidak bisa diubah menjadi JSON.

### 7. Migrasi Alembic

```python
# alembic/versions/0001_buat_tabel_kegiatan.py
revision = "0001"
down_revision = None

def upgrade() -> None:
    op.create_table("kegiatan", sa.Column("id", sa.Integer(), primary_key=True), ...)
    op.create_index("ix_kegiatan_tanggal", "kegiatan", ["tanggal"])

def downgrade() -> None:
    op.drop_index("ix_kegiatan_tanggal", table_name="kegiatan")
    op.drop_table("kegiatan")
```

```
alembic upgrade head      # terapkan semua revisi
alembic current           # revisi yang aktif sekarang
alembic check             # bandingkan model dengan database
alembic downgrade -1      # batalkan satu revisi
alembic revision --autogenerate -m "pesan"   # buat revisi dari selisih model dan database
```

- Alembic mencatat setiap perubahan skema sebagai revisi bernomor, mirip `onUpgrade` di SQLite tetapi untuk server.
- `upgrade()` menerapkan perubahan dan `downgrade()` membatalkannya, sehingga perubahan skema bisa diulang di mesin lain dan dibatalkan.
- `down_revision` menunjuk revisi sebelumnya sehingga revisi membentuk satu rantai.
- `env.py` membaca URL database dari konfigurasi aplikasi dan menunjuk `Base.metadata` sebagai acuan `--autogenerate`; model harus diimpor di sana agar terdeteksi.
- `start.sh` menjalankan `alembic upgrade head` lalu `exec uvicorn ...`, sehingga tabel selalu siap sebelum API menerima request.

### 8. Laporan dihitung di SQL (`routers/laporan.py`)

```python
_SELESAI = func.coalesce(
    func.sum(case((Kegiatan.selesai.is_(True), 1), else_=0)), 0
).label("selesai")
_MASUK = func.coalesce(
    func.sum(case((Kegiatan.tipe == Tipe.pemasukan, Kegiatan.nominal), else_=0)), 0
).label("masuk")

baris = db.execute(
    select(Kegiatan.tanggal, _JUMLAH, _SELESAI, _MASUK, _KELUAR)
    .where(Kegiatan.tanggal.between(mulai, sampai))
    .group_by(Kegiatan.tanggal)
).all()
per_hari = {b.tanggal: b for b in baris}

return [
    RingkasanHariOut(**_susun(hari, per_hari.get(hari)))
    for hari in (mulai + timedelta(days=i) for i in range(jumlah_hari))
]
```

- `case((kondisi, nilai), else_=0)` adalah `CASE WHEN` di SQL: menjumlahkan nominal hanya untuk jenis tertentu dalam satu query.
- `func.coalesce(..., 0)` mengganti `NULL` (saat tidak ada data) menjadi 0.
- `group_by(Kegiatan.tanggal)` menghasilkan satu baris per tanggal untuk seluruh rentang dalam **satu query**.
- Hari tanpa kegiatan tidak muncul di hasil `GROUP BY`, jadi dibuat dengan menelusuri semua tanggal dalam rentang (`timedelta`) dan memakai nol bila tidak ada barisnya.
- Pengecekan rentang memakai `HTTPException(400)` untuk rentang terbalik atau lebih dari 31 hari.
- Angka dihitung di database (bukan dijumlahkan dengan perulangan Python) karena database dirancang untuk agregasi dan hanya mengirim hasil ringkas.

### 9. Flutter: konversi JSON dan galat API

```dart
Map<String, Object?> toJson() => {
      'judul': judul,
      'selesai': selesai,
      'tipe': tipe.name,
    };

factory Kegiatan.fromJson(Map<String, dynamic> j) => Kegiatan(
      id: j['id'] as int,
      selesai: j['selesai'] as bool,
      tipe: Tipe.values.byName(j['tipe'] as String),
    );

factory ApiException.dariRespons(http.Response res) {
  var pesan = 'Server membalas kode ${res.statusCode}';
  try {
    final detail = (jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>)['detail'];
    if (detail is String) {
      pesan = detail;
    } else if (detail is List) {
      pesan = detail.map((e) => (e['msg'] as String).replaceFirst('Value error, ', '')).join('\n');
    }
  } catch (_) {}
  return ApiException(pesan, kode: res.statusCode);
}
```

- Berbeda dengan `toMap()` SQLite, `toJson()` mengirim `selesai` sebagai boolean dan tidak mengirim `id` (sudah ada di URL).
- FastAPI membalas galat dalam dua bentuk: teks (`HTTPException`) atau daftar (validasi 422); `dariRespons` menangani keduanya dan membuang awalan "Value error, ".
- `utf8.decode(res.bodyBytes)` dipakai agar karakter non-ASCII terbaca benar.
- Blok `try ... catch` melindungi dari balasan yang bukan JSON (misalnya halaman galat 502 dari proxy), lalu memakai pesan bawaan.

### 10. Flutter: `KegiatanApi` dan `LaporanApi`

```dart
class KegiatanApi {
  final http.Client _client;
  KegiatanApi({http.Client? client}) : _client = client ?? http.Client();

  http.Response _cek(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException.dariRespons(res);
    }
    return res;
  }

  Future<List<Kegiatan>> daftar({String? tanggal}) async {
    final res = _cek(await _client
        .get(_uri('/kegiatan', tanggal == null ? null : {'tanggal': tanggal}))
        .timeout(batasWaktu));
    ...
  }
}
```

- Konstruktor menerima `http.Client` opsional (*dependency injection*): kode produksi memakai client asli, sedangkan tes memberi `MockClient`.
- `_cek` dipakai semua method sehingga respons di luar 2xx selalu dilempar sebagai `ApiException`.
- Parameter query dikirim `null` bila tidak ada filter, agar URL tidak berakhir dengan tanda `?` kosong.
- `.timeout(batasWaktu)` membatalkan permintaan yang terlalu lama.
- `LaporanApi` memakai pola yang sama dengan method `harian(tanggal)` dan `rentang(mulai, sampai)`, ditambah kelas `LaporanHarian` yang membaca `per_kategori`.

### 11. Flutter: unit test dengan `MockClient`

```dart
test('422: pesan dibaca dari detail dan awalan Value error dibuang', () async {
  final api = KegiatanApi(client: MockClient((req) async {
    return http.Response(jsonEncode({
      'detail': [{'msg': 'Value error, judul wajib diisi'}]
    }), 422);
  }));

  await expectLater(
    api.setSelesai(1, true),
    throwsA(isA<ApiException>()
        .having((e) => e.kode, 'kode', 422)
        .having((e) => e.pesan, 'pesan', 'judul wajib diisi')),
  );
});
```

- `MockClient` membalas permintaan dengan jawaban buatan, sehingga kelas diuji tanpa server dan Docker.
- Tes memeriksa **permintaan yang dikirim** (metode, jalur, query, isi JSON) dan **hasil yang dikembalikan**.
- `throwsA(isA<ApiException>().having(...))` memeriksa jenis galat sekaligus isi pesan dan kodenya.
- Tes mencakup JSON (`toJson`, `fromJson`), semua method `KegiatanApi`, galat 422, 404, dan 502 (bukan JSON), serta `LaporanApi` (hari berisi, hari kosong, rentang, dan galat 400).

## Hasil Uji Swagger (Bagian F)

| No | Skenario | Hasil yang diharapkan | Hasil |
|----|----------|-----------------------|-------|
| 1 | `POST` pengeluaran Makan Rp 15.000 | 201, ada `id` dan `created_at` | Lulus |
| 2 | `POST` pemasukan dengan kategori Makan | 201, `kategori` menjadi `-` | Lulus |
| 3 | `POST` judul hanya spasi | 422, `judul wajib diisi` | Lulus |
| 4 | `POST` kategori `Jajan` | 422, daftar kategori yang sah | Lulus |
| 5 | `PATCH` `{"selesai": true}` | 200, `selesai` menjadi `true` | Lulus |
| 6 | `PATCH` `{"nominal": 0}` pada pengeluaran | 422, data tidak berubah | Lulus |
| 7 | `GET` dengan `tanggal` dan `limit=1` | 200, satu data, header `x-total-count` | Lulus |
| 8 | `DELETE` lalu `GET` pada id yang sama | 204, lalu 404 | Lulus |

## Jawaban Latihan Mandiri

**1. Filter `selesai`.** Parameter `selesai: bool | None` ditambahkan pada `GET /kegiatan`. Syaratnya dicek dengan `is not None` agar nilai `false` tetap diproses sebagai filter, dan `selesai=true` hanya mengembalikan kegiatan yang sudah selesai.

**2. Parameter `urut`.** Bertipe `Literal["terbaru", "terlama"]`. `terbaru` mengurutkan menurut tanggal lalu id secara menurun, `terlama` secara menaik. Bila `urut` kosong, urutan lama tetap berlaku (belum selesai di atas). Nilai selain dua pilihan itu dibalas 422.

**3. Revisi Alembic `0001b`.** Kolom `catatan` (`TEXT`, nullable) ditambahkan ke model, lalu revisi dibuat dengan `alembic revision --autogenerate --rev-id 0001b`. Isinya `op.add_column('kegiatan', sa.Column('catatan', sa.Text(), nullable=True))` di `upgrade()` dan `op.drop_column('kegiatan', 'catatan')` di `downgrade()`. Setelah `alembic upgrade head`, kolom `catatan` muncul di Adminer; setelah `alembic downgrade -1`, kolom itu hilang. Revisi dan perubahan model dihapus lagi sebelum melanjutkan ke Pertemuan 10, lalu `alembic check` kembali bersih.

**4. Tanggal `06-10-2026`.** Server membalas **422 Unprocessable Entity**:

```json
{"detail":[{"type":"date_from_datetime_parsing","loc":["body","tanggal"],"msg":"Input should be a valid date or datetime, invalid character in year","input":"06-10-2026","ctx":{"error":"invalid character in year"}}]}
```

Pydantic membaca field `date` dengan format ISO 8601 (`YYYY-MM-DD`). Teks `06-10-2026` tidak cocok dengan format itu (bagian awalnya dibaca sebagai tahun yang tidak valid). `loc` menunjuk `body` lalu `tanggal`, jadi pesan ini memberi tahu letak persis kesalahannya. Data ditolak sebelum menyentuh database.

## Jawaban Pertanyaan Refleksi

1. **`POST` membalas 201 dan `DELETE` 204, bukan 200.** 201 (*Created*) memberi tahu bahwa sebuah sumber daya baru berhasil dibuat, dan balasannya berisi data barunya. 204 (*No Content*) berarti berhasil tetapi tidak ada isi yang perlu dikirim, karena data yang dihapus sudah tidak ada. Kode 200 terlalu umum untuk kedua kasus itu.
2. **Skema diubah langsung lewat Adminer.** Perubahan itu tidak tercatat di revisi Alembic, sehingga database berbeda dari kode dan dari mesin lain. `alembic check` akan melaporkan selisih, dan revisi berikutnya bisa gagal (misalnya `Table already exists` atau `Can't locate revision`). Perubahan juga tidak bisa dibatalkan dengan `downgrade`.
3. **`PATCH` memvalidasi ulang data gabungan.** `PATCH` hanya mengirim sebagian field, sehingga aturan bisnis yang menyangkut beberapa field tidak bisa dicek dari data yang dikirim saja. Contoh data rusak yang dicegah: `PATCH {"nominal": 0}` pada kegiatan pengeluaran (pengeluaran dengan nominal 0 melanggar aturan), atau `PATCH {"tipe": "pengeluaran"}` pada kegiatan tanpa uang (nominal masih 0 dan kategori belum sah).
4. **Pagination dan `X-Total-Count`.** Aplikasi mobile terbatas pada data seluler, baterai, dan memori, jadi tidak boleh mengunduh ribuan baris sekaligus; data diambil per halaman dengan `limit` dan `offset`. Header `X-Total-Count` memberi tahu jumlah seluruh data sebelum dipotong, sehingga aplikasi tahu apakah masih ada halaman berikutnya dan bisa menampilkan jumlah total tanpa mengunduh semuanya.
5. **`KegiatanApi` menerima `http.Client` lewat konstruktor.** Saat dijalankan, kelas memakai client asli; saat diuji, tes memberi `MockClient` yang membalas dengan jawaban buatan, sehingga tes cepat, tidak butuh server, dan bisa menguji kasus galat yang sulit dibuat sungguhan (422, 404, 502). Ini disebut *dependency injection*.

## Cara Menjalankan

**Backend** (di folder `pertemuan9`, Docker Desktop harus menyala):

```
cp .env.example .env
docker compose up -d --build
docker compose ps
```

Migrasi Alembic otomatis berjalan saat container `api` menyala. Setelah `mysql` berstatus *healthy*:

| Alamat | Isi |
|---|---|
| `http://localhost:8000/docs` | Swagger (CRUD kegiatan dan laporan) |
| `http://localhost:8000/health` | Status API dan database |
| `http://localhost:8081` | Adminer (Server `mysql`, user dan password sesuai `.env`) |

Perintah migrasi (dijalankan di dalam container):

```
docker compose exec api alembic current
docker compose exec api alembic check
```

**Aplikasi Flutter** (di folder `pertemuan9/mobile`):

```
flutter pub get
flutter test
```

## Struktur Folder

```
pertemuan9/
  docker-compose.yml         MySQL + API + Adminer
  .env.example               contoh variabel lingkungan (.env tidak di-commit)
  backend/
    Dockerfile               image API (menjalankan start.sh)
    start.sh                 alembic upgrade head, lalu uvicorn
    requirements.txt         dependensi Python (versi dikunci)
    alembic.ini
    alembic/
      env.py                 koneksi dan Base.metadata untuk Alembic
      script.py.mako         templat revisi
      versions/
        0001_buat_tabel_kegiatan.py
    app/
      main.py                aplikasi FastAPI dan pendaftaran router
      config.py              pengaturan dari environment variable
      database.py            engine, SessionLocal, Base, get_db
      models.py              model Kegiatan dan enum Tipe
      schemas.py             skema Pydantic dan aturan bisnis
      routers/
        health.py            GET /health
        kegiatan.py          CRUD /kegiatan
        laporan.py           GET /laporan/harian dan /laporan/rentang
  mobile/
    lib/
      config/api_config.dart       alamat API
      models/kegiatan.dart         Kegiatan, Ringkasan (toJson, fromJson)
      models/laporan.dart          LaporanHarian
      services/api_exception.dart  penerjemah galat FastAPI
      services/kegiatan_api.dart   pembungkus /kegiatan
      services/laporan_api.dart    pembungkus /laporan
    test/                    unit test MockClient
  Docs/
    readme.md                berkas ini
```