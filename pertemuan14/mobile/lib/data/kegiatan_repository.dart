import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/kategori.dart';
import '../models/kegiatan.dart';
import '../models/laporan.dart';
import 'api_kegiatan_repository.dart';
import 'sqlite_kegiatan_repository.dart';

/// Naik setiap kali data berubah. Halaman yang menampilkan data
/// mendengarkan notifier ini lalu memuat ulang datanya.
final ValueNotifier<int> versiData = ValueNotifier<int>(0);

/// Kontrak sumber data kegiatan. Halaman hanya mengenal kelas abstrak ini,
/// sehingga sumber data (SQLite atau API) dapat ditukar tanpa mengubah UI.
abstract class KegiatanRepository {
  /// Kegiatan pada satu tanggal; [q] menyaring berdasarkan judul.
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''});

  Future<Ringkasan> ringkasan(String tanggal);
  Future<LaporanHarian> laporanHarian(String tanggal);
    /// Total satu bulan penuh (hanya tersedia saat memakai server).
  Future<LaporanBulanan> laporanBulanan(int tahun, int bulan);

  /// Ringkasan setiap hari dari [mulai] sampai [sampai], urut dari yang
  /// terlama ke terbaru.
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai);

  /// Pencarian di semua tanggal.
  Future<List<Kegiatan>> cari({
    String kata = '',
    Tipe? tipe,
    String? kategori,
  });

  /// Kategori pengeluaran yang aktif (dari server, atau kategoriBawaan di mode lokal).
  Future<List<Kategori>> daftarKategori();

  /// Menyimpan kegiatan baru dan mengembalikannya lengkap dengan id.
  /// Id dibutuhkan untuk mengunggah foto bukti sesudahnya.
  Future<Kegiatan> tambah(Kegiatan k);
  Future<Kegiatan> ubah(Kegiatan k);
  Future<void> setSelesai(Kegiatan k, bool selesai);
  Future<void> hapus(int id);

  /// Foto bukti struk (hanya tersedia saat memakai server).
  Future<void> unggahBukti(int id, List<int> isi, String namaBerkas);
  Future<void> hapusBukti(int id);
}

/// Repository yang sedang dipakai aplikasi. Test dapat menggantinya
/// dengan repository palsu.
KegiatanRepository repo = modeData == 'lokal'
    ? SqliteKegiatanRepository()
    : ApiKegiatanRepository();