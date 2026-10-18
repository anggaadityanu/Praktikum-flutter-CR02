import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _gelap = false;

  @override
  void initState() {
    super.initState();
    _muatTema();
  }

  Future<void> _muatTema() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _gelap = prefs.getBool('gelap') ?? false);
  }

  Future<void> _ubahTema(bool nilai) async {
    setState(() => _gelap = nilai);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gelap', nilai);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pencatat Pengeluaran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _gelap ? Brightness.dark : Brightness.light,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: PengeluaranPage(gelap: _gelap, onUbahTema: _ubahTema),
    );
  }
}

// ======================= MODEL =======================

class Pengeluaran {
  final int? id;
  final String nama;
  final int jumlah;
  final String kategori;
  final String tanggal;

  const Pengeluaran({
    this.id,
    required this.nama,
    required this.jumlah,
    required this.kategori,
    required this.tanggal,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'nama': nama,
        'jumlah': jumlah,
        'kategori': kategori,
        'tanggal': tanggal,
      };

  factory Pengeluaran.fromMap(Map<String, Object?> m) => Pengeluaran(
        id: m['id'] as int,
        nama: m['nama'] as String,
        jumlah: m['jumlah'] as int,
        kategori: m['kategori'] as String,
        tanggal: m['tanggal'] as String,
      );
}

// ======================= AKSES DATA (DbHelper) =======================

class DbHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'pengeluaran.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE pengeluaran('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'nama TEXT NOT NULL, '
          'jumlah INTEGER NOT NULL, '
          'kategori TEXT NOT NULL, '
          'tanggal TEXT NOT NULL)',
        );
      },
    );
    return _db!;
  }

  static Future<int> tambah(Pengeluaran x) async {
    final db = await database;
    return db.insert('pengeluaran', x.toMap());
  }

  static Future<List<Pengeluaran>> semua() async {
    final db = await database;
    final rows = await db.query('pengeluaran', orderBy: 'id DESC');
    return rows.map(Pengeluaran.fromMap).toList();
  }

  static Future<int> ubah(Pengeluaran x) async {
    final db = await database;
    return db.update('pengeluaran', x.toMap(), where: 'id = ?', whereArgs: [x.id]);
  }

  static Future<int> hapus(int id) async {
    final db = await database;
    return db.delete('pengeluaran', where: 'id = ?', whereArgs: [id]);
  }

  // Total dihitung lewat SQL, bukan di Dart
  static Future<int> totalSemua() async {
    final db = await database;
    final result = await db.rawQuery('SELECT SUM(jumlah) as total FROM pengeluaran');
    final total = result.first['total'];
    return (total as int?) ?? 0;
  }
}

// ======================= UI: HALAMAN DAFTAR =======================

const kategoriList = ['Makanan', 'Transportasi', 'Belanja', 'Tagihan', 'Lainnya'];

class PengeluaranPage extends StatefulWidget {
  final bool gelap;
  final ValueChanged<bool> onUbahTema;
  const PengeluaranPage({super.key, required this.gelap, required this.onUbahTema});

  @override
  State<PengeluaranPage> createState() => _PengeluaranPageState();
}

class _PengeluaranPageState extends State<PengeluaranPage> {
  late Future<List<Pengeluaran>> _futureList;
  late Future<int> _futureTotal;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    setState(() {
      _futureList = DbHelper.semua();
      _futureTotal = DbHelper.totalSemua();
    });
  }

  Future<void> _buka([Pengeluaran? x]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormPengeluaranPage(pengeluaran: x)),
    );
    if (!mounted) return;
    _muat();
  }

  Future<void> _konfirmasiHapus(Pengeluaran x) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pengeluaran ini?'),
        content: Text('"${x.nama}" akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yakin == true) {
      await DbHelper.hapus(x.id!);
      _muat();
    }
  }

  String _formatRupiah(int angka) {
    final s = angka.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatat Pengeluaran'),
        actions: [
          IconButton(
            icon: Icon(widget.gelap ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Mode gelap',
            onPressed: () => widget.onUbahTema(!widget.gelap),
          ),
        ],
      ),
      body: Column(
        children: [
          // Kartu total
          FutureBuilder<int>(
            future: _futureTotal,
            builder: (context, snapshot) {
              final total = snapshot.data ?? 0;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pengeluaran'),
                    const SizedBox(height: 4),
                    Text(
                      _formatRupiah(total),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Pengeluaran>>(
              future: _futureList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Galat: ${snapshot.error}'));
                }
                final data = snapshot.data!;
                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada pengeluaran'));
                }
                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final x = data[i];
                    return ListTile(
                      title: Text(x.nama),
                      subtitle: Text('${x.kategori} • ${x.tanggal}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formatRupiah(x.jumlah)),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _konfirmasiHapus(x),
                          ),
                        ],
                      ),
                      onTap: () => _buka(x),
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

// ======================= UI: FORM TAMBAH/UBAH =======================

class FormPengeluaranPage extends StatefulWidget {
  final Pengeluaran? pengeluaran;
  const FormPengeluaranPage({super.key, this.pengeluaran});

  @override
  State<FormPengeluaranPage> createState() => _FormPengeluaranPageState();
}

class _FormPengeluaranPageState extends State<FormPengeluaranPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nama;
  late final TextEditingController _jumlah;
  String? _kategori;

  @override
  void initState() {
    super.initState();
    _nama = TextEditingController(text: widget.pengeluaran?.nama ?? '');
    _jumlah = TextEditingController(
        text: widget.pengeluaran != null ? widget.pengeluaran!.jumlah.toString() : '');
    _kategori = widget.pengeluaran?.kategori;
  }

  @override
  void dispose() {
    _nama.dispose();
    _jumlah.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final x = Pengeluaran(
      id: widget.pengeluaran?.id,
      nama: _nama.text.trim(),
      jumlah: int.parse(_jumlah.text.trim()),
      kategori: _kategori!,
      tanggal: widget.pengeluaran?.tanggal ?? DateTime.now().toString().substring(0, 10),
    );
    if (widget.pengeluaran == null) {
      await DbHelper.tambah(x);
    } else {
      await DbHelper.ubah(x);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final baru = widget.pengeluaran == null;
    return Scaffold(
      appBar: AppBar(title: Text(baru ? 'Tambah Pengeluaran' : 'Ubah Pengeluaran')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jumlah,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)', border: OutlineInputBorder()),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Jumlah harus angka lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: kategoriList
                  .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: (v) => setState(() => _kategori = v),
              validator: (v) => v == null ? 'Pilih kategori' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _simpan, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}