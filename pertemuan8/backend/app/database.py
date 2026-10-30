from sqlalchemy import create_engine

from .config import settings

# pool_pre_ping: cek koneksi sebelum dipakai, berguna bila MySQL sempat restart.
# connect_timeout: menyerah dalam 3 detik bila MySQL tidak dapat dihubungi.
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 3},
)
