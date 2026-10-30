import 'package:flutter/material.dart';

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
      // IndexedStack menjaga state tiap tab tetap hidup saat berpindah.
      body: IndexedStack(
        index: _tab,
        children: const [
          BerandaPage(),
          LaporanPage(),
          PengaturanPage(),
        ],
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