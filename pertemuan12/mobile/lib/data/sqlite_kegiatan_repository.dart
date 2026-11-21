import '../models/kategori.dart';
import '../models/kegiatan.dart';
import '../models/laporan.dart';
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
  Future<void> tambah(Kegiatan k) async {
    await DbHelper.tambah(k);
    versiData.value++;
  }

  @override
  Future<void> ubah(Kegiatan k) async {
    await DbHelper.ubah(k);
    versiData.value++;
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
}