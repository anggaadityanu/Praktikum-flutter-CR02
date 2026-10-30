import 'package:flutter/material.dart';

import '../models/kegiatan.dart';
import '../utils/format.dart';

class RingkasanCard extends StatelessWidget {
  final String judul;
  final Ringkasan ringkasan;
  final int target;

  const RingkasanCard({
    super.key,
    required this.judul,
    required this.ringkasan,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final tabungan = ringkasan.tabungan;
    final negatif = tabungan < 0;
    final tercapai = !negatif && tabungan >= target;
    final persen = target <= 0
        ? (tabungan > 0 ? 1.0 : 0.0)
        : (tabungan / target).clamp(0.0, 1.0);
    final warna = negatif
        ? skema.error
        : (tercapai ? Colors.green.shade600 : skema.primary);

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: persen),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            backgroundColor: skema.surfaceContainerHighest,
                            color: warna,
                          ),
                        ),
                        Text(
                          '${(v * 100).round()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tabungan',
                        style: TextStyle(color: skema.onSurfaceVariant),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          rupiah(tabungan),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: warna,
                          ),
                        ),
                      ),
                      Text(
                        'Target ${rupiah(target)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: skema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    ikon: Icons.south_west,
                    warna: Colors.green.shade600,
                    nilai: rupiah(ringkasan.pemasukan),
                    label: 'Pemasukan',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    ikon: Icons.north_east,
                    warna: Colors.red.shade600,
                    nilai: rupiah(ringkasan.pengeluaran),
                    label: 'Pengeluaran',
                  ),
                ),
                Expanded(
                  child: _Stat(
                    ikon: Icons.check_circle_outline,
                    warna: skema.primary,
                    nilai:
                        '${ringkasan.selesai}/${ringkasan.jumlahKegiatan}',
                    label: 'Selesai',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Pesan(
              ikon: negatif
                  ? Icons.warning_amber_rounded
                  : (tercapai
                      ? Icons.emoji_events_outlined
                      : Icons.flag_outlined),
              warnaLatar: negatif
                  ? skema.errorContainer
                  : (tercapai
                      ? Colors.green.withOpacity(0.15)
                      : skema.primaryContainer),
              teks: negatif
                  ? 'Pengeluaran melebihi pemasukan. Hati-hati!'
                  : (tercapai
                      ? 'Target tercapai, kerja bagus!'
                      : 'Kurang ${rupiah(target - tabungan)} lagi untuk mencapai target.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final String nilai;
  final String label;

  const _Stat({
    required this.ikon,
    required this.warna,
    required this.nilai,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(ikon, size: 20, color: warna),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            nilai,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Pesan extends StatelessWidget {
  final IconData ikon;
  final Color warnaLatar;
  final String teks;

  const _Pesan({
    required this.ikon,
    required this.warnaLatar,
    required this.teks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: warnaLatar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}