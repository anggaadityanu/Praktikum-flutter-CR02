import calendar
import csv
import io
from datetime import date, timedelta

from fastapi import APIRouter, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from sqlalchemy import case, func, select
from sqlalchemy.orm import Session, joinedload

from ..deps import DbSession, UserAktif
from ..models import Kategori, Kegiatan, Tipe, User
from ..schemas import (
    LaporanBulananOut,
    LaporanHarianOut,
    RingkasanHariOut,
    TotalKategori,
)

router = APIRouter(prefix="/laporan", tags=["laporan"])

BATAS_HARI = 31
BATAS_EKSPOR_HARI = 366

# Seluruh angka dihitung di database, bukan dengan perulangan Python.
# COALESCE mengganti NULL (saat tidak ada data) menjadi 0, dan
# SUM(CASE WHEN ...) menjumlahkan nominal hanya untuk jenis tertentu.
_JUMLAH = func.count(Kegiatan.id).label("jumlah")
_SELESAI = func.coalesce(
    func.sum(case((Kegiatan.selesai.is_(True), 1), else_=0)), 0
).label("selesai")
_MASUK = func.coalesce(
    func.sum(case((Kegiatan.tipe == Tipe.pemasukan, Kegiatan.nominal), else_=0)), 0
).label("masuk")
_KELUAR = func.coalesce(
    func.sum(case((Kegiatan.tipe == Tipe.pengeluaran, Kegiatan.nominal), else_=0)), 0
).label("keluar")


def _susun(tanggal: date, baris=None) -> dict:
    """Menyusun ringkasan satu hari. baris=None berarti hari tanpa kegiatan."""
    masuk = int(baris.masuk) if baris else 0
    keluar = int(baris.keluar) if baris else 0
    return {
        "tanggal": tanggal,
        "jumlah_kegiatan": int(baris.jumlah) if baris else 0,
        "selesai": int(baris.selesai) if baris else 0,
        "pemasukan": masuk,
        "pengeluaran": keluar,
        "tabungan": masuk - keluar,
    }


def _per_kategori(
    db: Session, user: User, mulai: date, sampai: date
) -> list[TotalKategori]:
    """Pengeluaran per kategori pada rentang tanggal, terbesar di atas."""
    # JOIN ke tabel kategori: nama diambil dari sana, bukan dari kolom teks lagi.
    nama_kat = func.coalesce(Kategori.nama, "-")
    baris = db.execute(
        select(nama_kat, func.sum(Kegiatan.nominal))
        .outerjoin(Kegiatan.kategori)
        .where(
            Kegiatan.user_id == user.id,
            Kegiatan.tanggal.between(mulai, sampai),
            Kegiatan.tipe == Tipe.pengeluaran,
        )
        .group_by(nama_kat)
        .order_by(func.sum(Kegiatan.nominal).desc(), nama_kat)
    ).all()
    return [TotalKategori(kategori=k, total=int(total)) for k, total in baris]


@router.get("/harian", response_model=LaporanHarianOut)
def laporan_harian(
    db: DbSession,
    user: UserAktif,
    tanggal: date = Query(description="Format YYYY-MM-DD"),
):
    # Satu query agregat untuk angka ringkasan (selalu menghasilkan satu baris).
    baris = db.execute(
        select(_JUMLAH, _SELESAI, _MASUK, _KELUAR).where(
            Kegiatan.user_id == user.id, Kegiatan.tanggal == tanggal
        )
    ).one()

    return LaporanHarianOut(
        **_susun(tanggal, baris),
        per_kategori=_per_kategori(db, user, tanggal, tanggal),
    )


@router.get("/rentang", response_model=list[RingkasanHariOut])
def laporan_rentang(
    db: DbSession,
    user: UserAktif,
    mulai: date = Query(description="Tanggal awal, YYYY-MM-DD"),
    sampai: date = Query(description="Tanggal akhir, YYYY-MM-DD"),
):
    if sampai < mulai:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Tanggal 'sampai' tidak boleh lebih awal dari 'mulai'",
        )
    jumlah_hari = (sampai - mulai).days + 1
    if jumlah_hari > BATAS_HARI:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, f"Rentang maksimal {BATAS_HARI} hari"
        )

    # Satu query GROUP BY tanggal untuk seluruh rentang.
    baris = db.execute(
        select(Kegiatan.tanggal, _JUMLAH, _SELESAI, _MASUK, _KELUAR)
        .where(
            Kegiatan.user_id == user.id,
            Kegiatan.tanggal.between(mulai, sampai),
        )
        .group_by(Kegiatan.tanggal)
    ).all()
    per_hari = {b.tanggal: b for b in baris}

    # Hari tanpa kegiatan tidak ada di hasil query, jadi diisi nilai 0 di sini.
    return [
        RingkasanHariOut(**_susun(hari, per_hari.get(hari)))
        for hari in (mulai + timedelta(days=i) for i in range(jumlah_hari))
    ]


