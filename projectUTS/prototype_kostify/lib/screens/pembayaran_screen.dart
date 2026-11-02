import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';

class PembayaranScreen extends StatefulWidget {
  final Tagihan tagihan;
  const PembayaranScreen(this.tagihan, {super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  static const _metode = [
    'Virtual Account', 'Transfer Bank', 'QRIS', 'E-Wallet'
  ];
  String _dipilih = 'Virtual Account';
  bool _memproses = false;

  Future<void> _bayar() async {
    setState(() => _memproses = true);
    await Future.delayed(const Duration(milliseconds: 900)); // simulasi gateway
    if (!mounted) return;

    widget.tagihan
      ..lunas = true
      ..dibayar = tanggalHariIni();
    setState(() => _memproses = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: K.primary, size: 48),
        title: const Text('Pembayaran berhasil'),
        content: Text(
            '${rupiah(widget.tagihan.nominal)} via $_dipilih telah diterima.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tagihan;
    final riwayat = daftarTagihan.where((x) => x.lunas && x != t).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Tagihan Saat Ini',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(kamarAnda.nama,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    StatusChip(t.lunas ? 'Lunas' : 'Belum Dibayar'),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Periode ${t.periode}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 8),
                Text(rupiah(t.nominal),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Metode Pembayaran',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _dipilih,
            isDense: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.account_balance_outlined, size: 20),
            ),
            items: [
              for (final m in _metode) DropdownMenuItem(value: m, child: Text(m)),
            ],
            onChanged: (v) => setState(() => _dipilih = v ?? _dipilih),
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: (t.lunas || _memproses) ? null : _bayar,
            child: _memproses
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(t.lunas ? 'Sudah Lunas' : 'Bayar Sekarang'),
          ),
          const SizedBox(height: 24),

          const Text('Riwayat Pembayaran',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (riwayat.isEmpty)
            const Text('Belum ada riwayat',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
          for (final r in riwayat) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(r.periode,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      const Text('Lunas',
                          style: TextStyle(fontSize: 12, color: K.primary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(rupiah(r.nominal), style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Dibayar pada ${r.dibayar}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}