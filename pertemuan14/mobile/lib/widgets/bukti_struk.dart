import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Foto yang baru dipilih dari kamera/galeri dan belum diunggah.
class FotoBaru {
  final Uint8List isi;
  final String nama;
  const FotoBaru(this.isi, this.nama);
}

/// Kotak pratinjau foto struk + tombol Kamera, Galeri, dan Hapus.
/// Widget ini hanya menampilkan dan memilih foto; pengunggahannya
/// dilakukan form setelah kegiatan tersimpan.
class BuktiStruk extends StatelessWidget {
  /// URL foto yang sudah ada di server (mode ubah), atau null.
  final String? urlLama;

  /// Foto baru pilihan pengguna, atau null.
  final FotoBaru? fotoBaru;

  final ValueChanged<FotoBaru> onPilih;
  final VoidCallback onHapus;

  const BuktiStruk({
    super.key,
    required this.urlLama,
    required this.fotoBaru,
    required this.onPilih,
    required this.onHapus,
  });

  bool get _adaFoto => fotoBaru != null || urlLama != null;

  Future<void> _ambil(BuildContext context, ImageSource sumber) async {
    try {
      // Diperkecil di HP agar unggahan cepat dan di bawah batas 2 MB server.
      final f = await ImagePicker().pickImage(
        source: sumber,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (f == null) return; // pengguna membatalkan
      onPilih(FotoBaru(await f.readAsBytes(), f.name));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka kamera/galeri')),
      );
    }
  }

  /// Foto baru (dari memori) diutamakan; kalau tidak ada, ambil dari server.
  Widget _gambar(BoxFit fit) {
    final baru = fotoBaru;
    if (baru != null) return Image.memory(baru.isi, fit: fit);
    return Image.network(
      urlLama!,
      fit: fit,
      loadingBuilder: (context, child, progres) => progres == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stack) => const Center(
        child: Icon(Icons.broken_image_outlined, size: 40),
      ),
    );
  }

  void _perbesar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Bukti struk'),
          ),
          // InteractiveViewer: cubit dua jari untuk memperbesar.
          body: Center(child: InteractiveViewer(child: _gambar(BoxFit.contain))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: skema.surfaceContainerHighest.withOpacity(0.5),
              border: Border.all(color: skema.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _adaFoto
                ? InkWell(
                    onTap: () => _perbesar(context),
                    child: _gambar(BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 40, color: skema.onSurfaceVariant),
                      const SizedBox(height: 6),
                      Text(
                        'Belum ada foto struk',
                        style: TextStyle(color: skema.onSurfaceVariant),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _ambil(context, ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Kamera'),
            ),
            OutlinedButton.icon(
              onPressed: () => _ambil(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Galeri'),
            ),
            if (_adaFoto)
              TextButton.icon(
                onPressed: onHapus,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus foto'),
              ),
          ],
        ),
      ],
    );
  }
}