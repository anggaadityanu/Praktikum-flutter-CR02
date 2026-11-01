import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../nav.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';

class KeluhanScreen extends StatefulWidget {
  const KeluhanScreen({super.key});

  @override
  State<KeluhanScreen> createState() => _KeluhanScreenState();
}

class _KeluhanScreenState extends State<KeluhanScreen> {
  static const _kategori = [
    'Fasilitas', 'Kebersihan', 'Keamanan', 'Listrik & Air', 'Lainnya'
  ];

  StatusChip _chip(String s) {
    switch (s) {
      case 'Baru':
        return const StatusChip('Baru', bg: K.warn, fg: Color(0xFF8A5A00));
      default:
        return StatusChip(s);
    }
  }

  Future<void> _buatKeluhan() async {
    final judul = TextEditingController();
    final deskripsi = TextEditingController();
    String kategori = _kategori.first;
    String? error;

    final kirim = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buat Keluhan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: kategori,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  for (final k in _kategori)
                    DropdownMenuItem(value: k, child: Text(k)),
                ],
                onChanged: (v) => setSheet(() => kategori = v ?? kategori),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: judul,
                decoration: InputDecoration(
                  labelText: 'Judul keluhan',
                  isDense: true,
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deskripsi,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Ceritakan masalahnya',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (judul.text.trim().isEmpty) {
                    setSheet(() => error = 'Judul wajib diisi');
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('Kirim Keluhan'),
              ),
            ],
          ),
        ),
      ),
    );

    if (kirim == true) {
      setState(() => daftarKeluhan.insert(
            0,
            Keluhan(kategori, judul.text.trim(), deskripsi.text.trim(),
                tanggalHariIni()),
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Keluhan terkirim')));
    }
    judul.dispose();
    deskripsi.dispose();
  }

  void _detail(Keluhan k) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(k.judul,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                _chip(k.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('${k.kategori} • ${k.tanggal}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            Text(k.deskripsi.isEmpty ? 'Tanpa deskripsi.' : k.deskripsi),
            if (k.status != 'Selesai') ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => k.status = 'Selesai');
                  Navigator.pop(sheetCtx);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: K.primary,
                  side: const BorderSide(color: K.primary),
                ),
                child: const Text('Tandai Selesai'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kosong = daftarKeluhan.isEmpty;

    return Scaffold(
      backgroundColor: kosong ? Colors.white : K.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => tabNotifier.value = tabBeranda,
        ),
        title: const Text('Keluhan'),
      ),
      body: kosong
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 72,
                      decoration: BoxDecoration(
                        color: K.mint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.chat_bubble_outline,
                          size: 38, color: K.primary),
                    ),
                    const SizedBox(height: 20),
                    const Text('Belum ada keluhan',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    const Text(
                      'Jika ada masalah, silakan buat keluhan baru.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _buatKeluhan,
                      child: const Text('Buat Keluhan'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: daftarKeluhan.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final k = daftarKeluhan[i];
                return AppCard(
                  onTap: () => _detail(k),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(k.judul,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          _chip(k.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${k.kategori} • ${k.tanggal}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: kosong
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton(
                  onPressed: _buatKeluhan,
                  child: const Text('Buat Keluhan'),
                ),
              ),
            ),
    );
  }
}