import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../theme.dart';
import 'akun_screen.dart' show konfirmasiLogout;


class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  Future<void> _pilih(String judul, List<String> opsi, String aktif,
      void Function(String) simpan) async {
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(judul,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            for (final o in opsi)
              ListTile(
                title: Text(o),
                trailing: o == aktif
                    ? const Icon(Icons.check, color: K.primary)
                    : null,
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
    if (v != null) setState(() => simpan(v));
  }

  void _teks(String judul, String isi) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(judul),
        content: Text(isi),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _item(IconData ikon, String label,
      {String? nilai, Widget? trailing, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(ikon, color: Colors.black54, size: 22),
          title: Text(label, style: const TextStyle(fontSize: 14)),
          trailing: trailing ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (nilai != null)
                    Text(nilai,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  if (onTap != null)
                    const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => konfirmasiLogout(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          _item(
            Icons.notifications_none,
            'Notifikasi',
            trailing: Switch(
              value: notifAktif,
              activeColor: Colors.white,
              activeTrackColor: K.primary,
              onChanged: (v) => setState(() => notifAktif = v),
            ),
          ),
          _item(Icons.language, 'Bahasa',
              nilai: bahasaApp,
              onTap: () => _pilih('Bahasa', ['Bahasa Indonesia', 'English'],
                  bahasaApp, (v) => bahasaApp = v)),
          _item(Icons.dark_mode_outlined, 'Tema Aplikasi',
              nilai: temaApp,
              onTap: () => _pilih('Tema Aplikasi', ['Terang', 'Gelap', 'Sistem'],
                  temaApp, (v) => temaApp = v)),
          _item(Icons.shield_outlined, 'Privasi & Keamanan',
              onTap: () => _teks('Privasi & Keamanan',
                  'Data Anda disimpan dengan aman dan hanya digunakan untuk keperluan layanan Kostify.')),
          _item(Icons.description_outlined, 'Syarat & Ketentuan',
              onTap: () => _teks('Syarat & Ketentuan',
                  'Dengan menggunakan Kostify, Anda menyetujui ketentuan sewa dan pembayaran yang berlaku.')),
          _item(Icons.lock_outline, 'Kebijakan Privasi',
              onTap: () => _teks('Kebijakan Privasi',
                  'Kami tidak membagikan data pribadi Anda kepada pihak ketiga tanpa persetujuan.')),
          _item(Icons.info_outline, 'Versi Aplikasi', nilai: versiApp),
        ],
      ),
    );
  }
}