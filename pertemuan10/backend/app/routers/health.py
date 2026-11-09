from datetime import datetime

from fastapi import APIRouter
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from ..database import engine

router = APIRouter(tags=["health"])


@router.get("/health")
def health():
    """Memeriksa API sekaligus koneksi ke database.

    Sehat  -> 200 dengan versi MySQL.
    Rusak  -> 503: API masih hidup, tetapi database tidak dapat dihubungi.
    """
    waktu = datetime.now().isoformat(timespec="seconds")
    try:
        with engine.connect() as koneksi:
            versi = koneksi.execute(text("SELECT VERSION()")).scalar()
    except SQLAlchemyError:
        return JSONResponse(
            status_code=503,
            content={
                "status": "degraded",
                "waktu_server": waktu,
                "database": "error",
                "mysql_version": None,
                "detail": "Tidak dapat terhubung ke database MySQL.",
            },
        )
    return {
        "status": "ok",
        "waktu_server": waktu,
        "database": "ok",
        "mysql_version": versi,
    }
