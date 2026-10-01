import 'package:flutter/material.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;

  void _tambah() => setState(() => _count++);

  // Soal 4: angka tidak boleh negatif
  void _kurang() {
    if (_count > 0) {
      setState(() => _count--);
    }
  }

  // Soal 3: reset ke 0
  void _reset() => setState(() => _count = 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter Saya'),
        backgroundColor: Colors.teal, // Soal 1: warna AppBar
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '$_count',
          style: const TextStyle(
            fontSize: 48,
            color: Colors.deepPurple, // Soal 1: warna teks
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'tambah',
            onPressed: _tambah,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          // Soal 2: tombol kurang
          FloatingActionButton(
            heroTag: 'kurang',
            onPressed: _kurang,
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 12),
          // Soal 3: tombol reset
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: _reset,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}