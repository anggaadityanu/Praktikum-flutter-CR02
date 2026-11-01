import 'package:flutter/material.dart';
import 'nav.dart';
import 'screens/akun_screen.dart';
import 'screens/beranda_screen.dart';
import 'screens/cari_kamar_screen.dart';
import 'screens/keluhan_screen.dart';
import 'screens/login_screen.dart';
import 'screens/tagihan_screen.dart';
import 'theme.dart';

void main() => runApp(const KostifyApp());

class KostifyApp extends StatelessWidget {
  const KostifyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kostify',
        theme: kostifyTheme(),
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(), // <- ini yang diganti (dulu MainShell)
      );
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  // tanpa const di list: halaman dibangun ulang tiap pindah tab
  List<Widget> get _pages => [
        const BerandaScreen(),
        const CariKamarScreen(),
        const TagihanScreen(),
        const KeluhanScreen(),
        const AkunScreen(),
      ];

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: tabNotifier,
        builder: (_, i, __) => Scaffold(
          body: IndexedStack(index: i, children: _pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: (v) => tabNotifier.value = v,
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: K.primary),
                  label: 'Beranda'),
              NavigationDestination(
                  icon: Icon(Icons.search),
                  selectedIcon: Icon(Icons.search, color: K.primary),
                  label: 'Cari Kamar'),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long, color: K.primary),
                  label: 'Tagihan'),
              NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble, color: K.primary),
                  label: 'Keluhan'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: K.primary),
                  label: 'Akun'),
            ],
          ),
        ),
      );
}