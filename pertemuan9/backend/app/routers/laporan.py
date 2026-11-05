from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import case, func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Kegiatan, Tipe
from ..schemas import LaporanHarianOut, RingkasanHariOut, TotalKategori

router = APIRouter(prefix="/laporan", tags=["laporan"])

BATAS_HARI = 31

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


@router.get("/harian", response_model=LaporanHarianOut)
def laporan_harian(
    tanggal: date = Query(description="Format YYYY-MM-DD"),
    db: Session = Depends(get_db),
):
    # Satu query agregat untuk angka ringkasan (selalu menghasilkan satu baris).
    baris = db.execute(
        select(_JUMLAH, _SELESAI, _MASUK, _KELUAR).where(Kegiatan.tanggal == tanggal)
    ).one()

    # Satu query lagi: pengeluaran per kategori, terbesar di atas.
    per_kategori = db.execute(
        select(Kegiatan.kategori, func.sum(Kegiatan.nominal))
        .where(Kegiatan.tanggal == tanggal, Kegiatan.tipe == Tipe.pengeluaran)
        .group_by(Kegiatan.kategori)
        .order_by(func.sum(Kegiatan.nominal).desc(), Kegiatan.kategori)
    ).all()

    return LaporanHarianOut(
        **_susun(tanggal, baris),
        per_kategori=[
            TotalKategori(kategori=k, total=int(total)) for k, total in per_kategori
        ],
    )


@router.get("/rentang", response_model=list[RingkasanHariOut])
def laporan_rentang(
    mulai: date = Query(description="Tanggal awal, YYYY-MM-DD"),
    sampai: date = Query(description="Tanggal akhir, YYYY-MM-DD"),
    db: Session = Depends(get_db),
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
        .where(Kegiatan.tanggal.between(mulai, sampai))
        .group_by(Kegiatan.tanggal)
    ).all()
    per_hari = {b.tanggal: b for b in baris}

    # Hari tanpa kegiatan tidak ada di hasil query, jadi diisi nilai 0 di sini.
    return [
        RingkasanHariOut(**_susun(hari, per_hari.get(hari)))
        for hari in (mulai + timedelta(days=i) for i in range(jumlah_hari))
    ]
