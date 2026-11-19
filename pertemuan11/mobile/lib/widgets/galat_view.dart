import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/pesan_galat.dart';

/// Tampilan galat dengan tombol "Coba lagi". Galat dari server (ApiException)
/// menampilkan pesan server; galat lain dianggap masalah koneksi.
class GalatView extends StatelessWidget {
  final Object galat;
  final VoidCallback onCobaLagi;

  const GalatView({super.key, required this.galat, required this.onCobaLagi});

  String _pesan() {
    final e = galat;
    if (e is ApiException) return e.pesan;
    if (e is TimeoutException) {
      return 'Server tidak merespons.\nCoba lagi sebentar lagi.';
    }
    return 'Tidak dapat terhubung ke server.\nPeriksa koneksi dan alamat API.';
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final dariServer = galat is ApiException;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skema.errorContainer,
              ),
              child: Icon(
                dariServer ? Icons.error_outline : Icons.cloud_off_outlined,
                size: 48,
                color: skema.onErrorContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(_pesan(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCobaLagi,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menampilkan pesan galat singkat di SnackBar (untuk operasi tulis yang gagal).
void tampilkanGalat(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(pesanGalat(e))),
  );
}
