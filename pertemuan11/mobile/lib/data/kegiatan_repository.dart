import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
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

  /// Ringkasan setiap hari dari [mulai] sampai [sampai], urut dari yang
  /// terlama ke terbaru.
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai);

  /// Pencarian di semua tanggal.
  Future<List<Kegiatan>> cari({
    String kata = '',
    Tipe? tipe,
    String? kategori,
  });

  Future<void> tambah(Kegiatan k);
  Future<void> ubah(Kegiatan k);
  Future<void> setSelesai(Kegiatan k, bool selesai);
  Future<void> hapus(int id);
}

/// Repository yang sedang dipakai aplikasi. Test dapat menggantinya
/// dengan repository palsu.
KegiatanRepository repo = modeData == 'lokal'
    ? SqliteKegiatanRepository()
    : ApiKegiatanRepository();
