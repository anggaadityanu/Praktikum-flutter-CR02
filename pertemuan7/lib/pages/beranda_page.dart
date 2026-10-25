import 'package:flutter/material.dart';

import '../data/db_helper.dart';
import '../models/kegiatan.dart';
import '../utils/format.dart';
import '../widgets/kegiatan_tile.dart';
import '../widgets/ringkasan_card.dart';
import '../state/pengaturan.dart';

class DataHari {
  final List<Kegiatan> daftar;
  final Ringkasan ringkasan;
  const DataHari(this.daftar, this.ringkasan);
}

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  late Future<DataHari> _future;

  @override
  void initState() {
    super.initState();
    _future = _ambil();
    versiData.addListener(_muat);
  }

  @override
  void dispose() {
    versiData.removeListener(_muat);
    super.dispose();
  }

  Future<DataHari> _ambil() async {
    final tanggal = kunciTanggal(DateTime.now());
    final daftar = await DbHelper.pada(tanggal);
    final ringkasan = await DbHelper.ringkasan(tanggal);
    return DataHari(daftar, ringkasan);
  }

  void _muat() {
    setState(() {
      _future = _ambil();
    });
  }

  Future<void> _bukaForm([Kegiatan? k]) async {
    final hasil = await Navigator.pushNamed(context, '/form', arguments: k);
    if (!mounted) return;
    if (hasil == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan disimpan')),
      );
    }
  }

  /// Selalu mengembalikan false: baris hilang saat daftar dimuat ulang
  /// (lewat versiData), bukan lewat animasi Dismissible.
  Future<bool> _konfirmasiHapus(Kegiatan k) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kegiatan?'),
        content: Text('"${k.judul}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ya == true) {
      await DbHelper.hapus(k.id!);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaForm(),
        icon: const Icon(Icons.add),
        label: const Text('Kegiatan'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              tanggal: DateTime.now(),
              onCari: () => Navigator.pushNamed(context, '/cari'),
            ),
          ),
          FutureBuilder<DataHari>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Galat: ${snapshot.error}')),
                );
              }
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final data = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ValueListenableBuilder<int>(
                        valueListenable: targetHarian,
                        builder: (context, target, _) => RingkasanCard(
                          judul: 'Ringkasan hari ini',
                          ringkasan: data.ringkasan,
                          target: target,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    if (data.daftar.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_available_outlined,
                                    size: 56, color: skema.outline),
                                const SizedBox(height: 12),
                                const Text(
                                  'Belum ada kegiatan hari ini.\nTekan tombol Kegiatan untuk menambah.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList.separated(
                        itemCount: data.daftar.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final k = data.daftar[i];
                          return Dismissible(
                            key: ValueKey(k.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => _konfirmasiHapus(k),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: skema.errorContainer,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(Icons.delete_outline,
                                  color: skema.onErrorContainer),
                            ),
                            child: KegiatanTile(
                              kegiatan: k,
                              onCentang: (v) =>
                                  DbHelper.setSelesai(k.id!, v),
                              onTap: () => _bukaForm(k),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final DateTime tanggal;
  final VoidCallback onCari;
  const _Header({required this.tanggal, required this.onCari});

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        12,
        28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skema.primary, skema.tertiary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hari Ini',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: skema.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tanggalIndo(tanggal),
                  style: TextStyle(color: skema.onPrimary.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onCari,
            icon: const Icon(Icons.search),
            tooltip: 'Cari kegiatan',
          ),
        ],
      ),
    );
  }
}