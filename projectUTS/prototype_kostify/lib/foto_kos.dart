import 'package:flutter/material.dart';
import '../theme.dart';

class FotoKos extends StatelessWidget {
  final double? width, height;
  final double radius;
  final String? asset;
  const FotoKos(
      {super.key, this.width, this.height, this.radius = 8, this.asset});

  Widget _placeholder() => Container(
        color: K.mint,
        child: const Center(
            child: Icon(Icons.bed_outlined, color: K.primary, size: 28)),
      );

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: (asset == null || asset!.isEmpty)
              ? _placeholder()
              : Image.network(
                  asset!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : _placeholder(),
                    errorBuilder: (_, error, ___) {
                    debugPrint('FOTO GAGAL: $asset -> $error');
                    return _placeholder();
                  },
                ),
        ),
      );
}