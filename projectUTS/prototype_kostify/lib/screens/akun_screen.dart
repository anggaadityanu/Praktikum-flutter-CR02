import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../nav.dart';
import '../theme.dart';
import 'pengaturan_screen.dart';
import 'login_screen.dart';

Future<void> konfirmasiLogout(BuildContext context) async {
  final ya = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Keluar dari akun?'),
      content: const Text('Anda akan kembali ke halaman utama.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal')),
        TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar')),
      ],
    ),
  );
    if (ya == true && context.mounted) {
    tabNotifier.value = tabBeranda;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }
}

class AkunScreen extends StatelessWidget {
  const AkunScreen({super.key});

  void _info(BuildContext context, String teks) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(teks)));

  void _sheet(BuildContext context, String judul, List<List<String>> baris) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(judul,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            for (final b in baris)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(b[0],
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    Flexible(
                      child: Text(b[1],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = <_Menu>[
      _Menu(Icons.person_outline, 'Informasi Akun',
          () => _sheet(context, 'Informasi Akun', [
                ['Nama', namaUser],
                ['Email', emailUser],
              ])),
      _Menu(Icons.description_outlined, 'Riwayat Penyewaan',
          () => _sheet(context, 'Riwayat Penyewaan', [
                ['Kos', kamarAnda.nama],
                ['Kamar', 'No. $nomorKamarAnda'],
                ['Alamat', kamarAnda.alamat],
                ['Status', 'Dihuni'],
              ])),
      _Menu(Icons.credit_card_outlined, 'Metode Pembayaran',
          () => _info(context, 'Metode pembayaran dipilih saat membayar tagihan')),
      _Menu(Icons.notifications_none, 'Notifikasi',
          () => _info(context, 'Belum ada notifikasi baru')),
      _Menu(Icons.settings_outlined, 'Pengaturan', () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PengaturanScreen()));
      }),
      _Menu(Icons.help_outline, 'Bantuan & Panduan',
          () => _info(context, 'Pusat bantuan segera hadir')),
      _Menu(Icons.info_outline, 'Tentang Kostify', () {
        showAboutDialog(
          context: context,
          applicationName: 'Kostify',
          applicationVersion: versiApp,
          children: const [
            Text('Aplikasi pencarian dan pengelolaan kos untuk penyewa.')
          ],
        );
      }),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => tabNotifier.value = tabBeranda,
        ),
        title: const Text('Akun'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => konfirmasiLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header profil
          Container(
            color: K.primary,
            padding: const EdgeInsets.only(bottom: 24, top: 4),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: K.mint,
                  child: Icon(Icons.person_outline, size: 42, color: K.primary),
                ),
                const SizedBox(height: 10),
                const Text(namaUser,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text(emailUser,
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),

          // Daftar menu
          for (final m in menu)
            Column(
              children: [
                ListTile(
                  leading: Icon(m.ikon, color: Colors.black54, size: 22),
                  title: Text(m.label, style: const TextStyle(fontSize: 14)),
                  trailing:
                      const Icon(Icons.chevron_right, color: Colors.black38),
                  onTap: m.onTap,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ),

          // Logout
          ListTile(
            title: const Text('Logout', style: TextStyle(fontSize: 14)),
            onTap: () => konfirmasiLogout(context),
          ),
        ],
      ),
    );
  }
}

class _Menu {
  final IconData ikon;
  final String label;
  final VoidCallback onTap;
  _Menu(this.ikon, this.label, this.onTap);
}