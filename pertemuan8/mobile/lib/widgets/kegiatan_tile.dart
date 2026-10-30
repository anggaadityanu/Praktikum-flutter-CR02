import 'package:flutter/material.dart';

import '../models/kegiatan.dart';
import '../utils/format.dart';

class KegiatanTile extends StatelessWidget {
  final Kegiatan kegiatan;
  final ValueChanged<bool> onCentang;
  final VoidCallback onTap;

  const KegiatanTile({
    super.key,
    required this.kegiatan,
    required this.onCentang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final k = kegiatan;
    final masuk = k.tipe == Tipe.pemasukan;
    final warnaUang = masuk ? Colors.green.shade600 : Colors.red.shade600;

    return Material(
      color: skema.surfaceContainerHighest.withOpacity(0.5),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: skema.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => onCentang(!k.selesai),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: k.selesai ? skema.primary : Colors.transparent,
                    border: Border.all(color: skema.primary, width: 2),
                  ),
                  child: k.selesai
                      ? Icon(Icons.check, size: 18, color: skema.onPrimary)
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.judul,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration:
                            k.selesai ? TextDecoration.lineThrough : null,
                        color: k.selesai
                            ? skema.onSurfaceVariant
                            : skema.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _Label(teks: k.tipe.nama),
                        if (k.tipe == Tipe.pengeluaran)
                          _Label(teks: k.kategori),
                      ],
                    ),
                  ],
                ),
              ),
              if (k.tipe != Tipe.tanpa)
                Text(
                  '${masuk ? '+' : '-'}${rupiah(k.nominal)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: warnaUang,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String teks;
  const _Label({required this.teks});

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: skema.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        teks,
        style: TextStyle(fontSize: 11, color: skema.onPrimaryContainer),
      ),
    );
  }
}