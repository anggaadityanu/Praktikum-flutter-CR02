import 'package:flutter/material.dart';

class Makanan {
  final String nama;
  final int harga;
  final String deskripsi; // Soal 2: properti baru
  const Makanan(this.nama, this.harga, this.deskripsi);
}

// Soal 1: ditambah 3 menu baru (total 7)
const daftarMenu = [
  Makanan('Nasi Goreng', 15000, 'Nasi goreng dengan telur, ayam, dan kerupuk.'),
  Makanan('Mie Ayam', 12000, 'Mie kenyal dengan topping ayam dan pangsit.'),
  Makanan('Es Teh', 4000, 'Teh manis dingin yang menyegarkan.'),
  Makanan('Ayam Bakar', 20000, 'Ayam bakar bumbu kecap dengan sambal.'),
  Makanan('Soto Ayam', 14000, 'Soto kuah kuning dengan suwiran ayam dan telur.'),
  Makanan('Bakso', 13000, 'Bakso sapi dengan mie, bihun, dan kuah kaldu.'),
  Makanan('Es Jeruk', 5000, 'Perasan jeruk segar dengan es batu.'),
];

// Soal 4: fungsi format ribuan, 15000 -> Rp 15.000
String formatRupiah(int angka) {
  final s = angka.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return 'Rp $buffer';
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum 2',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const MenuPage(),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Menu')),
      body: ListView.builder(
        itemCount: daftarMenu.length,
        itemBuilder: (context, index) {
          final item = daftarMenu[index];
          // Soal 3: Card diganti Container berwarna dan sudut membulat
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.restaurant),
              title: Text(item.nama),
              subtitle: Text(formatRupiah(item.harga)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPage(makanan: item)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final Makanan makanan;
  const DetailPage({super.key, required this.makanan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(makanan.nama)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.restaurant_menu, size: 80),
              const SizedBox(height: 16),
              Text(makanan.nama, style: const TextStyle(fontSize: 24)),
              Text(formatRupiah(makanan.harga)),
              const SizedBox(height: 12),
              // Soal 2: tampilkan deskripsi
              Text(
                makanan.deskripsi,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}