import 'package:flutter/material.dart';

import '../models/laporan.dart';
import '../utils/format.dart';

/// Kartu ringkasan satu bulan: total uang masuk/keluar/tabungan dan
/// berapa hari target tabungan harian tercapai.
class KartuBulanan extends StatelessWidget {
  final LaporanBulanan laporan;

  /// Jumlah hari yang sudah berjalan (bulan ini: tanggal hari ini).
  /// Dipakai sebagai pembagi progress, supaya hari yang belum terjadi
  /// tidak dihitung "gagal".
  final int hariBerjalan;

  const KartuBulanan({
    super.key,
    required this.laporan,
    required this.hariBerjalan,
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final r = laporan.ringkasan;
    final pembagi = hariBerjalan < 1 ? 1 : hariBerjalan;
    final persen = (laporan.hariTargetTercapai / pembagi).clamp(0.0, 1.0);
    final warnaTabungan =
        r.tabungan < 0 ? Colors.red.shade600 : Colors.green.shade600;

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, color: skema.primary),
                const SizedBox(width: 8),
                Text(
                  'Bulan ini · ${namaBulan(laporan.bulan)} ${laporan.tahun}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Angka(
                  label: 'Masuk',
                  nilai: rupiah(r.pemasukan),
                  warna: Colors.green.shade600,
                ),
                _Angka(
                  label: 'Keluar',
                  nilai: rupiah(r.pengeluaran),
                  warna: Colors.red.shade600,
                ),
                _Angka(
                  label: 'Tabungan',
                  nilai: rupiah(r.tabungan),
                  warna: warnaTabungan,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Target harian tercapai ${laporan.hariTargetTercapai} '
              'dari $hariBerjalan hari',
              style: TextStyle(color: skema.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: persen, minHeight: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  final String label;
  final String nilai;
  final Color warna;

  const _Angka({required this.label, required this.nilai, required this.warna});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              nilai,
              style: TextStyle(fontWeight: FontWeight.bold, color: warna),
            ),
          ),
        ],
      ),
    );
  }
}