import '../models/kategori.dart';
import '../models/kegiatan.dart';
import '../models/laporan.dart';
import '../services/api_exception.dart';
import '../utils/format.dart';
import 'db_helper.dart';
import 'kegiatan_repository.dart';

/// Sumber data lokal (SQLite) seperti pertemuan 7.
class SqliteKegiatanRepository implements KegiatanRepository {
  @override
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''}) async {
    final semua = await DbHelper.pada(tanggal);
    final kata = q.trim().toLowerCase();
    if (kata.isEmpty) return semua;
    return semua.where((k) => k.judul.toLowerCase().contains(kata)).toList();
  }

  @override
  Future<Ringkasan> ringkasan(String tanggal) => DbHelper.ringkasan(tanggal);

  @override
  Future<LaporanHarian> laporanHarian(String tanggal) async {
    final ringkasan = await DbHelper.ringkasan(tanggal);
    final kategori = await DbHelper.pengeluaranPerKategori(tanggal);
    return LaporanHarian(
      tanggal: tanggal,
      ringkasan: ringkasan,
      perKategori: kategori,
    );
  }

  @override
  Future<LaporanBulanan> laporanBulanan(int tahun, int bulan) =>
      Future.error(const ApiException('Laporan bulanan hanya tersedia saat memakai server'));

  /// SQLite: satu query per hari (bandingkan dengan API yang cukup satu request).
  @override
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai) async {
    final hasil = <RingkasanHari>[];
    for (var d = DateTime(mulai.year, mulai.month, mulai.day);
        !d.isAfter(sampai);
        d = DateTime(d.year, d.month, d.day + 1)) {
      hasil.add(RingkasanHari(
        tanggal: d,
        ringkasan: await DbHelper.ringkasan(kunciTanggal(d)),
      ));
    }
    return hasil;
  }

  @override
  Future<List<Kegiatan>> cari({
    String kata = '',
    Tipe? tipe,
    String? kategori,
  }) =>
      DbHelper.cari(kata: kata, tipe: tipe, kategori: kategori);

  /// Mode lokal tidak punya server, jadi memakai daftar bawaan.
  @override
  Future<List<Kategori>> daftarKategori() async => kategoriBawaan;

  @override
  Future<Kegiatan> tambah(Kegiatan k) async {
    final id = await DbHelper.tambah(k);
    versiData.value++;
    return Kegiatan(
      id: id,
      judul: k.judul,
      tanggal: k.tanggal,
      selesai: k.selesai,
      tipe: k.tipe,
      nominal: k.nominal,
      kategori: k.kategori,
      kategoriId: k.kategoriId,
    );
  }

  @override
  Future<Kegiatan> ubah(Kegiatan k) async {
    await DbHelper.ubah(k);
    versiData.value++;
    return k;
  }

  @override
  Future<void> setSelesai(Kegiatan k, bool selesai) async {
    await DbHelper.setSelesai(k.id!, selesai);
    versiData.value++;
  }

  @override
  Future<void> hapus(int id) async {
    await DbHelper.hapus(id);
    versiData.value++;
  }

  /// Foto struk disimpan di server, jadi tidak tersedia di mode lokal.
  static const _hanyaServer = ApiException(
    'Bukti struk hanya tersedia saat memakai server',
  );

  @override
  Future<void> unggahBukti(int id, List<int> isi, String namaBerkas) =>
      Future.error(_hanyaServer);

  @override
  Future<void> hapusBukti(int id) => Future.error(_hanyaServer);
}