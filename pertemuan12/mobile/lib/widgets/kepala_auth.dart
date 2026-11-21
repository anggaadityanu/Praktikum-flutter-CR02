import 'package:flutter/material.dart';

/// Kepala berlatar gradient untuk halaman Login dan Register.
class KepalaAuth extends StatelessWidget {
  final String judul;
  final String subjudul;
  final double jarakAtas;

  const KepalaAuth({
    super.key,
    required this.judul,
    required this.subjudul,
    this.jarakAtas = 40,
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + jarakAtas,
        24,
        36,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skema.primary, skema.tertiary],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: skema.onPrimary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.savings_outlined, size: 32, color: skema.onPrimary),
          ),
          const SizedBox(height: 20),
          Text(
            judul,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: skema.onPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subjudul,
            style: TextStyle(color: skema.onPrimary.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }
}
