import 'kegiatan.dart';

/// Membaca daftar `per_kategori` dari JSON laporan server.
List<TotalKategori> _bacaKategori(List<dynamic> data) => data.map((e) {
      final m = e as Map<String, dynamic>;
      return TotalKategori(
        kategori: m['kategori'] as String,
        total: m['total'] as int,
      );
    }).toList();

/// Laporan satu hari dari GET /laporan/harian.
class LaporanHarian {
  final String tanggal; // yyyy-MM-dd
  final Ringkasan ringkasan;
  final List<TotalKategori> perKategori; // terbesar di atas

  const LaporanHarian({
    required this.tanggal,
    required this.ringkasan,
    required this.perKategori,
  });

  factory LaporanHarian.fromJson(Map<String, dynamic> j) => LaporanHarian(
        tanggal: j['tanggal'] as String,
        ringkasan: Ringkasan.fromJson(j),
        perKategori: _bacaKategori(j['per_kategori'] as List<dynamic>),
      );
}

/// Laporan satu bulan dari GET /laporan/bulanan.
class LaporanBulanan {
  final int tahun;
  final int bulan;
  final int jumlahHari;

  /// Berapa hari (yang sudah lewat) tabungannya mencapai target harian.
  final int hariTargetTercapai;
  final Ringkasan ringkasan;
  final List<TotalKategori> perKategori;

  const LaporanBulanan({
    required this.tahun,
    required this.bulan,
    required this.jumlahHari,
    required this.hariTargetTercapai,
    required this.ringkasan,
    required this.perKategori,
  });

  factory LaporanBulanan.fromJson(Map<String, dynamic> j) => LaporanBulanan(
        tahun: j['tahun'] as int,
        bulan: j['bulan'] as int,
        jumlahHari: j['jumlah_hari'] as int,
        hariTargetTercapai: j['hari_target_tercapai'] as int,
        ringkasan: Ringkasan.fromJson(j),
        perKategori: _bacaKategori(j['per_kategori'] as List<dynamic>),
      );
}