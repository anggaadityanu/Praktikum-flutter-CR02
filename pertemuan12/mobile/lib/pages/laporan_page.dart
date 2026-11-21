import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart';
import '../data/kegiatan_repository.dart';
import '../models/kegiatan.dart';
import '../models/laporan.dart';
import '../state/pengaturan.dart';
import '../utils/format.dart';
import '../utils/ukur_waktu.dart';
import '../widgets/galat_view.dart';
import '../widgets/ringkasan_card.dart';

class DataLaporan {
  final Ringkasan ringkasan;
  final List<TotalKategori> kategori;
  final List<RingkasanHari> tujuhHari; // terbaru di atas
  const DataLaporan(this.ringkasan, this.kategori, this.tujuhHari);
}

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  DateTime _tanggal = DateTime.now();
  late Future<DataLaporan> _future;

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

  /// Laporan harian dan 7 hari terakhir diambil bersamaan (2 request paralel,
  /// dulu 9 query SQLite berurutan).
  Future<DataLaporan> _ambil() async {
    final hariIni = DateTime.now();
    final awal = DateTime(hariIni.year, hariIni.month, hariIni.day - 6);
    final hasil = await Future.wait([
      repo.laporanHarian(kunciTanggal(_tanggal)),
      repo.rentang(awal, hariIni),
    ]);
    final harian = hasil[0] as LaporanHarian;
    final rentang = hasil[1] as List<RingkasanHari>;
    // Terbaru di atas, sama seperti pertemuan 7.
    return DataLaporan(
      harian.ringkasan,
      harian.perKategori,
      rentang.reversed.toList(),
    );
  }

  void _muat() {
    setState(() {
      _future = _ambil();
    });
  }

  Future<void> _tarikSegarkan() async {
    _muat();
    try {
      await _future;
    } catch (_) {
      // Galat sudah ditampilkan oleh FutureBuilder.
    }
  }

  void _pilih(DateTime d) {
    _tanggal = DateTime(d.year, d.month, d.day);
    _muat();
  }

  void _geser(int hari) =>
      _pilih(DateTime(_tanggal.year, _tanggal.month, _tanggal.day + hari));

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (dipilih != null) _pilih(dipilih);
  }

  Future<void> _salin() async {
    try {
      final data = await _future;
      final r = data.ringkasan;
      final target = targetHarian.value;
      final tercapai = r.tabungan >= target;

      final teks = StringBuffer();
      teks.writeln('LAPORAN TABUNGKU');
      teks.writeln(tanggalIndo(_tanggal));
      teks.writeln();
      teks.writeln('Kegiatan    : ${r.jumlahKegiatan} (selesai ${r.selesai})');
      teks.writeln('Pemasukan   : ${rupiah(r.pemasukan)}');
      teks.writeln('Pengeluaran : ${rupiah(r.pengeluaran)}');
      teks.writeln('Tabungan    : ${rupiah(r.tabungan)}');
      teks.writeln(
        'Target      : ${rupiah(target)} (${tercapai ? 'tercapai' : 'belum tercapai'})',
      );
      if (data.kategori.isNotEmpty) {
        teks.writeln();
        teks.writeln('Pengeluaran per kategori:');
        for (final t in data.kategori) {
          teks.writeln('- ${t.kategori}: ${rupiah(t.total)}');
        }
      }

      await Clipboard.setData(ClipboardData(text: teks.toString().trimRight()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan disalin ke papan klip')),
      );
    } catch (e) {
      if (mounted) tampilkanGalat(context, e);
    }
  }

  /// Latihan 3: membandingkan memuat Laporan berurutan dan dengan Future.wait.
  Future<void> _ukurWaktu() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Mengukur waktu muat...')),
          ],
        ),
      ),
    );
    HasilUkur? hasil;
    Object? galat;
    try {
      hasil = await ukurLaporan(repo);
    } catch (e) {
      galat = e;
    }
    if (!mounted) return;
    Navigator.of(context).pop(); // tutup dialog "Mengukur..."
    if (galat != null || hasil == null) {
      tampilkanGalat(context, galat ?? 'Pengukuran gagal');
      return;
    }
    final h = hasil;
    final lebihCepat = h.berurutanMs == 0
        ? 0
        : ((h.berurutanMs - h.paralelMs) * 100 / h.berurutanMs).round();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Waktu muat Laporan'),
        content: Text(
          'Sumber data : ${modeData == 'lokal' ? 'SQLite' : 'API'}\n'
          'Berurutan   : ${h.berurutanMs} ms\n'
          'Paralel     : ${h.paralelMs} ms (Future.wait)\n'
          'Lebih cepat : $lebihCepat%\n\n'
          'Rata-rata ${h.ulang} kali pengukuran.',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Color _warnaNilai(int n) {
    if (n > 0) return Colors.green.shade600;
    if (n < 0) return Colors.red.shade600;
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        actions: [
          IconButton(
            onPressed: _ukurWaktu,
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Ukur waktu muat',
          ),
          IconButton(
            onPressed: _salin,
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Salin laporan',
          ),
        ],
      ),
      body: FutureBuilder<DataLaporan>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return GalatView(galat: snapshot.error!, onCobaLagi: _muat);
          }
          final data = snapshot.data!;
          final maksimum =
              data.kategori.isEmpty ? 1 : data.kategori.first.total;
          final totalTujuh = data.tujuhHari
              .fold<int>(0, (jumlah, h) => jumlah + h.ringkasan.tabungan);

          return RefreshIndicator(
            onRefresh: _tarikSegarkan,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Pemilih tanggal
                Card.outlined(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _geser(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _pilihTanggal,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    tanggalIndo(_tanggal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _geser(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: targetHarian,
                  builder: (context, target, _) => RingkasanCard(
                    judul: 'Ringkasan ${tanggalPendek(_tanggal)}',
                    ringkasan: data.ringkasan,
                    target: target,
                  ),
                ),

                // Pengeluaran per kategori
                const _JudulBagian('Pengeluaran per kategori'),
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: data.kategori.isEmpty
                        ? Text(
                            'Tidak ada pengeluaran pada tanggal ini.',
                            style: TextStyle(color: skema.onSurfaceVariant),
                          )
                        : Column(
                            children: [
                              for (final t in data.kategori)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(t.kategori),
                                          const Spacer(),
                                          Text(
                                            rupiah(t.total),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: t.total / maksimum,
                                          minHeight: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),

                // 7 hari terakhir
                const _JudulBagian('7 hari terakhir'),
                Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        for (final h in data.tujuhHari)
                          _BarisHari(
                            hari: h,
                            terpilih: kunciTanggal(h.tanggal) ==
                                kunciTanggal(_tanggal),
                            warna: _warnaNilai(h.ringkasan.tabungan),
                            onTap: () => _pilih(h.tanggal),
                          ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: Row(
                            children: [
                              const Text(
                                'Total 7 hari',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                rupiah(totalTujuh),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _warnaNilai(totalTujuh),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  final String teks;
  const _JudulBagian(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        teks,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BarisHari extends StatelessWidget {
  final RingkasanHari hari;
  final bool terpilih;
  final Color warna;
  final VoidCallback onTap;

  const _BarisHari({
    required this.hari,
    required this.terpilih,
    required this.warna,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Material(
      color: terpilih ? skema.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tanggalPendek(hari.tanggal),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${hari.ringkasan.jumlahKegiatan} kegiatan',
                      style: TextStyle(
                        fontSize: 12,
                        color: skema.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                rupiah(hari.ringkasan.tabungan),
                style: TextStyle(fontWeight: FontWeight.bold, color: warna),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
