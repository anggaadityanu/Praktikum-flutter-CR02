import 'package:flutter/material.dart';
import '../theme.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color? bg;
  final Color? fg;
  const StatusChip(this.label, {super.key, this.bg, this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg ?? K.mint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: K.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg ?? K.primaryDark,
          ),
        ),
      );
}