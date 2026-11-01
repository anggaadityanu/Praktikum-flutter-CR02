import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../nav.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/foto_kos.dart';

class FormBookingScreen extends StatefulWidget {
  final Kamar kamar;
  const FormBookingScreen(this.kamar, {super.key});

  @override
  State<FormBookingScreen> createState() => _FormBookingScreenState();
}

class _FormBookingScreenState extends State<FormBookingScreen> {
  DateTime _tanggal = DateTime.now().add(const Duration(days: 7));
  int _durasi = 3;
  final _catatan = TextEditingController();

  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  String get _tanggalText =>
      '${_tanggal.day.toString().padLeft(2, '0')} ${_bulan[_tanggal.month - 1]} ${_tanggal.year}';

  int get _sewa => _durasi * widget.kamar.harga;
  int get _total => _sewa + biayaAdmin;

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _konfirmasi() async {
    // booking baru jadi tagihan yang belum dibayar
    daftarTagihan.insert(
      0,
      Tagihan('Booking ${widget.kamar.nama}', _tanggalText, _total),
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Booking berhasil'),
        content: Text(
            '${widget.kamar.nama} untuk $_durasi bulan mulai $_tanggalText.\n'
            'Silakan selesaikan pembayaran ${rupiah(_total)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Lihat Tagihan'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    tabNotifier.value = tabTagihan;
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kamar;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Form Booking'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ringkasan kos
          Row(
            children: [
              FotoKos(width: 64, height: 64, asset: k.foto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.nama,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(k.alamat,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    Text('${rupiah(k.harga)} / bulan',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tanggal masuk
          const _Label('Tanggal Masuk'),
          InkWell(
            onTap: _pilihTanggal,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: const InputDecoration(
                isDense: true,
                suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
              child: Text(_tanggalText, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(height: 16),

          // Durasi sewa
          const _Label('Durasi Sewa'),
          Row(
            children: [
              Expanded(
                child: Text('$_durasi Bulan',
                    style: const TextStyle(fontSize: 14)),
              ),
              _StepButton(
                Icons.remove,
                onTap: _durasi > 1 ? () => setState(() => _durasi--) : null,
              ),
              const SizedBox(width: 12),
              _StepButton(
                Icons.add,
                onTap: _durasi < 12 ? () => setState(() => _durasi++) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Catatan
          const _Label('Catatan (Opsional)'),
          TextField(
            controller: _catatan,
            decoration: const InputDecoration(
              hintText: 'Tambahkan catatan untuk pemilik kos',
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),

          // Estimasi biaya
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: K.mint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimasi Biaya',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _BarisBiaya('$_durasi bulan × ${rupiah(k.harga)}', rupiah(_sewa)),
                const SizedBox(height: 6),
                _BarisBiaya('Biaya Admin', rupiah(biayaAdmin)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(rupiah(_total),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: K.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _konfirmasi,
            child: const Text('Konfirmasi Booking'),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      );
}

class _BarisBiaya extends StatelessWidget {
  final String kiri, kanan;
  const _BarisBiaya(this.kiri, this.kanan);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(kiri, style: const TextStyle(fontSize: 12)),
          Text(kanan, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton(this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: onTap == null ? K.border : Colors.black54),
          ),
          child: Icon(icon,
              size: 18,
              color: onTap == null ? Colors.black26 : Colors.black87),
        ),
      );
}