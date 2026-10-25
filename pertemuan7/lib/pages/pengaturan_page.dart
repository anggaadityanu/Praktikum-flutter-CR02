import 'package:flutter/material.dart';

import '../state/pengaturan.dart';
import '../utils/format.dart';

class PengaturanPage extends StatefulWidget {
  const PengaturanPage({super.key});

  @override
  State<PengaturanPage> createState() => _PengaturanPageState();
}

class _PengaturanPageState extends State<PengaturanPage> {
  late double _slider;

  @override
  void initState() {
    super.initState();
    _slider = targetHarian.value.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _JudulBagian('Tampilan'),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: modeTema,
                builder: (context, mode, _) => SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('Sistem'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Terang'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Gelap'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => setModeTema(s.first),
                  ),
                ),
              ),
            ),
          ),
          const _JudulBagian('Warna tema'),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ValueListenableBuilder<int>(
                valueListenable: indeksWarna,
                builder: (context, terpilih, _) => Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < daftarWarna.length; i++)
                      GestureDetector(
                        onTap: () => setIndeksWarna(i),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: daftarWarna[i].warna,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: terpilih == i
                                      ? skema.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: terpilih == i
                                  ? const Icon(Icons.check,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              daftarWarna[i].nama,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const _JudulBagian('Target tabungan harian'),
          Card.outlined(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    rupiah(_slider.round()),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: skema.primary,
                    ),
                  ),
                  Slider(
                    value: _slider,
                    min: targetMin.toDouble(),
                    max: targetMaks.toDouble(),
                    divisions: (targetMaks - targetMin) ~/ 5000,
                    label: rupiah(_slider.round()),
                    onChanged: (v) => setState(() => _slider = v),
                    onChangeEnd: (v) => setTarget(v.round()),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rupiah(targetMin),
                          style: TextStyle(color: skema.onSurfaceVariant)),
                      Text(rupiah(targetMaks),
                          style: TextStyle(color: skema.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  final String teks;
  const _JudulBagian(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        teks,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}