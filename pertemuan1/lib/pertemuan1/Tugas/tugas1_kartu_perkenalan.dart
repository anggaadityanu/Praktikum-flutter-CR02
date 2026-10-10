import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kartu Perkenalan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const KartuPerkenalan(),
    );
  }
}

class KartuPerkenalan extends StatelessWidget {
  const KartuPerkenalan({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text('Kartu Perkenalan'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 120, color: Colors.indigo.shade400),
            const SizedBox(height: 20),
            Text(
              'Angga Aditya',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'NIM: 20240801165',
              style: TextStyle(fontSize: 18, color: Colors.indigo.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'Jurusan: Teknik Informatika',
              style: TextStyle(fontSize: 18, color: Colors.indigo.shade700),
            ),
          ],
        ),
      ),
    );
  }
}