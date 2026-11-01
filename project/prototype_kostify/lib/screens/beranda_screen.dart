import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../nav.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/app_card.dart';
import '../widgets/foto_kos.dart';
import '../widgets/status_chip.dart';
import 'detail_kamar_screen.dart';

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final belum = daftarTagihan.where((t) => !t.lunas).toList();
    final tagihan = belum.isNotEmpty ? belum.first : null;
    final terbaru = daftarKamar.last;
    final namaDepan = namaUser.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kostify'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header sapaan (menyatu dengan AppBar)
          Container(
            color: K.primary,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat datang,\n$namaDepan!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.25)),
                const SizedBox(height: 4),
                const Text('Temukan kos nyamanmu di sini.',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tagihan bulan ini
                AppCard(
                  onTap: () => tabNotifier.value = tabTagihan,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tagihan Bulan Ini',
                              style: TextStyle(fontSize: 13)),
                          tagihan == null
                              ? const StatusChip('Lunas')
                              : const StatusChip('Belum Lunas'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(rupiah(tagihan?.nominal ?? 0),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Status pembayaran
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Status Pembayaran',
                          style: TextStyle(fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: K.primary, size: 30),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Berhasil',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              Text(tanggalPembayaranTerakhir,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Kamar Anda
                const Text('Kamar Anda',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                AppCard(
                  child: Row(
                    children: [
                      FotoKos(width: 64, height: 56, asset: kamarAnda.foto),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kamarAnda.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text(kamarAnda.alamat,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 2),
                          const Text('Dihuni • Kamar No. $nomorKamarAnda',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: K.primary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Postingan terbaru
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Postingan terbaru',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    GestureDetector(
                      onTap: () => tabNotifier.value = tabCariKamar,
                      child: const Text('Lihat Semua',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppCard(
                    onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailKamarScreen(terbaru)),
                  ),
                  child: Row(
                    children: [
                      FotoKos(width: 64, height: 56, asset: terbaru.foto),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(terbaru.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          Text('${rupiah(terbaru.harga)} / bulan',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}