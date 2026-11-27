# Pertemuan 14 — Produksi, Keamanan, dan CI

![CI](https://github.com/anggaadityanu/Praktikum-flutter-CR02/actions/workflows/ci.yml/badge.svg)

Pertemuan ini membawa **TabungKu** dari mode pengembangan ke mode siap produksi:
konfigurasi yang diperkeras, Nginx sebagai pintu masuk tunggal, pengujian otomatis
lewat GitHub Actions, serta prosedur cadangan (backup) dan pemulihan (restore).

## Ringkasan Fitur

| Area | Yang dikerjakan |
|---|---|
| Backend | Validasi rahasia JWT di produksi, `/docs` dimatikan, uvicorn multi-worker, pengguna non-root |
| Reverse proxy | Nginx menjadi satu-satunya port publik: `/api/` ke API, `/` ke dashboard admin |
| Keamanan | Rate limit login, batas ukuran body, header keamanan, port database tidak dibuka |
| Admin | Mode produksi (`APP_DEBUG=false`, cache konfigurasi, tanpa paket dev) |
| Data | Skrip backup dan restore untuk database dan folder unggahan |
| Kualitas | Lint `ruff`, `pytest` + coverage, `flutter analyze` dan `flutter test` |
| CI | GitHub Actions: backend, mobile, dan build image Docker produksi |
| Rilis | APK release dengan alamat API diatur lewat `--dart-define` |

## Struktur Folder

```
pertemuan14/
├── backend/            # FastAPI + Alembic + tes pytest
│   ├── pyproject.toml  # konfigurasi ruff dan coverage
│   └── requirements-dev.txt
├── admin/              # Laravel + Filament
├── mobile/             # aplikasi Flutter
├── nginx/default.conf  # reverse proxy produksi
├── scripts/            # backup.sh dan restore.sh
├── docker-compose.yml       # mode pengembangan
├── docker-compose.prod.yml  # mode produksi (project tabungku-prod)
└── .env.example             # contoh variabel lingkungan
```

Di root repositori ada `.github/workflows/ci.yml`.

## Menjalankan Mode Produksi

1. Salin contoh konfigurasi, lalu isi dengan rahasia yang kuat:

   ```bash
   cp .env.example .env.prod
   ```

   Nilai penting di `.env.prod`:

   | Variabel | Keterangan |
   |---|---|
   | `APP_ENV` | `production` |
   | `JWT_SECRET` | acak, minimal 32 karakter (aplikasi menolak start bila lemah) |
   | `PUBLIC_URL` | alamat publik, contoh `http://localhost:8088` |
   | `HTTP_PORT` | port Nginx di host, contoh `8088` |

   File `.env.prod` **tidak boleh** di-commit (sudah ada di `.gitignore`).

2. Jalankan:

   ```bash
   docker compose -f docker-compose.prod.yml --env-file .env.prod up -d --build
   ```

3. Buka:

   | Alamat | Isi |
   |---|---|
   | `http://localhost:8088/` | Dashboard admin |
   | `http://localhost:8088/api/health` | Cek kesehatan API |
   | `http://localhost:8088/api/docs` | Tidak tersedia (404) karena dimatikan di produksi |

## Pengerasan Keamanan

| # | Langkah | Cara kerja |
|---|---|---|
| 1 | Rahasia JWT divalidasi | `config.py` menolak nilai bawaan atau kurang dari 32 karakter saat `APP_ENV=production` |
| 2 | Dokumentasi API dimatikan | `docs_url` dan `openapi_url` bernilai `None` di produksi |
| 3 | Pengguna non-root | Container API berjalan sebagai user `app` (uid 1000) |
| 4 | Tanpa paket pengembangan | Image produksi dibangun dengan `INSTALL_DEV=false` dan `COMPOSER_NO_DEV=1` |
| 5 | Rate limit login | Nginx membatasi `/api/auth/login` 5 permintaan per menit (burst 3), respons `429` |
| 6 | Batas ukuran body | `client_max_body_size 3m` |
| 7 | Header keamanan | Dipasang di Nginx, `server_tokens off` menyembunyikan versi |
| 8 | Port database tertutup | MySQL tidak dipublikasikan ke host, hanya terjangkau dari jaringan Docker |
| 9 | Debug dimatikan | `APP_DEBUG=false` pada admin |
| 10 | Proxy dipercaya dengan benar | uvicorn memakai `--proxy-headers`, Laravel memakai `trustProxies` |

### Daftar periksa hasil uji

- [x] `/api/docs` mengembalikan 404 di mode produksi
- [x] Login lebih dari 5 kali dalam semenit menghasilkan `429`
- [x] Unggahan lebih dari 3 MB ditolak
- [x] API tidak bisa dijalankan dengan `JWT_SECRET` bawaan
- [x] Port MySQL tidak bisa diakses dari luar container
- [x] Header keamanan muncul pada respons Nginx

## Backup dan Restore

Skrip menerima dua argumen opsional: berkas compose dan berkas env.

```bash
# Cadangkan database dan folder unggahan
./scripts/backup.sh docker-compose.prod.yml .env.prod
```

Hasilnya masuk ke folder `backups/`:

- `db-WAKTU.sql.gz`: dump database MySQL
- `uploads-WAKTU.tar.gz`: arsip foto bukti

```bash
# Pulihkan dari cadangan
./scripts/restore.sh docker-compose.prod.yml .env.prod
```

Folder `backups/` masuk `.gitignore` karena berisi data asli.

- [x] Backup berhasil membuat dua berkas di `backups/`
- [x] Restore mengembalikan data setelah data sengaja dihapus

## Kualitas Kode dan Pengujian

Jalankan di dalam `backend/` (disarankan memakai virtual environment):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt ruff

ruff check .
pytest --cov
```

Hasil: `All checks passed!` dari ruff dan **32 tes lolos**.

Aturan lint ada di `backend/pyproject.toml` (aturan `E`, `F`, `I`, `B`, panjang baris 100).

Di `mobile/`:

```bash
flutter analyze
flutter test
```

Hasil: tidak ada isu, **96 tes lolos**.

## Continuous Integration

Berkas `.github/workflows/ci.yml` berjalan pada setiap `push` ke `main` dan setiap pull request.

| Job | Isi | Syarat |
|---|---|---|
| `backend` | pasang dependensi, `ruff check`, `pytest --cov` | |
| `mobile` | `flutter pub get`, `flutter analyze`, `flutter test` (Flutter 3.24.3) | |
| `docker` | build image API dan Admin versi produksi | menunggu `backend` dan `mobile` hijau |

Job `docker` tidak memerlukan `.env.prod`, sehingga rahasia tidak pernah dikirim ke GitHub.

Hasil run terakhir: ketiga job **berstatus sukses** (backend, mobile, docker).

### Masalah yang ditemui

| Masalah | Penyebab | Solusi |
|---|---|---|
| `pip install` ditolak (`externally-managed-environment`) | Ubuntu melarang pemasangan ke Python sistem | Memakai virtual environment (`python3 -m venv .venv`) |
| Pembuatan venv gagal (`ensurepip`) | Paket `python3.12-venv` belum ada | `sudo apt install python3.12-venv` |
| 917 berkas siap di-commit | Folder `.venv` ikut ter-add | Menambahkan `.venv/` ke `.gitignore`, lalu `git reset` dan `git add .` ulang |
| `mobile` gagal di CI | `flutter analyze` menemukan `import 'dart:async'` yang tidak terpakai | Menghapus baris import tersebut |

## Membuat APK Release

Pada perangkat asli, alamat `10.0.2.2` tidak berlaku (itu khusus emulator). Gunakan IP laptop di jaringan WiFi yang sama dan lewat Nginx:

```bash
cd mobile
flutter build apk --release --dart-define=API_URL=http://192.168.1.23:8088/api
```

Ganti `192.168.1.23` dengan IP laptop. Hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`.
Alamat juga dapat diubah dari halaman **Pengaturan** di aplikasi tanpa build ulang.

## Yang Dipelajari

- Perbedaan konfigurasi pengembangan dan produksi, dan mengapa rahasia harus divalidasi saat start.
- Reverse proxy sebagai satu pintu masuk: rate limit, batas ukuran, dan header keamanan diatur di satu tempat.
- Menjaga rahasia dan sampah (`.env.prod`, `.venv`, `backups/`) agar tidak masuk repositori.
- CI memastikan lint, tes, dan build berjalan otomatis setiap perubahan.
- Backup yang belum pernah diuji restore belum bisa disebut backup.