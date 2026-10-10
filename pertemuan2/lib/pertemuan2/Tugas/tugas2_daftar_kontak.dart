import 'package:flutter/material.dart';

class Kontak {
  final String nama;
  final String telepon;
  final String email;
  const Kontak(this.nama, this.telepon, this.email);
}

const daftarKontak = [
  Kontak('Budi Santoso', '081234567890', 'budi.santoso@email.com'),
  Kontak('Citra Lestari', '082345678901', 'citra.lestari@email.com'),
  Kontak('Dimas Prasetyo', '083456789012', 'dimas.prasetyo@email.com'),
  Kontak('Eka Putri', '084567890123', 'eka.putri@email.com'),
  Kontak('Fajar Nugroho', '085678901234', 'fajar.nugroho@email.com'),
  Kontak('Gita Permata', '086789012345', 'gita.permata@email.com'),
  Kontak('Hendra Wijaya', '087890123456', 'hendra.wijaya@email.com'),
];

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Kontak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const KontakPage(),
    );
  }
}

class KontakPage extends StatelessWidget {
  const KontakPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kontak')),
      body: ListView.builder(
        itemCount: daftarKontak.length,
        itemBuilder: (context, index) {
          final kontak = daftarKontak[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(kontak.nama[0].toUpperCase()),
            ),
            title: Text(kontak.nama),
            subtitle: Text(kontak.telepon),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailKontakPage(kontak: kontak),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DetailKontakPage extends StatelessWidget {
  final Kontak kontak;
  const DetailKontakPage({super.key, required this.kontak});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Kontak')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 48,
              child: Text(
                kontak.nama[0].toUpperCase(),
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              kontak.nama,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone),
                const SizedBox(width: 8),
                Text(kontak.telepon, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.email),
                const SizedBox(width: 8),
                Text(kontak.email, style: const TextStyle(fontSize: 18)),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}