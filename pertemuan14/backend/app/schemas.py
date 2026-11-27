from datetime import date, datetime

from pydantic import (
    BaseModel,
    ConfigDict,
    EmailStr,
    Field,
    field_validator,
    model_validator,
)

from .models import Tipe


class KegiatanBase(BaseModel):
    judul: str = Field(min_length=1, max_length=100, examples=["Makan siang"])
    tanggal: date = Field(examples=["2026-10-06"])
    selesai: bool = False
    tipe: Tipe = Tipe.tanpa
    nominal: int = Field(default=0, ge=0, examples=[15000])
    kategori_id: int | None = Field(default=None, examples=[1])


class KegiatanInput(KegiatanBase):
    """Data dari klien untuk POST dan PUT. Aturan bisnis TabungKu dicek di sini."""

    @field_validator("judul")
    @classmethod
    def judul_tidak_kosong(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("judul wajib diisi")
        return v

    @model_validator(mode="after")
    def cek_aturan_bisnis(self):
        # Tanpa uang: nominal dan kategori dibersihkan.
        if self.tipe == Tipe.tanpa:
            self.nominal = 0
            self.kategori_id = None
            return self
        if self.nominal <= 0:
            raise ValueError("nominal wajib lebih dari 0 untuk pemasukan/pengeluaran")
        # Pemasukan tidak punya kategori; pengeluaran wajib memilih kategori.
        # (Apakah id-nya ada di tabel kategori dicek di router, karena butuh query.)
        if self.tipe == Tipe.pemasukan:
            self.kategori_id = None
        elif self.kategori_id is None:
            raise ValueError("kategori wajib dipilih untuk pengeluaran")
        return self


class KegiatanPatch(BaseModel):
    """PATCH: semua field opsional, hanya yang dikirim yang diubah."""

    judul: str | None = None
    tanggal: date | None = None
    selesai: bool | None = None
    tipe: Tipe | None = None
    nominal: int | None = None
    kategori_id: int | None = None


class KegiatanOut(KegiatanBase):
    """Data yang dikirim ke klien: ditambah id dan cap waktu dari database."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    bukti: str | None = None
    # Nama kategori untuk ditampilkan; dibaca dari properti model `nama_kategori`.
    kategori: str = Field(default="-", validation_alias="nama_kategori")
    created_at: datetime
    updated_at: datetime


class KategoriOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    nama: str


class TotalKategori(BaseModel):
    kategori: str
    total: int


class RingkasanHariOut(BaseModel):
    """Ringkasan satu hari (dipakai juga oleh laporan rentang)."""

    tanggal: date
    jumlah_kegiatan: int
    selesai: int
    pemasukan: int
    pengeluaran: int
    tabungan: int


class LaporanHarianOut(RingkasanHariOut):
    """Ringkasan satu hari ditambah rincian pengeluaran per kategori."""

    per_kategori: list[TotalKategori]

class LaporanBulananOut(BaseModel):
    """Total satu bulan penuh."""

    tahun: int
    bulan: int
    jumlah_hari: int
    # Hari yang sudah lewat dengan tabungan >= target harian pengguna.
    hari_target_tercapai: int
    jumlah_kegiatan: int
    selesai: int
    pemasukan: int
    pengeluaran: int
    tabungan: int
    per_kategori: list[TotalKategori]


def _cek_kekuatan(password: str) -> str:
    """Password wajib mengandung minimal satu huruf dan satu angka."""
    if not any(c.isalpha() for c in password):
        raise ValueError("password harus mengandung minimal satu huruf")
    if not any(c.isdigit() for c in password):
        raise ValueError("password harus mengandung minimal satu angka")
    return password


class UserCreate(BaseModel):
    nama: str = Field(min_length=1, max_length=100, examples=["Budi"])
    email: EmailStr = Field(examples=["budi@contoh.id"])
    password: str = Field(min_length=8, max_length=72, examples=["rahasia123"])

    @field_validator("password")
    @classmethod
    def password_kuat(cls, v: str) -> str:
        return _cek_kekuatan(v)


class UserOut(BaseModel):
    """Sengaja tidak memuat password_hash."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    nama: str
    email: str
    target_harian: int


class Token(BaseModel):
    """Pasangan token hasil login atau refresh."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class GantiPassword(BaseModel):
    password_lama: str = Field(min_length=1, max_length=72)
    password_baru: str = Field(min_length=8, max_length=72, examples=["rahasia456"])

    @field_validator("password_baru")
    @classmethod
    def password_baru_kuat(cls, v: str) -> str:
        return _cek_kekuatan(v)

    @model_validator(mode="after")
    def beda_dari_lama(self):
        if self.password_baru == self.password_lama:
            raise ValueError("password baru harus berbeda dari password lama")
        return self


class UserUpdate(BaseModel):
    """PATCH /users/me: hanya field yang dikirim yang diubah."""

    nama: str | None = Field(default=None, min_length=1, max_length=100)
    target_harian: int | None = Field(default=None, ge=0, le=10_000_000)

    @field_validator("nama")
    @classmethod
    def nama_tidak_kosong(cls, v: str | None) -> str | None:
        if v is None:
            return v
        v = v.strip()
        if not v:
            raise ValueError("nama tidak boleh kosong")
        return v