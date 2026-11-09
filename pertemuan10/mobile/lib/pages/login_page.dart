import 'package:flutter/material.dart';

import '../services/auth_api.dart';
import '../services/pesan_galat.dart';
import '../widgets/kepala_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _kunci = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _sembunyi = true;
  bool _memuat = false;
  String? _galat;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_kunci.currentState!.validate()) return;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      await AuthApi().masuk(_emailC.text.trim(), _passC.text);
      // Berhasil: sesi tersimpan dan halaman awal berpindah sendiri ke aplikasi.
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const KepalaAuth(
              judul: 'Selamat datang',
              subjudul: 'Masuk untuk melanjutkan TabungKu',
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _kunci,
                child: Column(
                  children: [
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
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _memuat ? null : _masuk(),
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Password wajib diisi' : null,
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
                        onPressed: _memuat ? null : _masuk,
                        child: _memuat
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : const Text('Masuk'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _memuat
                          ? null
                          : () => Navigator.pushNamed(context, '/daftar'),
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/status'),
                      icon: const Icon(Icons.dns_outlined, size: 18),
                      label: const Text('Status server'),
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
