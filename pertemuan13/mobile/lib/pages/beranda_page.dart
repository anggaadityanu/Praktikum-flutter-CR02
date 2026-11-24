import 'dart:async';

import 'package:flutter/material.dart';

import '../data/kegiatan_repository.dart';
import '../models/kegiatan.dart';
import '../models/pengguna.dart';
import '../state/pengaturan.dart';
import '../state/sesi.dart';
import '../utils/format.dart';
import '../widgets/galat_view.dart';
import '../widgets/kegiatan_tile.dart';
import '../widgets/ringkasan_card.dart';

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

  // Latihan 4: pencarian judul dengan jeda ketik (debounce).
  final _kataC = TextEditingController();
  Timer? _tunda;
  String _kata = '';

  // Latihan 2: nilai centang yang sudah ditampilkan tetapi belum dikonfirmasi
  // server (id kegiatan -> nilai selesai).
  final Map<int, bool> _optimis = {};

  @override
  void initState() {
    super.initState();
    _future = _ambil();
    versiData.addListener(_muat);
  }

  @override
  void dispose() {
    versiData.removeListener(_muat);
    _tunda?.cancel();
    _kataC.dispose();
    super.dispose();
  }

  Future<DataHari> _ambil() async {
    final tanggal = kunciTanggal(DateTime.now());
    // Dua request dikirim bersamaan, bukan berurutan.
    final hasil = await Future.wait([
      repo.pada(tanggal, q: _kata),
      repo.ringkasan(tanggal),
    ]);
    final daftar = hasil[0] as List<Kegiatan>;
    // Buang nilai sementara yang sudah sama dengan data server
    // (atau yang barisnya sudah tidak ada).
    _optimis.removeWhere((id, nilai) {
      final cocok = daftar.where((k) => k.id == id);
      return cocok.isEmpty || cocok.first.selesai == nilai;
    });
    return DataHari(daftar, hasil[1] as Ringkasan);
  }

  void _muat() {
    setState(() {
      _future = _ambil();
    });
  }

  /// Untuk RefreshIndicator: indikator berputar sampai data baru tiba.
  Future<void> _tarikSegarkan() async {
    _muat();
    try {
      await _future;
    } catch (_) {
      // Galat sudah ditampilkan oleh FutureBuilder.
    }
  }

  /// Menjalankan operasi tulis; bila gagal, galat tampil di SnackBar.
  Future<void> _jalankan(Future<void> Function() aksi) async {
    try {
      await aksi();
    } catch (e) {
      if (mounted) tampilkanGalat(context, e);
    }
  }

  /// Optimistic update: tampilan berubah lebih dulu, lalu server dikabari.
  /// Bila server menolak, tampilan dikembalikan dan galat ditampilkan.
  Future<void> _centang(Kegiatan k, bool nilai) async {
    setState(() => _optimis[k.id!] = nilai);
    try {
      await repo.setSelesai(k, nilai);
    } catch (e) {
      if (!mounted) return;
      setState(() => _optimis.remove(k.id!));
      tampilkanGalat(context, e);
    }
  }

  /// Kegiatan seperti yang ditampilkan: nilai sementara (bila ada) menimpa data.
  Kegiatan _tampil(Kegiatan k) {
    final nilai = _optimis[k.id];
    if (nilai == null || nilai == k.selesai) return k;
    return Kegiatan(
      id: k.id,
      judul: k.judul,
      tanggal: k.tanggal,
      selesai: nilai,
      tipe: k.tipe,
      nominal: k.nominal,
      kategori: k.kategori,
      kategoriId: k.kategoriId,
    );
  }

  /// Menunggu pengguna berhenti mengetik sebelum meminta data ke server.
  void _ketik(String nilai) {
    _tunda?.cancel();
    setState(() {}); // memperbarui tombol hapus di kolom cari
    _tunda = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _kata = nilai.trim();
      _muat();
    });
  }

  void _hapusKata() {
    _tunda?.cancel();
    _kataC.clear();
    _kata = '';
    _muat();
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
      await _jalankan(() => repo.hapus(k.id!));
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
      body: RefreshIndicator(
        onRefresh: _tarikSegarkan,
        child: CustomScrollView(
          // Agar tetap bisa ditarik walau isinya sedikit.
          physics: const AlwaysScrollableScrollPhysics(),
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
                final belumSelesai =
                    snapshot.connectionState != ConnectionState.done;

                // Memuat pertama kali, atau memuat ulang setelah galat.
                if (belumSelesai && !snapshot.hasData) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: GalatView(
                      galat: snapshot.error!,
                      onCobaLagi: _muat,
                    ),
                  );
                }
                final data = snapshot.data!;
                // Latihan 1: sedang memuat ulang (data lama masih ada).
                final memuatUlang = belumSelesai;

                return SliverMainAxisGroup(
                  slivers: [
                    // Tingginya selalu 3 piksel agar tampilan tidak bergeser
                    // saat garis muncul dan hilang.
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 3,
                        child: memuatUlang
                            ? const LinearProgressIndicator(minHeight: 3)
                            : null,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 13, 16, 96),
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
                          SliverToBoxAdapter(
                            child: TextField(
                              controller: _kataC,
                              onChanged: _ketik,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: 'Cari kegiatan hari ini',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _kataC.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.close),
                                        tooltip: 'Hapus pencarian',
                                        onPressed: _hapusKata,
                                      ),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          if (data.daftar.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _kata.isEmpty
                                            ? Icons.event_available_outlined
                                            : Icons.search_off,
                                        size: 56,
                                        color: skema.outline,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _kata.isEmpty
                                            ? 'Belum ada kegiatan hari ini.\nTekan tombol Kegiatan untuk menambah.'
                                            : 'Tidak ada kegiatan yang cocok dengan "$_kata".',
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
                                    kegiatan: _tampil(k),
                                    onCentang: (v) => _centang(k, v),
                                    onTap: () => _bukaForm(k),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
          // Inisial nama pengguna yang sedang login.
          ValueListenableBuilder<Pengguna?>(
            valueListenable: pengguna,
            builder: (context, p, _) {
              final nama = (p?.nama ?? '').trim();
              final inisial = nama.isEmpty ? '?' : nama[0].toUpperCase();
              return Tooltip(
                message: nama.isEmpty ? 'Pengguna' : nama,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: skema.onPrimary.withOpacity(0.2),
                  child: Text(
                    inisial,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: skema.onPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
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
