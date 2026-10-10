import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum 5',
      home: const CatatanPage(),
    );
  }
}

class Catatan {
  final int? id;
  final String judul;
  final String isi;
  final String dibuat; // Soal 3: kolom baru

  const Catatan({
    this.id,
    required this.judul,
    required this.isi,
    required this.dibuat,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'judul': judul,
        'isi': isi,
        'dibuat': dibuat,
      };

  factory Catatan.fromMap(Map<String, Object?> m) => Catatan(
        id: m['id'] as int,
        judul: m['judul'] as String,
        isi: m['isi'] as String,
        dibuat: (m['dibuat'] as String?) ?? '-',
      );
}

class DbHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'catatan.db');
    _db = await openDatabase(
      path,
      version: 2, // Soal 3: dinaikkan dari 1 ke 2
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE catatan('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'judul TEXT NOT NULL, '
          'isi TEXT NOT NULL, '
          'dibuat TEXT)',
        );
      },
      // Soal 3: migrasi untuk pengguna lama yang masih punya versi 1
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE catatan ADD COLUMN dibuat TEXT');
        }
      },
    );
    return _db!;
  }

  static Future<int> tambah(Catatan c) async {
    final db = await database;
    return db.insert('catatan', c.toMap());
  }

  // Soal 4: orderBy sekarang parameter, bukan hardcode
  static Future<List<Catatan>> semua({String orderBy = 'id DESC'}) async {
    final db = await database;
    final rows = await db.query('catatan', orderBy: orderBy);
    return rows.map(Catatan.fromMap).toList();
  }

  // Soal 2: pencarian berdasarkan judul
  static Future<List<Catatan>> cari(String kata, {String orderBy = 'id DESC'}) async {
    final db = await database;
    final rows = await db.query(
      'catatan',
      where: 'judul LIKE ?',
      whereArgs: ['%$kata%'],
      orderBy: orderBy,
    );
    return rows.map(Catatan.fromMap).toList();
  }

  static Future<int> ubah(Catatan c) async {
    final db = await database;
    return db.update('catatan', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  static Future<int> hapus(int id) async {
    final db = await database;
    return db.delete('catatan', where: 'id = ?', whereArgs: [id]);
  }
}

class CatatanPage extends StatefulWidget {
  const CatatanPage({super.key});

  @override
  State<CatatanPage> createState() => _CatatanPageState();
}

class _CatatanPageState extends State<CatatanPage> {
  late Future<List<Catatan>> _future;
  final _pencarian = TextEditingController();
  bool _terbaruDulu = true; // Soal 4: status urutan

  @override
  void initState() {
    super.initState();
    _future = _muatAwal();
  }

  @override
  void dispose() {
    _pencarian.dispose();
    super.dispose();
  }

  // Soal 4: baca preferensi urutan sebelum memuat data pertama kali
  Future<List<Catatan>> _muatAwal() async {
    final prefs = await SharedPreferences.getInstance();
    _terbaruDulu = prefs.getBool('terbaruDulu') ?? true;
    return DbHelper.semua(orderBy: _terbaruDulu ? 'id DESC' : 'id ASC');
  }

  void _muat() {
    setState(() {
      _future = _pencarian.text.trim().isEmpty
          ? DbHelper.semua(orderBy: _terbaruDulu ? 'id DESC' : 'id ASC')
          : DbHelper.cari(_pencarian.text.trim(),
              orderBy: _terbaruDulu ? 'id DESC' : 'id ASC');
    });
  }

  // Soal 4: simpan pilihan urutan baru
  Future<void> _ubahUrutan(bool terbaruDulu) async {
    setState(() => _terbaruDulu = terbaruDulu);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terbaruDulu', terbaruDulu);
    _muat();
  }

  Future<void> _buka([Catatan? catatan]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormCatatanPage(catatan: catatan)),
    );
    if (!mounted) return;
    _muat();
  }

  // Soal 1: konfirmasi sebelum hapus
  Future<void> _konfirmasiHapus(Catatan c) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan ini?'),
        content: Text('Catatan "${c.judul}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin == true) {
      await DbHelper.hapus(c.id!);
      _muat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan Saya'),
        actions: [
          // Soal 4: tombol ganti urutan
          IconButton(
            icon: Icon(_terbaruDulu ? Icons.arrow_downward : Icons.arrow_upward),
            tooltip: _terbaruDulu ? 'Terbaru dulu' : 'Terlama dulu',
            onPressed: () => _ubahUrutan(!_terbaruDulu),
          ),
        ],
      ),
      body: Column(
        children: [
          // Soal 2: kolom pencarian
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _pencarian,
              decoration: InputDecoration(
                labelText: 'Cari judul...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _pencarian.clear();
                    _muat();
                  },
                ),
              ),
              onChanged: (_) => _muat(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Catatan>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Galat: ${snapshot.error}'));
                }
                final data = snapshot.data!;
                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada catatan'));
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final c = data[i];
                    return ListTile(
                      title: Text(c.judul),
                      subtitle: Text('${c.isi}\nDibuat: ${c.dibuat}',
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                      isThreeLine: true,
                      onTap: () => _buka(c),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _konfirmasiHapus(c), // Soal 1
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _buka(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class FormCatatanPage extends StatefulWidget {
  final Catatan? catatan;
  const FormCatatanPage({super.key, this.catatan});

  @override
  State<FormCatatanPage> createState() => _FormCatatanPageState();
}

class _FormCatatanPageState extends State<FormCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judul;
  late final TextEditingController _isi;

  @override
  void initState() {
    super.initState();
    _judul = TextEditingController(text: widget.catatan?.judul ?? '');
    _isi = TextEditingController(text: widget.catatan?.isi ?? '');
  }

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final c = Catatan(
      id: widget.catatan?.id,
      judul: _judul.text.trim(),
      isi: _isi.text.trim(),
      // Soal 3: isi tanggal dibuat saat catatan baru; pertahankan nilai lama saat diubah
      dibuat: widget.catatan?.dibuat ?? DateTime.now().toString().substring(0, 16),
    );
    if (widget.catatan == null) {
      await DbHelper.tambah(c);
    } else {
      await DbHelper.ubah(c);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final baru = widget.catatan == null;
    return Scaffold(
      appBar: AppBar(title: Text(baru ? 'Catatan Baru' : 'Ubah Catatan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judul,
              decoration: const InputDecoration(
                labelText: 'Judul',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isi,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Isi catatan',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Isi wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _simpan, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}