import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ======================= TEMA (GLOBAL STATE) =======================

final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);
final seedColor = ValueNotifier<Color>(Colors.teal);

const List<Color> pilihanWarna = [
  Colors.teal,
  Colors.indigo,
  Colors.deepOrange,
  Colors.pink,
];

ThemeData buatTema(Color seed, Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: seed,
    brightness: brightness,
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}

Future<void> _muatPreferensiTema() async {
  final prefs = await SharedPreferences.getInstance();
  final gelap = prefs.getBool('gelap') ?? false;
  final warnaIndex = prefs.getInt('warnaIndex') ?? 0;
  themeMode.value = gelap ? ThemeMode.dark : ThemeMode.light;
  seedColor.value = pilihanWarna[warnaIndex.clamp(0, pilihanWarna.length - 1)];
}

Future<void> _simpanTema() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('gelap', themeMode.value == ThemeMode.dark);
  await prefs.setInt('warnaIndex', pilihanWarna.indexOf(seedColor.value));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _muatPreferensiTema();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeMode, seedColor]),
      builder: (context, _) {
        return MaterialApp(
          title: 'Galeri Tempat Wisata',
          debugShowCheckedModeBanner: false,
          theme: buatTema(seedColor.value, Brightness.light),
          darkTheme: buatTema(seedColor.value, Brightness.dark),
          themeMode: themeMode.value,
          initialRoute: '/',
          routes: {
            '/': (_) => const ShellPage(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/detail') {
              final destinasi = settings.arguments as Destinasi;
              return PageRouteBuilder(
                settings: settings,
                transitionDuration: const Duration(milliseconds: 350),
                pageBuilder: (_, __, ___) => DetailPage(destinasi: destinasi),
                transitionsBuilder: (_, animation, __, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              );
            }
            return null;
          },
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('404')),
                body: const Center(child: Text('404 - Halaman tidak ditemukan')),
              ),
            );
          },
        );
      },
    );
  }
}

// ======================= MODEL =======================

class Destinasi {
  final int id;
  final String nama;
  final String kategori;
  final String deskripsi;
  final IconData ikon;
  final Color warna;

  const Destinasi({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.deskripsi,
    required this.ikon,
    required this.warna,
  });
}

const daftarDestinasi = [
  Destinasi(
    id: 1,
    nama: 'Raja Ampat',
    kategori: 'Bahari',
    deskripsi: 'Gugusan pulau karst dengan terumbu karang terkaya di dunia, surganya para penyelam.',
    ikon: Icons.water,
    warna: Colors.blue,
  ),
  Destinasi(
    id: 2,
    nama: 'Gunung Bromo',
    kategori: 'Pegunungan',
    deskripsi: 'Gunung berapi aktif dengan lautan pasir dan pemandangan matahari terbit yang ikonik.',
    ikon: Icons.landscape,
    warna: Colors.deepOrange,
  ),
  Destinasi(
    id: 3,
    nama: 'Candi Borobudur',
    kategori: 'Budaya',
    deskripsi: 'Candi Buddha terbesar di dunia, peninggalan Dinasti Syailendra abad ke-9.',
    ikon: Icons.temple_buddhist,
    warna: Colors.brown,
  ),
  Destinasi(
    id: 4,
    nama: 'Danau Toba',
    kategori: 'Alam',
    deskripsi: 'Danau vulkanik terbesar di Asia Tenggara dengan Pulau Samosir di tengahnya.',
    ikon: Icons.waves,
    warna: Colors.indigo,
  ),
  Destinasi(
    id: 5,
    nama: 'Kawah Ijen',
    kategori: 'Pegunungan',
    deskripsi: 'Terkenal dengan fenomena api biru dan danau kawah berwarna hijau toska.',
    ikon: Icons.local_fire_department,
    warna: Colors.teal,
  ),
  Destinasi(
    id: 6,
    nama: 'Pantai Kuta',
    kategori: 'Bahari',
    deskripsi: 'Pantai populer di Bali dengan ombak yang cocok untuk berselancar dan sunset memukau.',
    ikon: Icons.beach_access,
    warna: Colors.orange,
  ),
];

// ======================= FAVORIT (GLOBAL STATE) =======================

final favoritIds = ValueNotifier<Set<int>>({});

