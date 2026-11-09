import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'models/kegiatan.dart';
import 'models/pengguna.dart';
import 'pages/cari_page.dart';
import 'pages/form_kegiatan_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/shell_page.dart';
import 'pages/status_server_page.dart';
import 'state/pengaturan.dart';
import 'state/sesi.dart';

final navigatorKey = GlobalKey<NavigatorState>();

ThemeData buatTema(Color seed, Brightness b) => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: b,
    );

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await muatPengaturan();
  await muatAlamatApi();
  await muatSesi();

  // Auto-logout: begitu sesi dihapus, tutup semua halaman yang sedang terbuka
  // agar halaman Login (rute awal) terlihat.
  pengguna.addListener(() {
    if (pengguna.value == null) {
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
    }
  });

  runApp(const TabungKuApp());
}

class TabungKuApp extends StatelessWidget {
  const TabungKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([modeTema, indeksWarna]),
      builder: (context, _) {
        final seed = daftarWarna[indeksWarna.value].warna;
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'TabungKu',
          debugShowCheckedModeBanner: false,
          theme: buatTema(seed, Brightness.light),
          darkTheme: buatTema(seed, Brightness.dark),
          themeMode: modeTema.value,
          // Halaman awal ditentukan sesi: belum login -> Login, sudah -> aplikasi.
          home: ValueListenableBuilder<Pengguna?>(
            valueListenable: pengguna,
            builder: (context, p, _) =>
                p == null ? const LoginPage() : const ShellPage(),
          ),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/form':
                final k = settings.arguments as Kegiatan?;
                return MaterialPageRoute(
                  builder: (_) => FormKegiatanPage(kegiatan: k),
                );
              case '/cari':
                return MaterialPageRoute(builder: (_) => const CariPage());
              case '/status':
                return MaterialPageRoute(
                  builder: (_) => const StatusServerPage(),
                );
              case '/daftar':
                return MaterialPageRoute(builder: (_) => const RegisterPage());
            }
            return null;
          },
        );
      },
    );
  }
}
