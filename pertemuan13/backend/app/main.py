import os

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .config import settings
from .routers import auth, health, kategori, kegiatan, laporan

VERSI = "0.5.0"

app = FastAPI(title="TabungKu API", version=VERSI)
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(kategori.router)
app.include_router(kegiatan.router)
app.include_router(laporan.router)
# Foto bukti bisa dibuka langsung: GET /uploads/<nama-berkas>.
# Nama berkas acak (UUID), jadi tidak bisa ditebak orang lain.
os.makedirs(settings.upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")


@app.get("/", tags=["umum"])
def beranda():
    return {"pesan": "Selamat datang di TabungKu API. Dokumentasi: /docs"}


@app.get("/info", tags=["umum"])
def info():
    """Identitas API: nama, versi, dan zona waktu server."""
    return {
        "nama": "TabungKu API",
        "versi": VERSI,
        "zona_waktu": os.getenv("TZ", "UTC"),
    }