// ======================= SHELL: NAVIGASI TAB BAWAH =======================

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;
  static const _halaman = [BerandaTab(), FavoritTab(), PengaturanTab()];
  static const _judul = ['Galeri Wisata', 'Favorit', 'Pengaturan'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_judul[_index])),
      body: IndexedStack(index: _index, children: _halaman),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorit',
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

// ======================= TAB: BERANDA =======================

class BerandaTab extends StatelessWidget {
  const BerandaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: daftarDestinasi.length,
      itemBuilder: (context, i) => _KartuDestinasi(destinasi: daftarDestinasi[i]),
    );
  }
}

class FavoritTab extends StatelessWidget {
  const FavoritTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ValueListenableBuilder<Set<int>>(
      valueListenable: favoritIds,
      builder: (context, ids, _) {
        final data = daftarDestinasi.where((d) => ids.contains(d.id)).toList();
        if (data.isEmpty) {
          return Center(
            child: Text(
              'Belum ada destinasi favorit.\nTekan ikon hati di Beranda.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyLarge,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: data.length,
          itemBuilder: (context, i) => _KartuDestinasi(destinasi: data[i]),
        );
      },
    );
  }
}

// Kartu dipakai bersama Beranda & Favorit, dengan tombol favorit beranimasi implisit
class _KartuDestinasi extends StatelessWidget {
  final Destinasi destinasi;
  const _KartuDestinasi({required this.destinasi});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: Hero(
          tag: 'ikon-${destinasi.id}',
          child: CircleAvatar(
            radius: 26,
            backgroundColor: destinasi.warna,
            child: Icon(destinasi.ikon, color: Colors.white),
          ),
        ),
        title: Text(destinasi.nama, style: tema.textTheme.titleMedium),
        subtitle: Text(destinasi.kategori),
        trailing: _TombolFavorit(id: destinasi.id),
        onTap: () {
          Navigator.pushNamed(context, '/detail', arguments: destinasi);
        },
      ),
    );
  }
}

// Animasi IMPLISIT: AnimatedScale pada ikon favorit saat ditekan
class _TombolFavorit extends StatelessWidget {
  final int id;
  const _TombolFavorit({required this.id});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ValueListenableBuilder<Set<int>>(
      valueListenable: favoritIds,
      builder: (context, ids, _) {
        final aktif = ids.contains(id);
        return IconButton(
          onPressed: () {
            final baru = Set<int>.from(ids);
            if (aktif) {
              baru.remove(id);
            } else {
              baru.add(id);
            }
            favoritIds.value = baru;
          },
          icon: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: aktif ? 1.2 : 1.0,
            curve: Curves.elasticOut,
            child: Icon(
              aktif ? Icons.favorite : Icons.favorite_border,
              color: aktif ? tema.colorScheme.error : tema.colorScheme.outline,
            ),
          ),
        );
      },
    );
  }
}

// ======================= HALAMAN DETAIL =======================

class DetailPage extends StatefulWidget {
  final Destinasi destinasi;
  const DetailPage({super.key, required this.destinasi});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

// Animasi EKSPLISIT: AnimationController menggerakkan fade + slide saat halaman dibuka
class _DetailPageState extends State<DetailPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _geser;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _geser = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final d = widget.destinasi;
    return Scaffold(
      appBar: AppBar(title: Text(d.nama)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'ikon-${d.id}',
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: d.warna,
                  child: Icon(d.ikon, size: 64, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _geser,
                  child: Column(
                    children: [
                      Text(d.nama, style: tema.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Chip(label: Text(d.kategori)),
                      const SizedBox(height: 16),
                      Text(
                        d.deskripsi,
                        textAlign: TextAlign.center,
                        style: tema.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      _TombolFavorit(id: d.id),
                    ],
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

// ======================= TAB: PENGATURAN =======================

class PengaturanTab extends StatelessWidget {
  const PengaturanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeMode, seedColor]),
      builder: (context, _) {
        final tema = Theme.of(context);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Mode gelap'),
              value: themeMode.value == ThemeMode.dark,
              onChanged: (v) {
                themeMode.value = v ? ThemeMode.dark : ThemeMode.light;
                _simpanTema();
              },
            ),
            const SizedBox(height: 8),
            Text('Warna tema', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (final c in pilihanWarna)
                  GestureDetector(
                    onTap: () {
                      seedColor.value = c;
                      _simpanTema();
                    },
                    child: CircleAvatar(
                      backgroundColor: c,
                      child: seedColor.value == c
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}