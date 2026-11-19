import '../models/kegiatan.dart';
import '../models/laporan.dart';
import '../services/kegiatan_api.dart';
import '../services/laporan_api.dart';
import '../utils/format.dart';
import 'kegiatan_repository.dart';

/// Sumber data dari server (FastAPI). Operasi tulis menaikkan [versiData]
/// hanya SETELAH server menjawab berhasil; bila gagal, pengecualian dilempar
/// ke halaman dan tampilan tidak berubah.
class ApiKegiatanRepository implements KegiatanRepository {
  final KegiatanApi _kegiatan;
  final LaporanApi _laporan;

  ApiKegiatanRepository({KegiatanApi? kegiatan, LaporanApi? laporan})
      : _kegiatan = kegiatan ?? KegiatanApi(),
        _laporan = laporan ?? LaporanApi();

  @override
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''}) {
    final kata = q.trim();
    return _kegiatan.daftar(tanggal: tanggal, q: kata.isEmpty ? null : kata);
  }

  @override
  Future<Ringkasan> ringkasan(String tanggal) async =>
      (await _laporan.harian(tanggal)).ringkasan;

  @override
  Future<LaporanHarian> laporanHarian(String tanggal) =>
      _laporan.harian(tanggal);

  /// Satu request untuk seluruh rentang, bukan satu request per hari.
  @override
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai) =>
      _laporan.rentang(kunciTanggal(mulai), kunciTanggal(sampai));

  @override
  Future<List<Kegiatan>> cari({
    String kata = '',
    Tipe? tipe,
    String? kategori,
  }) async {
    final bersih = kata.trim();
    final hasil = await _kegiatan.daftar(
      q: bersih.isEmpty ? null : bersih,
      tipe: tipe,
      urut: 'terbaru',
      limit: 200,
    );
    // Server belum punya filter kategori, jadi disaring di sini.
    if (kategori == null) return hasil;
    return hasil.where((k) => k.kategori == kategori).toList();
  }

  @override
  Future<void> tambah(Kegiatan k) async {
    await _kegiatan.tambah(k);
    versiData.value++;
  }

  @override
  Future<void> ubah(Kegiatan k) async {
    await _kegiatan.ubah(k);
    versiData.value++;
  }

  @override
  Future<void> setSelesai(Kegiatan k, bool selesai) async {
    await _kegiatan.setSelesai(k.id!, selesai);
    versiData.value++;
  }

  @override
  Future<void> hapus(int id) async {
    await _kegiatan.hapus(id);
    versiData.value++;
  }
}
