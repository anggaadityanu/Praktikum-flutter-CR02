import '../data/kegiatan_repository.dart';
import 'format.dart';

class HasilUkur {
  final int berurutanMs;
  final int paralelMs;
  final int ulang;

  const HasilUkur({
    required this.berurutanMs,
    required this.paralelMs,
    required this.ulang,
  });
}

/// Membandingkan dua cara memuat halaman Laporan: dua request satu per satu
/// (jumlah waktunya) dan dengan Future.wait (kira-kira sebesar yang terlama).
/// Hasilnya adalah rata-rata dari [ulang] kali pengukuran.
Future<HasilUkur> ukurLaporan(
  KegiatanRepository r, {
  DateTime? hari,
  int ulang = 3,
}) async {
  final basis = hari ?? DateTime.now();
  final tanggal = kunciTanggal(basis);
  final awal = DateTime(basis.year, basis.month, basis.day - 6);

  Future<int> ukur(Future<void> Function() kerja) async {
    final jam = Stopwatch()..start();
    await kerja();
    jam.stop();
    return jam.elapsedMilliseconds;
  }

  // Pemanasan sekali, supaya biaya membuka koneksi tidak ikut terhitung.
  await r.laporanHarian(tanggal);

  var berurutan = 0;
  var paralel = 0;
  for (var i = 0; i < ulang; i++) {
    berurutan += await ukur(() async {
      await r.laporanHarian(tanggal);
      await r.rentang(awal, basis);
    });
    paralel += await ukur(() async {
      await Future.wait([r.laporanHarian(tanggal), r.rentang(awal, basis)]);
    });
  }
  return HasilUkur(
    berurutanMs: berurutan ~/ ulang,
    paralelMs: paralel ~/ ulang,
    ulang: ulang,
  );
}
