from datetime import datetime, timedelta, timezone

import jwt
from pwdlib import PasswordHash

from .config import settings

# Argon2: algoritma hash password yang direkomendasikan saat ini.
_hasher = PasswordHash.recommended()

JENIS_ACCESS = "access"
JENIS_REFRESH = "refresh"


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def cek_password(password: str, hash_tersimpan: str) -> bool:
    return _hasher.verify(password, hash_tersimpan)


def _buat_token(user_id: int, jenis: str, umur: timedelta) -> str:
    sekarang = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),  # subject: pemilik token
        "jenis": jenis,  # access atau refresh
        "iat": sekarang,  # issued at
        "exp": sekarang + umur,  # expired at
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algoritma)


def buat_access_token(user_id: int) -> str:
    return _buat_token(
        user_id, JENIS_ACCESS, timedelta(minutes=settings.access_token_menit)
    )


def buat_refresh_token(user_id: int) -> str:
    return _buat_token(
        user_id, JENIS_REFRESH, timedelta(days=settings.refresh_token_hari)
    )


def baca_token(token: str, jenis: str) -> dict:
    """Membaca token dan memastikan jenisnya sesuai.

    Melempar jwt.InvalidTokenError bila token rusak, palsu, kedaluwarsa,
    atau jenisnya salah (misalnya refresh token dipakai sebagai access token).
    """
    payload = jwt.decode(
        token, settings.jwt_secret, algorithms=[settings.jwt_algoritma]
    )
    if payload.get("jenis") != jenis:
        raise jwt.InvalidTokenError("jenis token tidak sesuai")
    return payload
