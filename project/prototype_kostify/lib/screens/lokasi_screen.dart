import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../theme.dart';

class LokasiScreen extends StatefulWidget {
  final Kamar kamar;
  const LokasiScreen(this.kamar, {super.key});

  @override
  State<LokasiScreen> createState() => _LokasiScreenState();
}

class _LokasiScreenState extends State<LokasiScreen> {
  int _geser = 0; // dipakai tombol refresh untuk "menyegarkan" peta

  void _info(String teks) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(teks)));

  @override
  Widget build(BuildContext context) {
    final k = widget.kamar;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _geser++);
              _info('Peta diperbarui');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Peta
          Positioned.fill(
            child: CustomPaint(painter: _PetaPainter(_geser % 3)),
          ),
          // Pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 44, color: K.primary),
            ),
          ),
          // Kartu info di bawah
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.nama,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(k.alamat,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _info('Membuka peta ${k.nama} (simulasi)'),
                            icon: const Icon(Icons.place_outlined, size: 18),
                            label: const Text('Lihat Peta'),
                            style: _tombolOutline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _info('Menghitung rute ke ${k.nama} (simulasi)'),
                            icon: const Icon(Icons.alt_route, size: 18),
                            label: const Text('Lihat Rute'),
                            style: _tombolOutline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _tombolOutline = OutlinedButton.styleFrom(
  foregroundColor: Colors.black87,
  side: const BorderSide(color: K.border),
  minimumSize: const Size(0, 44),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

// Gambar peta sederhana: latar abu muda, jalan diagonal, blok hijau (taman)
class _PetaPainter extends CustomPainter {
  final int variasi;
  _PetaPainter(this.variasi);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF1F1EF));

    // blok taman (hijau muda)
    final taman = Paint()..color = const Color(0xFFDCEFE1);
    canvas.save();
    canvas.translate(size.width * 0.78, size.height * 0.08);
    canvas.rotate(0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 0, 130, 100), const Radius.circular(18)),
      taman,
    );
    canvas.restore();

    // jalan: dua arah diagonal
    final jalan = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final tipis = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;

    final w = size.width, h = size.height;
    final geser = variasi * 18.0;

    for (var i = -3; i < 9; i++) {
      final x = i * 90.0 + geser;
      canvas.drawLine(Offset(x, 0), Offset(x + h * 0.55, h), i.isEven ? jalan : tipis);
    }
    for (var i = -2; i < 10; i++) {
      final y = i * 80.0 + geser;
      canvas.drawLine(Offset(0, y + w * 0.4), Offset(w, y - w * 0.4), i.isOdd ? jalan : tipis);
    }
  }

  @override
  bool shouldRepaint(covariant _PetaPainter old) => old.variasi != variasi;
}