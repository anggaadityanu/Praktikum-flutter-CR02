import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Praktikum 4',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const PenggunaPage(),
    );
  }
}

class Pengguna {
  final int id;
  final String name;
  final String username; // Soal 1
  final String email;
  final String phone;
  final String website;
  final String city; // Soal 1: data bersarang json['address']['city']

  const Pengguna({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.city,
  });

  factory Pengguna.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>;
    return Pengguna(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      city: address['city'] as String,
    );
  }
}

Future<List<Pengguna>> ambilPengguna() async {
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/users');
  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('Gagal memuat data (kode ${response.statusCode})');
  }
  final List<dynamic> data = jsonDecode(response.body);
  return data.map((e) => Pengguna.fromJson(e as Map<String, dynamic>)).toList();
}

class PenggunaPage extends StatefulWidget {
  const PenggunaPage({super.key});

  @override
  State<PenggunaPage> createState() => _PenggunaPageState();
}

class _PenggunaPageState extends State<PenggunaPage> {
  late Future<List<Pengguna>> _future;

  @override
  void initState() {
    super.initState();
    _future = ambilPengguna();
  }

  // Soal 2: dipakai juga oleh RefreshIndicator, karena itu dibuat return Future
  Future<void> _muatUlang() async {
    setState(() {
      _future = ambilPengguna();
    });
    await _future.catchError((_) {}); // tunggu selesai, abaikan error di sini
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pengguna'),
        actions: [
          // Soal 4: jumlah pengguna di AppBar
          FutureBuilder<List<Pengguna>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(child: Text('${snapshot.data!.length} pengguna')),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _muatUlang),
        ],
      ),
      body: FutureBuilder<List<Pengguna>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Terjadi kesalahan:\n${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _muatUlang, child: const Text('Coba lagi')),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          // Soal 3: teks saat daftar kosong
          if (data.isEmpty) {
            return const Center(child: Text('Tidak ada data'));
          }

          // Soal 2: RefreshIndicator membungkus ListView
          return RefreshIndicator(
            onRefresh: _muatUlang,
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, i) {
                final p = data[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(p.name[0])),
                  title: Text(p.name),
                  subtitle: Text(p.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailPenggunaPage(pengguna: p)),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DetailPenggunaPage extends StatelessWidget {
  final Pengguna pengguna;
  const DetailPenggunaPage({super.key, required this.pengguna});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pengguna.name)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(pengguna.username), // Soal 1
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: Text(pengguna.email),
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text(pengguna.phone),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(pengguna.website),
          ),
          ListTile(
            leading: const Icon(Icons.location_city),
            title: Text(pengguna.city), // Soal 1
          ),
        ],
      ),
    );
  }
}