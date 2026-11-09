import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/kegiatan.dart';
import '../utils/format.dart';

/// Dinaikkan setiap ada tambah/ubah/hapus. Halaman yang menampilkan
/// data mendengarkan ini untuk memuat ulang tampilannya.
final ValueNotifier<int> versiData = ValueNotifier<int>(0);

class DbHelper {
  DbHelper._();

  static Future<Database>? _bukaDb;
  static Future<Database> get _database => _bukaDb ??= _buka();

  static Future<Database> _buka() async {
    final folder = await getDatabasesPath();
    return openDatabase(
      p.join(folder, 'tabungku.db'),
      version: 1,
      onCreate: (db, versi) async {
        await db.execute('''
          CREATE TABLE kegiatan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            judul TEXT NOT NULL,
            tanggal TEXT NOT NULL,
            selesai INTEGER NOT NULL DEFAULT 0,
            tipe TEXT NOT NULL,
            nominal INTEGER NOT NULL DEFAULT 0,
            kategori TEXT NOT NULL DEFAULT '-'
          )
        ''');
      },
    );
  }

  // ---------- CRUD ----------

  static Future<int> tambah(Kegiatan k) async {
    final db = await _database;
    final id = await db.insert('kegiatan', k.toMap()..remove('id'));
    versiData.value++;
    return id;
  }

  static Future<void> ubah(Kegiatan k) async {
    final db = await _database;
    await db.update(
      'kegiatan',
      k.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [k.id],
    );
    versiData.value++;
  }

  static Future<void> setSelesai(int id, bool selesai) async {
    final db = await _database;
    await db.update(
      'kegiatan',
      {'selesai': selesai ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    versiData.value++;
  }

  static Future<void> hapus(int id) async {
    final db = await _database;
    await db.delete('kegiatan', where: 'id = ?', whereArgs: [id]);
    versiData.value++;
  }

  /// Semua kegiatan pada satu tanggal (yang belum selesai di atas).
  static Future<List<Kegiatan>> pada(String tanggal) async {
    final db = await _database;
    final baris = await db.query(
      'kegiatan',
      where: 'tanggal = ?',
      whereArgs: [tanggal],
      orderBy: 'selesai ASC, id ASC',
    );
    return baris.map(Kegiatan.fromMap).toList();
  }

  // ---------- LAPORAN ----------

  /// Satu query menghasilkan seluruh angka ringkasan satu hari.
  /// COALESCE mengganti NULL (saat tidak ada data) dengan 0.
  static Future<Ringkasan> ringkasan(String tanggal) async {
    final db = await _database;
    final hasil = await db.rawQuery('''
      SELECT COUNT(*) AS jumlah,
             COALESCE(SUM(selesai), 0) AS selesai,
             COALESCE(SUM(CASE WHEN tipe = 'pemasukan'
                               THEN nominal END), 0) AS masuk,
             COALESCE(SUM(CASE WHEN tipe = 'pengeluaran'
                               THEN nominal END), 0) AS keluar
      FROM kegiatan
      WHERE tanggal = ?
    ''', [tanggal]);
    final baris = hasil.first;
    return Ringkasan(
      jumlahKegiatan: baris['jumlah'] as int,
      selesai: baris['selesai'] as int,
      pemasukan: baris['masuk'] as int,
      pengeluaran: baris['keluar'] as int,
    );
  }

  /// Total pengeluaran per kategori pada satu hari, terbesar di atas.
  static Future<List<TotalKategori>> pengeluaranPerKategori(
      String tanggal) async {
    final db = await _database;
    final hasil = await db.rawQuery('''
      SELECT kategori, SUM(nominal) AS total
      FROM kegiatan
      WHERE tanggal = ? AND tipe = 'pengeluaran'
      GROUP BY kategori
      ORDER BY total DESC
    ''', [tanggal]);
    return hasil
        .map((b) => TotalKategori(
              kategori: b['kategori'] as String,
              total: b['total'] as int,
            ))
        .toList();
  }

  /// Ringkasan 7 hari yang berakhir pada [akhir] (terbaru di atas).
  /// Hari tanpa kegiatan tetap ada dengan nilai 0.
  static Future<List<RingkasanHari>> tujuhHari(DateTime akhir) async {
    final db = await _database;
    final awal = DateTime(akhir.year, akhir.month, akhir.day - 6);
    final hasil = await db.rawQuery('''
      SELECT tanggal,
             COUNT(*) AS jumlah,
             COALESCE(SUM(selesai), 0) AS selesai,
             COALESCE(SUM(CASE WHEN tipe = 'pemasukan'
                               THEN nominal END), 0) AS masuk,
             COALESCE(SUM(CASE WHEN tipe = 'pengeluaran'
                               THEN nominal END), 0) AS keluar
      FROM kegiatan
      WHERE tanggal BETWEEN ? AND ?
      GROUP BY tanggal
    ''', [kunciTanggal(awal), kunciTanggal(akhir)]);

    final peta = <String, Ringkasan>{};
    for (final b in hasil) {
      peta[b['tanggal'] as String] = Ringkasan(
        jumlahKegiatan: b['jumlah'] as int,
        selesai: b['selesai'] as int,
        pemasukan: b['masuk'] as int,
        pengeluaran: b['keluar'] as int,
      );
    }

    final daftar = <RingkasanHari>[];
    for (var i = 0; i < 7; i++) {
      final hari = DateTime(akhir.year, akhir.month, akhir.day - i);
      daftar.add(RingkasanHari(
        tanggal: hari,
        ringkasan: peta[kunciTanggal(hari)] ??
            const Ringkasan(
              jumlahKegiatan: 0,
              selesai: 0,
              pemasukan: 0,
              pengeluaran: 0,
            ),
      ));
    }
    return daftar;
    }

  // ---------- PENCARIAN ----------

  /// Cari di semua tanggal. Semua syarat bersifat opsional dan digabung AND.
  /// LIKE di SQLite tidak membedakan huruf besar/kecil untuk huruf ASCII.
  static Future<List<Kegiatan>> cari({
    String kata = '',
    Tipe? tipe,
    String? kategori,
  }) async {
    final db = await _database;
    final syarat = <String>[];
    final args = <Object?>[];

    if (kata.trim().isNotEmpty) {
      syarat.add('judul LIKE ?');
      args.add('%${kata.trim()}%');
    }
    if (tipe != null) {
      syarat.add('tipe = ?');
      args.add(tipe.name);
    }
    if (kategori != null) {
      syarat.add('kategori = ?');
      args.add(kategori);
    }

    final baris = await db.query(
      'kegiatan',
      where: syarat.isEmpty ? null : syarat.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'tanggal DESC, id DESC',
      limit: 200,
    );
    return baris.map(Kegiatan.fromMap).toList();
  }
}