import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .config import settings
from .routers import auth, health, kategori, kegiatan, laporan

VERSI = "1.0.0"

app = FastAPI(
    title="TabungKu API",
    version=VERSI,
    # Di produksi dokumentasi dimatikan agar daftar endpoint tidak terbuka.
    docs_url=None if settings.produksi else "/docs",
    redoc_url=None,
    openapi_url=None if settings.produksi else "/openapi.json",
)

# CORS hanya dipasang bila diatur (dibutuhkan Flutter Web, bukan Android/iOS).
if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[o.strip() for o in settings.cors_origins.split(",")],
        allow_methods=["*"],
        allow_headers=["Authorization", "Content-Type"],
    )

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(kategori.router)
app.include_router(kegiatan.router)
app.include_router(laporan.router)

# Foto bukti bisa dibuka langsung: GET /uploads/<nama-berkas>.
os.makedirs(settings.upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")


@app.get("/", tags=["umum"])
def beranda():
    return {"pesan": "Selamat datang di TabungKu API"}


@app.get("/info", tags=["umum"])
def info():
    """Identitas API: nama, versi, dan zona waktu server."""
    return {
        "nama": "TabungKu API",
        "versi": VERSI,
        "zona_waktu": os.getenv("TZ", "UTC"),
    }