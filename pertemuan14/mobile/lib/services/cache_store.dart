import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Satu entri cache: isi respons dan kapan disimpan.
class CacheEntri {
  final String isi;
  final DateTime waktu;

  const CacheEntri(this.isi, this.waktu);
}

abstract class CacheStore {
  Future<CacheEntri?> baca(String kunci);
  Future<void> simpan(String kunci, String isi, DateTime waktu);
  Future<void> hapusSemua();
}

/// Cache di SQLite (berkas tabungku_cache.db), terpisah dari database
/// kegiatan lokal pertemuan 7.
class SqliteCacheStore implements CacheStore {
  Future<Database>? _bukaDb;
  Future<Database> get _database => _bukaDb ??= _buka();

  Future<Database> _buka() async {
    final folder = await getDatabasesPath();
    return openDatabase(
      p.join(folder, 'tabungku_cache.db'),
      version: 1,
      onCreate: (db, versi) => db.execute('''
        CREATE TABLE cache (
          kunci TEXT PRIMARY KEY,
          isi TEXT NOT NULL,
          waktu TEXT NOT NULL
        )
      '''),
    );
  }

  @override
  Future<CacheEntri?> baca(String kunci) async {
    final db = await _database;
    final baris = await db.query(
      'cache',
      where: 'kunci = ?',
      whereArgs: [kunci],
      limit: 1,
    );
    if (baris.isEmpty) return null;
    final b = baris.first;
    return CacheEntri(b['isi'] as String, DateTime.parse(b['waktu'] as String));
  }

  @override
  Future<void> simpan(String kunci, String isi, DateTime waktu) async {
    final db = await _database;
    await db.insert(
      'cache',
      {'kunci': kunci, 'isi': isi, 'waktu': waktu.toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> hapusSemua() async {
    final db = await _database;
    await db.delete('cache');
  }
}

/// Cache di memori, dipakai test (tanpa plugin native).
class MemoryCacheStore implements CacheStore {
  final Map<String, CacheEntri> _data = {};

  int get jumlah => _data.length;

  @override
  Future<CacheEntri?> baca(String kunci) async => _data[kunci];

  @override
  Future<void> simpan(String kunci, String isi, DateTime waktu) async {
    _data[kunci] = CacheEntri(isi, waktu);
  }

  @override
  Future<void> hapusSemua() async => _data.clear();
}

/// Cache yang sedang dipakai aplikasi (test dapat menggantinya).
CacheStore penyimpanCache = SqliteCacheStore();

/// Waktu data cache yang sedang ditampilkan saat offline; null bila online.
final ValueNotifier<DateTime?> statusOffline = ValueNotifier<DateTime?>(null);
