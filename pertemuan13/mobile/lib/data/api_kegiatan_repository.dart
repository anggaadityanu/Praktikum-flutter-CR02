import '../models/kategori.dart';
import '../models/kegiatan.dart';
import '../models/laporan.dart';
import '../services/kategori_api.dart';
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
  final KategoriApi _kategori;

  ApiKegiatanRepository({
    KegiatanApi? kegiatan,
    LaporanApi? laporan,
    KategoriApi? kategori,
  })  : _kegiatan = kegiatan ?? KegiatanApi(),
        _laporan = laporan ?? LaporanApi(),
        _kategori = kategori ?? KategoriApi();

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

  @override
  Future<LaporanBulanan> laporanBulanan(int tahun, int bulan) =>
      _laporan.bulanan(tahun, bulan);

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
  Future<List<Kategori>> daftarKategori() => _kategori.daftar();

  @override
  Future<Kegiatan> tambah(Kegiatan k) async {
    final baru = await _kegiatan.tambah(k);
    versiData.value++;
    return baru;
  }

  @override
  Future<Kegiatan> ubah(Kegiatan k) async {
    final baru = await _kegiatan.ubah(k);
    versiData.value++;
    return baru;
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

  @override
  Future<void> unggahBukti(int id, List<int> isi, String namaBerkas) async {
    await _kegiatan.unggahBukti(id, isi, namaBerkas);
    versiData.value++;
  }

  @override
  Future<void> hapusBukti(int id) async {
    await _kegiatan.hapusBukti(id);
    versiData.value++;
  }
}