import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/foto_kos.dart';
import 'cari_kamar_screen.dart' show ikonFasilitas;
import 'lokasi_screen.dart';
import 'form_booking_screen.dart';

class DetailKamarScreen extends StatefulWidget {
  final Kamar kamar;
  const DetailKamarScreen(this.kamar, {super.key});

  @override
  State<DetailKamarScreen> createState() => _DetailKamarScreenState();
}

class _DetailKamarScreenState extends State<DetailKamarScreen> {
  final _pageCtrl = PageController();
  int _foto = 0;
  static const _jumlahFoto = 3;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kamar;
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Galeri foto + tombol back & favorit
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _jumlahFoto,
                  onPageChanged: (i) => setState(() => _foto = i),
                  itemBuilder: (_, __) =>
                      FotoKos(width: double.infinity, radius: 0, asset: k.foto),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _jumlahFoto,
                      (i) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _foto ? Colors.white : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleBtn(Icons.arrow_back,
                            onTap: () => Navigator.pop(context)),
                        _CircleBtn(
                          k.favorit ? Icons.favorite : Icons.favorite_border,
                          onTap: () => setState(() => k.favorit = !k.favorit),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.nama,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 15, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text('${k.alamat}, ${k.kota}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_border_rounded,
                        size: 17, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${k.rating} (${k.ulasan} ulasan)',
                        style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    const Text('Tersedia',
                        style: TextStyle(
                            fontSize: 12,
                            color: K.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rupiah(k.harga),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text('/ bulan',
                          style:
                              TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text('Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(k.deskripsi,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54, height: 1.5)),
                const SizedBox(height: 20),

                const Text('Fasilitas',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final f in k.fasilitas)
                      Column(
                        children: [
                          Icon(ikonFasilitas(f),
                              size: 24, color: Colors.black54),
                          const SizedBox(height: 4),
                          Text(f,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Lihat lokasi di peta
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                    onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LokasiScreen(k)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: K.bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: K.border),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.place_outlined,
                            size: 18, color: Colors.black54),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Lihat lokasi di peta',
                              style: TextStyle(fontSize: 13)),
                        ),
                        Icon(Icons.chevron_right, color: Colors.black45),
                      ],
                    ),
                  ),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FormBookingScreen(k)),
            ),
            child: const Text('Booking Sekarang'),
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn(this.icon, {required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
              color: Colors.white70, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: K.primaryDark),
        ),
      );
}