@router.get("/bulanan", response_model=LaporanBulananOut)
def laporan_bulanan(
    db: DbSession,
    user: UserAktif,
    tahun: int = Query(ge=2000, le=2100),
    bulan: int = Query(ge=1, le=12),
):
    """Total satu bulan, pengeluaran per kategori, dan jumlah hari target tercapai."""
    jumlah_hari = calendar.monthrange(tahun, bulan)[1]
    mulai = date(tahun, bulan, 1)
    sampai = date(tahun, bulan, jumlah_hari)

    # Satu query GROUP BY tanggal untuk sebulan penuh.
    baris = db.execute(
        select(Kegiatan.tanggal, _JUMLAH, _SELESAI, _MASUK, _KELUAR)
        .where(
            Kegiatan.user_id == user.id,
            Kegiatan.tanggal.between(mulai, sampai),
        )
        .group_by(Kegiatan.tanggal)
    ).all()
    per_hari = {b.tanggal: b for b in baris}

    # Hari yang belum terjadi tidak dihitung; hari tanpa kegiatan bertabungan 0.
    tercapai = 0
    for i in range(jumlah_hari):
        hari = mulai + timedelta(days=i)
        if hari > date.today():
            break
        b = per_hari.get(hari)
        tabungan = (int(b.masuk) - int(b.keluar)) if b else 0
        if tabungan >= user.target_harian:
            tercapai += 1

    masuk = sum(int(b.masuk) for b in baris)
    keluar = sum(int(b.keluar) for b in baris)
    return LaporanBulananOut(
        tahun=tahun,
        bulan=bulan,
        jumlah_hari=jumlah_hari,
        hari_target_tercapai=tercapai,
        jumlah_kegiatan=sum(int(b.jumlah) for b in baris),
        selesai=sum(int(b.selesai) for b in baris),
        pemasukan=masuk,
        pengeluaran=keluar,
        tabungan=masuk - keluar,
        per_kategori=_per_kategori(db, user, mulai, sampai),
    )


def _aman_csv(teks: str) -> str:
    """Teks yang diawali = + - @ dibaca Excel sebagai rumus (CSV injection).
    Diberi tanda petik di depan agar dibaca sebagai teks biasa."""
    return "'" + teks if teks[:1] in ("=", "+", "-", "@") else teks


@router.get("/ekspor.csv", response_class=StreamingResponse)
def ekspor_csv(
    db: DbSession,
    user: UserAktif,
    mulai: date = Query(description="Tanggal awal, YYYY-MM-DD"),
    sampai: date = Query(description="Tanggal akhir, YYYY-MM-DD"),
):
    """Unduh kegiatan dalam rentang tanggal (maksimal 366 hari) sebagai berkas CSV."""
    if sampai < mulai:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Tanggal 'sampai' tidak boleh lebih awal dari 'mulai'",
        )
    if (sampai - mulai).days + 1 > BATAS_EKSPOR_HARI:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST, f"Rentang maksimal {BATAS_EKSPOR_HARI} hari"
        )

    daftar = db.scalars(
        select(Kegiatan)
        .where(Kegiatan.user_id == user.id, Kegiatan.tanggal.between(mulai, sampai))
        .options(joinedload(Kegiatan.kategori))
        .order_by(Kegiatan.tanggal, Kegiatan.id)
    ).all()

    buf = io.StringIO()
    tulis = csv.writer(buf)
    tulis.writerow(["tanggal", "judul", "tipe", "kategori", "nominal", "selesai"])
    for k in daftar:
        tulis.writerow(
            [
                k.tanggal,
                _aman_csv(k.judul),
                k.tipe.value,
                k.nama_kategori,
                k.nominal,
                int(k.selesai),
            ]
        )
    nama = f"tabungku_{mulai}_{sampai}.csv"
    return StreamingResponse(
        iter([buf.getvalue()]),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="{nama}"'},
    )