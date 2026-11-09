from typing import Annotated

import jwt
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select

from ..deps import DbSession, UserAktif
from ..models import User
from ..schemas import GantiPassword, RefreshRequest, Token, UserCreate, UserOut
from ..security import (
    JENIS_REFRESH,
    baca_token,
    buat_access_token,
    buat_refresh_token,
    cek_password,
    hash_password,
)

router = APIRouter(tags=["auth"])


def _pasangan_token(user_id: int) -> Token:
    return Token(
        access_token=buat_access_token(user_id),
        refresh_token=buat_refresh_token(user_id),
    )


@router.post("/auth/register", response_model=UserOut, status_code=status.HTTP_201_CREATED)
def register(data: UserCreate, db: DbSession):
    email = data.email.lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(status.HTTP_409_CONFLICT, "Email sudah terdaftar")
    user = User(
        nama=data.nama.strip(),
        email=email,
        password_hash=hash_password(data.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/auth/login", response_model=Token)
def login(form: Annotated[OAuth2PasswordRequestForm, Depends()], db: DbSession):
    """Login memakai form `username` (berisi email) dan `password`."""
    user = db.scalar(select(User).where(User.email == form.username.lower()))
    # Pesan sengaja sama untuk email salah maupun password salah.
    if user is None or not cek_password(form.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Email atau password salah")
    if not user.aktif:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Akun dinonaktifkan oleh admin")
    return _pasangan_token(user.id)


@router.post("/auth/refresh", response_model=Token)
def refresh(data: RefreshRequest, db: DbSession):
    """Menukar refresh token dengan pasangan token baru.

    Access token dan token rusak/kedaluwarsa ditolak (401); akun yang
    dinonaktifkan admin ditolak (403).
    """
    gagal = HTTPException(
        status.HTTP_401_UNAUTHORIZED,
        "Refresh token tidak valid atau sudah kedaluwarsa",
    )
    try:
        payload = baca_token(data.refresh_token, JENIS_REFRESH)
        user_id = int(payload["sub"])
    except (jwt.InvalidTokenError, KeyError, ValueError):
        raise gagal from None
    user = db.get(User, user_id)
    if user is None:
        raise gagal
    if not user.aktif:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Akun dinonaktifkan oleh admin")
    return _pasangan_token(user.id)


@router.get("/users/me", response_model=UserOut)
def profil_saya(user: UserAktif):
    return user


@router.post("/auth/ganti-password", status_code=status.HTTP_204_NO_CONTENT)
def ganti_password(data: GantiPassword, db: DbSession, user: UserAktif):
    """Wajib login. Password lama harus benar.

    Password lama yang salah dibalas 400 (bukan 401), karena 401 berarti
    "token tidak valid" dan akan membuat aplikasi mengira sesi sudah habis.
    """
    if not cek_password(data.password_lama, user.password_hash):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Password lama salah")
    user.password_hash = hash_password(data.password_baru)
    db.commit()
