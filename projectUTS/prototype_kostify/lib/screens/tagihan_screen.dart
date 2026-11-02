import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../nav.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';
import 'pembayaran_screen.dart';

class TagihanScreen extends StatefulWidget {
  const TagihanScreen({super.key});

  @override
  State<TagihanScreen> createState() => _TagihanScreenState();
}

class _TagihanScreenState extends State<TagihanScreen> {
  int _tab = 0; // 0 = Aktif, 1 = Riwayat

  Future<void> _bayar(Tagihan t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PembayaranScreen(t)),
    );
    setState(() {}); // refresh setelah kembali
  }

  void _rincian(Tagihan t) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rincian ${t.periode}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            _baris('Kos', kamarAnda.nama),
            _baris('Nominal', rupiah(t.nominal)),
            _baris('Jatuh tempo', t.jatuhTempo),
            _baris('Dibayar', t.dibayar),
            _baris('Status', t.lunas ? 'Lunas' : 'Belum Dibayar'),
          ],
        ),
      ),
    );
  }

  Widget _baris(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text(v,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final data = daftarTagihan.where((t) => t.lunas == (_tab == 1)).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => tabNotifier.value = tabBeranda,
        ),
        title: const Text('Tagihan'),
      ),
      body: Column(
        children: [
          // Segmen Aktif / Riwayat
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: K.border),
              ),
              child: Row(
                children: [
                  _segmen('Aktif', 0),
                  _segmen('Riwayat', 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: data.isEmpty
                ? Center(
                    child: Text(
                        _tab == 0
                            ? 'Tidak ada tagihan aktif'
                            : 'Belum ada riwayat tagihan',
                        style: const TextStyle(color: Colors.black45)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _TagihanCard(
                      data[i],
                      onBayar: () => _bayar(data[i]),
                      onRincian: () => _rincian(data[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _segmen(String label, int index) {
    final aktif = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? K.mint : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                  color: aktif ? K.primaryDark : Colors.black54)),
        ),
      ),
    );
  }
}

class _TagihanCard extends StatelessWidget {
  final Tagihan t;
  final VoidCallback onBayar, onRincian;
  const _TagihanCard(this.t, {required this.onBayar, required this.onRincian});

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(t.periode,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                StatusChip(t.lunas ? 'Lunas' : 'Belum Dibayar'),
              ],
            ),
            const SizedBox(height: 6),
            Text(rupiah(t.nominal),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                t.lunas
                    ? 'Dibayar: ${t.dibayar}'
                    : 'Jatuh tempo: ${t.jatuhTempo}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            t.lunas
                ? OutlinedButton(
                    onPressed: onRincian,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: K.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Lihat Rincian'),
                  )
                : ElevatedButton(
                    onPressed: onBayar,
                    child: const Text('Bayar Sekarang'),
                  ),
          ],
        ),
      );
}