import 'package:flutter/material.dart';
import '../main.dart' show MainShell;
import '../widgets/foto_kos.dart';

const _hijau1 = Color(0xFF00B98C);
const _hijau2 = Color(0xFF007A5C);
const _navy = Color(0xFF12305F);

const _emailDemo = 'admin@admin.com';
const _passDemo = '123';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _sembunyi = true;
  bool _ingat = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _info(String t) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(t)));

  void _isiOtomatis() {
    setState(() {
      _email.text = _emailDemo;
      _pass.text = _passDemo;
      _error = null;
    });
  }

  Future<void> _masuk() async {
    FocusScope.of(context).unfocus();
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Email dan password wajib diisi');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 700)); // simulasi server
    if (!mounted) return;

    if (_email.text.trim() == _emailDemo && _pass.text == _passDemo) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      setState(() {
        _loading = false;
        _error = 'Email atau password salah';
      });
    }
  }

  InputDecoration _dekor(String hint, IconData ikon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        prefixIcon: Icon(ikon, size: 18, color: Colors.black54),
        suffixIcon: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _hijau1, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _hero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: _form(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero() => Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_hijau1, _hijau2],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              children: [
                // Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_work_outlined,
                          size: 20, color: _hijau1),
                    ),
                    const SizedBox(width: 8),
                    const Text('Kostify',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),

                // Foto rumah + kartu "Pencarian Kos"
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: FotoKos(
                        width: double.infinity,
                        height: 170,
                        radius: 18,
                        asset:
                            'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=700&q=70',
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Color(0xFFD9F7EA),
                              child: Icon(Icons.home,
                                  size: 14, color: _hijau1),
                            ),
                            SizedBox(width: 8),
                            Text('Pencarian Kos',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _navy)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 34),

                const Text('Hunian Nyaman, Sewa Tanpa Ribet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _navy,
                        fontSize: 22,
                        height: 1.25,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text(
                  'Temukan kos & kontrakan terbaik dengan proses booking dan pembayaran yang mudah, transparan, dan terjamin aman 100%.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 18),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _ChipFitur(Icons.check_circle, 'Booking Online'),
                    _ChipFitur(Icons.shield, 'Pembayaran Aman'),
                    _ChipFitur(Icons.headset_mic, 'Support 24/7'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _form() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selamat Datang Kembali!',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 4),
          const Text(
              'Silakan masukkan email dan password Anda untuk masuk ke dashboard.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
          const SizedBox(height: 16),

          // Kotak info akun demo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8F1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFEBD8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Akun demo (prototipe)',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _hijau2)),
                      SizedBox(height: 4),
                      Text('Email    : admin@admin.com',
                          style: TextStyle(fontSize: 12)),
                      Text('Password : 123', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _isiOtomatis,
                  style: TextButton.styleFrom(foregroundColor: _hijau2),
                  child: const Text('Isi otomatis',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text('Email Address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: _dekor('contoh@gmail.com', Icons.mail),
          ),
          const SizedBox(height: 14),

          const Text('Password',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _pass,
            obscureText: _sembunyi,
            onSubmitted: (_) => _masuk(),
            decoration: _dekor(
              '••••••••',
              Icons.lock,
              suffix: IconButton(
                icon: Icon(
                    _sembunyi ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: Colors.black54),
                onPressed: () => setState(() => _sembunyi = !_sembunyi),
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 6),
                Text(_error!,
                    style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],
            ),
          ],
          const SizedBox(height: 10),

          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _ingat,
                  activeColor: _hijau1,
                  onChanged: (v) => setState(() => _ingat = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Ingat Saya', style: TextStyle(fontSize: 12)),
              const Spacer(),
              GestureDetector(
                onTap: () => _info('Fitur lupa password belum tersedia di prototipe'),
                child: const Text('Lupa Password?',
                    style: TextStyle(
                        fontSize: 12,
                        color: _hijau1,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Tombol masuk
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _masuk,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hijau1,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('Masuk ke Akun Saya',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('Atau masuk dengan',
                    style: TextStyle(fontSize: 11, color: Colors.black54)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () => _info('Login Google belum tersedia di prototipe'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: const BorderSide(color: Color(0xFFE2E8E5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('G',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4285F4))),
                  SizedBox(width: 10),
                  Text('Google Account', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: Wrap(
              children: [
                const Text('Belum punya akun? ',
                    style: TextStyle(fontSize: 12)),
                GestureDetector(
                  onTap: () => _info('Pendaftaran belum tersedia di prototipe'),
                  child: const Text('Daftar sekarang',
                      style: TextStyle(
                          fontSize: 12,
                          color: _hijau1,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      );
}

class _ChipFitur extends StatelessWidget {
  final IconData ikon;
  final String label;
  const _ChipFitur(this.ikon, this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}