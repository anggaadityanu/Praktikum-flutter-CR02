import os
from datetime import datetime

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from .database import engine

VERSI = "0.1.0"

app = FastAPI(title="TabungKu API", version=VERSI)


@app.get("/")
def beranda():
    return {"pesan": "Selamat datang di TabungKu API. Dokumentasi: /docs"}


@app.get("/info")
def info():
    """Identitas API: nama, versi, dan zona waktu server."""
    return {
        "nama": "TabungKu API",
        "versi": VERSI,
        "zona_waktu": os.getenv("TZ", "UTC"),
    }


@app.get("/health")
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
