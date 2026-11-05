import 'kegiatan.dart';

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
        perKategori: (j['per_kategori'] as List<dynamic>).map((e) {
          final m = e as Map<String, dynamic>;
          return TotalKategori(
            kategori: m['kategori'] as String,
            total: m['total'] as int,
          );
        }).toList(),
      );
}
