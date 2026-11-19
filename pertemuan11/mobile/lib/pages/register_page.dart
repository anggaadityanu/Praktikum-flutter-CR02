import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/pesan_galat.dart';
import '../utils/validasi.dart';
import '../widgets/kepala_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _kunci = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _ulangC = TextEditingController();
  bool _sembunyi = true;
  bool _memuat = false;
  String? _galat;

  @override
  void dispose() {
    _namaC.dispose();
    _emailC.dispose();
    _passC.dispose();
    _ulangC.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!_kunci.currentState!.validate()) return;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final api = AuthApi();
      final email = _emailC.text.trim();
      await api.daftar(_namaC.text.trim(), email, _passC.text);
      // Setelah terdaftar, langsung login.
      await api.masuk(email, _passC.text);
      if (!mounted) return;
      // Sesi sudah tersimpan: tutup halaman ini agar aplikasi utama terlihat.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = pesanGalat(e);
        _memuat = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: skema.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const KepalaAuth(
              judul: 'Buat akun',
              subjudul: 'Daftar gratis, data tabunganmu tersimpan aman',
              jarakAtas: 72,
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _kunci,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaC,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Email wajib diisi';
                        if (!t.contains('@') || !t.contains('.')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passC,
                      obscureText: _sembunyi,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password (min. 8, ada huruf dan angka)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _sembunyi ? 'Tampilkan' : 'Sembunyikan',
                          icon: Icon(
                            _sembunyi ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _sembunyi = !_sembunyi),
                        ),
                      ),
                      validator: validasiPasswordBaru,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ulangC,
                      obscureText: _sembunyi,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Ulangi password',
                        prefixIcon: Icon(Icons.lock_reset),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v != _passC.text ? 'Password tidak sama' : null,
                    ),
                    if (_galat != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: skema.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: skema.onErrorContainer),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _galat!,
                                style: TextStyle(color: skema.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _memuat ? null : _daftar,
                        child: _memuat
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Daftar dan masuk'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _memuat ? null : () => Navigator.pop(context),
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
