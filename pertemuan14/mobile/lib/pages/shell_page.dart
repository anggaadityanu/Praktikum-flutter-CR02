import 'package:flutter/material.dart';

import '../services/cache_store.dart';
import '../utils/format.dart';
import 'beranda_page.dart';
import 'laporan_page.dart';
import 'pengaturan_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<DateTime?>(
        valueListenable: statusOffline,
        builder: (context, waktu, _) {
          final offline = waktu != null;
          return Column(
            children: [
              // Struktur kolom tetap sama (banner dianimasikan), sehingga
              // state halaman di bawahnya tidak hilang saat banner muncul.
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.topCenter,
                child: offline
                    ? _BannerOffline(waktu: waktu)
                    : const SizedBox(width: double.infinity),
              ),
              Expanded(
                // Banner sudah menutupi area status bar, jadi halaman di bawahnya
                // tidak perlu menambah jarak atas lagi.
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: offline,
                  // IndexedStack menjaga state tiap tab tetap hidup.
                  child: IndexedStack(
                    index: _tab,
                    children: const [
                      BerandaPage(),
                      LaporanPage(),
                      PengaturanPage(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hari Ini',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

class _BannerOffline extends StatelessWidget {
  final DateTime waktu;
  const _BannerOffline({required this.waktu});

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Material(
      color: skema.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 20,
                color: skema.onTertiaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Offline: menampilkan data tersimpan '
                  '(terakhir diperbarui pukul ${jamMenit(waktu)})',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: skema.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
