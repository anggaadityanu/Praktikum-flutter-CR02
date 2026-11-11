import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// Root aplikasi: hanya mengatur tema dan halaman awal.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TabungKu Layout',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const RingkasanPage(),
    );
  }
}

// Model data transaksi (data statis / hard-coded).
class Transaksi {
  final String judul;
  final String tanggal;
  final int nominal;
  final bool masuk; // true = menabung, false = tarik
  const Transaksi(this.judul, this.tanggal, this.nominal, this.masuk);
}

const daftarTransaksi = [
  Transaksi('Menabung uang saku', '10 Nov 2026', 150000, true),
  Transaksi('Tarik untuk beli buku', '8 Nov 2026', 85000, false),
  Transaksi('Menabung hasil freelance', '5 Nov 2026', 300000, true),
  Transaksi('Tarik untuk bayar kos', '1 Nov 2026', 500000, false),
];

// Format angka ke rupiah, misal 1500000 -> "Rp 1.500.000".
String rupiah(int nilai) {
  final teks = nilai.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) buffer.write('.');
    buffer.write(teks[i]);
  }
  return 'Rp $buffer';
}

class RingkasanPage extends StatelessWidget {
  const RingkasanPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold: kerangka halaman, latar abu muda supaya kartu menonjol.
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Ringkasan Tabungan'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // Center + ConstrainedBox: di tablet isi dibatasi 600 px.
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          // ListView: isi bisa di-scroll sehingga tidak overflow.
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _KartuTabungan(),
              const SizedBox(height: 24),
              const _BarisKategori(),
              const SizedBox(height: 28),
              const Text(
                'Transaksi Terakhir',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Satu kartu per transaksi.
              for (final t in daftarTransaksi) _ItemTransaksi(transaksi: t),
            ],
          ),
        ),
      ),
    );
  }
}

// Kartu utama: nama tabungan, saldo, progress, dan target.
class _KartuTabungan extends StatelessWidget {
  const _KartuTabungan();

  static const int saldo = 2750000;
  static const int target = 8000000;

  @override
  Widget build(BuildContext context) {
    // Persentase tercapai (bilangan bulat), dipakai untuk lebar progress bar.
    final persen = saldo * 100 ~/ target;

    // Card: kartu berlatar teal; margin 0 agar lebarnya sejajar elemen lain.
    return Card(
      color: Colors.teal,
      margin: EdgeInsets.zero,
      // Padding: jarak antara isi kartu dan tepi kartu.
      child: Padding(
        padding: const EdgeInsets.all(20),
        // Column: susunan vertikal seluruh isi kartu.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris nama tabungan: ikon + teks.
            const Row(
              children: [
                Icon(Icons.savings, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tabungan Laptop',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Saldo', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              rupiah(saldo),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar: dua Expanded dengan flex sebanding persen.
            Row(
              children: [
                Expanded(
                  flex: persen,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.horizontal(left: Radius.circular(4)),
                    ),
                  ),
                ),
                Expanded(
                  flex: 100 - persen,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                          BorderRadius.horizontal(right: Radius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Row: persen tercapai (kiri) dan target (kanan).
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$persen% tercapai',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Target ${rupiah(target)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Satu baris berisi tiga penanda kategori.
class _BarisKategori extends StatelessWidget {
  const _BarisKategori();

  @override
  Widget build(BuildContext context) {
    // Row + spaceEvenly: tiga ikon tersebar rata.
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ItemKategori(ikon: Icons.add, label: 'Menabung', warna: Colors.green),
        _ItemKategori(ikon: Icons.remove, label: 'Tarik', warna: Colors.red),
        _ItemKategori(ikon: Icons.history, label: 'Riwayat', warna: Colors.blue),
      ],
    );
  }
}

// Kotak ikon membulat berwarna + label di bawahnya.
class _ItemKategori extends StatelessWidget {
  final IconData ikon;
  final String label;
  final MaterialColor warna;
  const _ItemKategori({
    required this.ikon,
    required this.label,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Container: kotak 60x60, ikon di tengah.
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: warna.shade50,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(ikon, color: warna.shade700, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// Satu baris transaksi: ikon, judul + tanggal, nominal.
class _ItemTransaksi extends StatelessWidget {
  final Transaksi transaksi;
  const _ItemTransaksi({required this.transaksi});

  @override
  Widget build(BuildContext context) {
    final masuk = transaksi.masuk;
    final warna = masuk ? Colors.green : Colors.red;

    // Container: kartu putih dengan sudut membulat.
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      // Row: ikon | judul+tanggal (melebar) | nominal.
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: warna.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              masuk ? Icons.arrow_downward : Icons.arrow_upward,
              color: warna.shade700,
            ),
          ),
          const SizedBox(width: 12),
          // Expanded: judul mengisi sisa lebar dan turun baris jika panjang.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaksi.judul,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  transaksi.tanggal,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tanda +/- dan warna mengikuti jenis transaksi.
          Text(
            '${masuk ? '+' : '-'} ${rupiah(transaksi.nominal)}',
            style: TextStyle(
              color: warna.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}