import os

from fastapi import FastAPI

from .routers import auth, health, kegiatan, laporan

VERSI = "0.3.0"

app = FastAPI(title="TabungKu API", version=VERSI)
app.include_router(health.router)
app.include_router(auth.router)
app.include_router(kegiatan.router)
app.include_router(laporan.router)


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
