from .conftest import daftar_dan_login


def test_skenario_satu_hari_modul_7(client, auth):
    """Contoh Skenario Satu Hari pada modul pertemuan 7."""
    data = [
        ("Kuliah pagi dan makan siang", "pengeluaran", 15000, 1, True),
        ("Pulang naik angkot", "pengeluaran", 10000, 2, True),
        ("Kerja freelance desain poster", "pemasukan", 50000, None, False),
        ("Belajar Flutter di perpustakaan", "tanpa", 0, None, False),
    ]
    for judul, tipe, nominal, kategori_id, selesai in data:
        res = client.post(
            "/kegiatan",
            headers=auth,
            json={
                "judul": judul,
                "tanggal": "2026-10-05",
                "tipe": tipe,
                "nominal": nominal,
                "kategori_id": kategori_id,
                "selesai": selesai,
            },
        )
        assert res.status_code == 201, res.text

    lap = client.get("/laporan/harian", headers=auth, params={"tanggal": "2026-10-05"}).json()
    assert lap["jumlah_kegiatan"] == 4
    assert lap["selesai"] == 2
    assert lap["pemasukan"] == 50000
    assert lap["pengeluaran"] == 25000
    assert lap["tabungan"] == 25000
    assert lap["per_kategori"] == [
        {"kategori": "Makan", "total": 15000},
        {"kategori": "Transport", "total": 10000},
    ]


def test_tanggal_kosong_bernilai_nol(client, auth):
    lap = client.get("/laporan/harian", headers=auth, params={"tanggal": "2000-01-01"}).json()
    assert lap["jumlah_kegiatan"] == 0
    assert lap["tabungan"] == 0
    assert lap["per_kategori"] == []


def test_rentang(client, auth):
    client.post(
        "/kegiatan",
        headers=auth,
        json={"judul": "Gaji", "tanggal": "2026-10-05", "tipe": "pemasukan", "nominal": 100},
    )
    res = client.get(
        "/laporan/rentang", headers=auth, params={"mulai": "2026-10-04", "sampai": "2026-10-06"}
    )
    assert [h["pemasukan"] for h in res.json()] == [0, 100, 0]

    terlalu_panjang = {"mulai": "2026-01-01", "sampai": "2026-03-01"}
    res = client.get("/laporan/rentang", headers=auth, params=terlalu_panjang)
    assert res.status_code == 400


# ---------------------------------------------------------------- bulanan


def _tambah(client, auth, judul, tanggal, tipe, nominal=0, kategori_id=None, selesai=False):
    res = client.post(
        "/kegiatan",
        headers=auth,
        json={
            "judul": judul,
            "tanggal": tanggal,
            "tipe": tipe,
            "nominal": nominal,
            "kategori_id": kategori_id,
            "selesai": selesai,
        },
    )
    assert res.status_code == 201, res.text


def test_laporan_bulanan(client, auth):
    # Tanggal 5: tabungan 25.000 (>= target 20.000). Tanggal 6: tabungan 5.000.
    _tambah(client, auth, "Gaji", "2026-10-05", "pemasukan", 50000, selesai=True)
    _tambah(client, auth, "Makan", "2026-10-05", "pengeluaran", 15000, 1)
    _tambah(client, auth, "Angkot", "2026-10-05", "pengeluaran", 10000, 2)
    _tambah(client, auth, "Uang saku", "2026-10-06", "pemasukan", 10000)
    _tambah(client, auth, "Kopi", "2026-10-06", "pengeluaran", 5000, 1)
    # Bulan lain tidak boleh ikut terhitung.
    _tambah(client, auth, "November", "2026-11-01", "pengeluaran", 99000, 3)

    res = client.get("/laporan/bulanan", headers=auth, params={"tahun": 2026, "bulan": 10})
    assert res.status_code == 200
    lap = res.json()
    assert lap["jumlah_hari"] == 31
    assert lap["jumlah_kegiatan"] == 5
    assert lap["selesai"] == 1
    assert lap["pemasukan"] == 60000
    assert lap["pengeluaran"] == 30000
    assert lap["tabungan"] == 30000
    assert lap["hari_target_tercapai"] == 1
    assert lap["per_kategori"] == [
        {"kategori": "Makan", "total": 20000},
        {"kategori": "Transport", "total": 10000},
    ]


def test_bulanan_februari_kabisat_dan_validasi(client, auth):
    res = client.get("/laporan/bulanan", headers=auth, params={"tahun": 2028, "bulan": 2})
    assert res.json()["jumlah_hari"] == 29

    for bulan in (0, 13):
        res = client.get("/laporan/bulanan", headers=auth, params={"tahun": 2026, "bulan": bulan})
        assert res.status_code == 422


def test_bulanan_hari_depan_tidak_dihitung_dan_perlu_login(client, auth):
    res = client.get("/laporan/bulanan", headers=auth, params={"tahun": 2100, "bulan": 1})
    assert res.json()["hari_target_tercapai"] == 0
    assert client.get("/laporan/bulanan", params={"tahun": 2026, "bulan": 10}).status_code == 401


# ------------------------------------------------------------------- CSV


def test_ekspor_csv(client, auth):
    _tambah(client, auth, "Makan, siang", "2026-10-06", "pengeluaran", 15000, 1, selesai=True)
    _tambah(client, auth, "Gaji", "2026-10-05", "pemasukan", 50000)
    _tambah(client, auth, "Di luar rentang", "2026-12-01", "pemasukan", 1)

    res = client.get(
        "/laporan/ekspor.csv", headers=auth, params={"mulai": "2026-10-01", "sampai": "2026-10-31"}
    )
    assert res.status_code == 200
    assert res.headers["content-type"].startswith("text/csv")
    assert "attachment" in res.headers["content-disposition"]
    assert "tabungku_2026-10-01_2026-10-31.csv" in res.headers["content-disposition"]

    baris = res.text.strip().splitlines()
    assert baris[0] == "tanggal,judul,tipe,kategori,nominal,selesai"
    assert len(baris) == 3  # judul + 2 kegiatan, yang di luar rentang tidak ikut
    assert baris[1] == "2026-10-05,Gaji,pemasukan,-,50000,0"
    # Koma di dalam judul harus dibungkus tanda kutip oleh modul csv.
    assert baris[2] == '2026-10-06,"Makan, siang",pengeluaran,Makan,15000,1'


def test_ekspor_csv_mencegah_injeksi_rumus(client, auth):
    _tambah(client, auth, "=1+1", "2026-10-06", "pemasukan", 1000)
    res = client.get(
        "/laporan/ekspor.csv", headers=auth, params={"mulai": "2026-10-06", "sampai": "2026-10-06"}
    )
    assert "'=1+1" in res.text


def test_ekspor_csv_validasi_rentang_dan_data_antar_pengguna(client, auth):
    def minta(mulai, sampai):
        return client.get(
            "/laporan/ekspor.csv", headers=auth, params={"mulai": mulai, "sampai": sampai}
        )

    assert minta("2026-10-10", "2026-10-01").status_code == 400  # terbalik
    assert minta("2025-01-01", "2026-12-31").status_code == 400  # > 366 hari
    assert minta("2026-01-01", "2026-12-31").status_code == 200  # 365 hari

    # Data pengguna lain tidak ikut terekspor.
    _tambah(client, auth, "Rahasia", "2026-10-06", "pemasukan", 1000)
    ani = daftar_dan_login(client, "ani@contoh.id")
    res = client.get(
        "/laporan/ekspor.csv", headers=ani, params={"mulai": "2026-10-01", "sampai": "2026-10-31"}
    )
    assert "Rahasia" not in res.text