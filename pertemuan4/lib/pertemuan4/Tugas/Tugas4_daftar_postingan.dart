import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daftar Postingan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const DaftarPostinganPage(),
    );
  }
}

// ======================= MODEL =======================

class Post {
  final int id;
  final String title;
  final String body;

  const Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

class Komentar {
  final int id;
  final String name;
  final String email;
  final String body;

  const Komentar({
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  factory Komentar.fromJson(Map<String, dynamic> json) {
    return Komentar(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      body: json['body'] as String,
    );
  }
}

// ======================= LAYANAN (PENGAMBIL DATA) =======================

const _baseUrl = 'https://jsonplaceholder.typicode.com';

Future<List<Post>> ambilPostingan() async {
  final uri = Uri.parse('$_baseUrl/posts');
  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('Gagal memuat postingan (kode ${response.statusCode})');
  }
  final List<dynamic> data = jsonDecode(response.body);
  return data.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
}

Future<List<Komentar>> ambilKomentar(int postId) async {
  final uri = Uri.parse('$_baseUrl/posts/$postId/comments');
  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode != 200) {
    throw Exception('Gagal memuat komentar (kode ${response.statusCode})');
  }
  final List<dynamic> data = jsonDecode(response.body);
  return data.map((e) => Komentar.fromJson(e as Map<String, dynamic>)).toList();
}

// ======================= UI: HALAMAN DAFTAR =======================

class DaftarPostinganPage extends StatefulWidget {
  const DaftarPostinganPage({super.key});

  @override
  State<DaftarPostinganPage> createState() => _DaftarPostinganPageState();
}

class _DaftarPostinganPageState extends State<DaftarPostinganPage> {
  late Future<List<Post>> _future;

  @override
  void initState() {
    super.initState();
    _future = ambilPostingan();
  }

  void _muatUlang() {
    setState(() {
      _future = ambilPostingan();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Postingan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _muatUlang),
        ],
      ),
      body: FutureBuilder<List<Post>>(
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
          if (data.isEmpty) {
            return const Center(child: Text('Tidak ada postingan'));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final post = data[i];
              return ListTile(
                title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailPostinganPage(post: post)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ======================= UI: HALAMAN DETAIL + KOMENTAR =======================

class DetailPostinganPage extends StatefulWidget {
  final Post post;
  const DetailPostinganPage({super.key, required this.post});

  @override
  State<DetailPostinganPage> createState() => _DetailPostinganPageState();
}

class _DetailPostinganPageState extends State<DetailPostinganPage> {
  late Future<List<Komentar>> _future;

  @override
  void initState() {
    super.initState();
    _future = ambilKomentar(widget.post.id);
  }

  void _muatUlang() {
    setState(() {
      _future = ambilKomentar(widget.post.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Postingan #${widget.post.id}')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.post.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.post.body),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Komentar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          FutureBuilder<List<Komentar>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Gagal memuat komentar:\n${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _muatUlang, child: const Text('Coba lagi')),
                    ],
                  ),
                );
              }
              final komentar = snapshot.data!;
              if (komentar.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Belum ada komentar')),
                );
              }
              return Column(
                children: komentar
                    .map((k) => ListTile(
                          leading: const Icon(Icons.comment),
                          title: Text(k.name),
                          subtitle: Text('${k.email}\n${k.body}'),
                          isThreeLine: true,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}