import 'package:flutter/material.dart';

import 'models/kegiatan.dart';
import 'pages/cari_page.dart';
import 'pages/form_kegiatan_page.dart';
import 'pages/shell_page.dart';
import 'state/pengaturan.dart';

ThemeData buatTema(Color seed, Brightness b) => ThemeData(
      useMaterial3: true,
      colorSchemeSeed: seed,
      brightness: b,
    );

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await muatPengaturan();
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
          title: 'TabungKu',
          debugShowCheckedModeBanner: false,
          theme: buatTema(seed, Brightness.light),
          darkTheme: buatTema(seed, Brightness.dark),
          themeMode: modeTema.value,
          home: const ShellPage(),
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/form':
                final k = settings.arguments as Kegiatan?;
                return MaterialPageRoute(
                  builder: (_) => FormKegiatanPage(kegiatan: k),
                );
              case '/cari':
                return MaterialPageRoute(builder: (_) => const CariPage());
            }
            return null;
          },
        );
      },
    );
  }
}