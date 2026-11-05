import 'package:flutter/material.dart';

import '../data/db_helper.dart';
import '../models/kegiatan.dart';
import '../utils/format.dart';
import '../widgets/kegiatan_tile.dart';

class CariPage extends StatefulWidget {
  const CariPage({super.key});

  @override
  State<CariPage> createState() => _CariPageState();
}

class _CariPageState extends State<CariPage> {
  final _kataC = TextEditingController();
  Tipe? _tipe;
  String? _kategori;
  late Future<List<Kegiatan>> _future;

  @override
  void initState() {
    super.initState();
    _future = _ambil();
    versiData.addListener(_muat);
  }

  @override
  void dispose() {
    versiData.removeListener(_muat);
    _kataC.dispose();
    super.dispose();
  }

  Future<List<Kegiatan>> _ambil() =>
      DbHelper.cari(kata: _kataC.text, tipe: _tipe, kategori: _kategori);

  void _muat() {
    setState(() {
      _future = _ambil();
    });
  }

  Widget _chip(String label, bool terpilih, VoidCallback aksi) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: terpilih,
          onSelected: (_) => aksi(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _kataC,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Cari nama kegiatan',
            border: InputBorder.none,
          ),
          onChanged: (_) => _muat(),
        ),
        actions: [
          if (_kataC.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _kataC.clear();
                _muat();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              children: [
                _chip('Semua jenis', _tipe == null, () {
                  _tipe = null;
                  _muat();
                }),
                for (final t in Tipe.values)
                  _chip(t.nama, _tipe == t, () {
                    _tipe = t;
                    _muat();
                  }),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
              children: [
                _chip('Semua kategori', _kategori == null, () {
                  _kategori = null;
                  _muat();
                }),
                for (final c in daftarKategori)
                  _chip(c, _kategori == c, () {
                    _kategori = c;
                    _muat();
                  }),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Kegiatan>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Galat: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final hasil = snapshot.data!;
                if (hasil.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 56, color: skema.outline),
                        const SizedBox(height: 12),
                        const Text('Tidak ada kegiatan yang cocok.'),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: hasil.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text(
                        '${hasil.length} kegiatan ditemukan',
                        style: TextStyle(color: skema.onSurfaceVariant),
                      );
                    }
                    final k = hasil[i - 1];
                    final d = dariKunci(k.tanggal);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            '${tanggalPendek(d)} ${d.year}',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        KegiatanTile(
                          kegiatan: k,
                          onCentang: (v) => DbHelper.setSelesai(k.id!, v),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/form',
                            arguments: k,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}