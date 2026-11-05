import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Alamat bawaan. `10.0.2.2` adalah alamat khusus emulator Android untuk
/// menuju `localhost` milik laptop. Bisa diganti saat menjalankan aplikasi:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8000
const apiUrlBawaan = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

/// Batas waktu tunggu setiap permintaan ke server.
const batasWaktu = Duration(seconds: 10);

const _kunciAlamat = 'api_url';

/// Alamat API yang sedang dipakai. Diubah dari halaman Pengaturan.
final ValueNotifier<String> alamatApi = ValueNotifier<String>(apiUrlBawaan);

/// Membuang spasi dan garis miring di akhir alamat.
String rapikanUrl(String nilai) => nilai.trim().replaceAll(RegExp(r'/+$'), '');

/// Mengembalikan null bila alamat valid, atau pesan galat bila tidak.
String? validasiUrl(String? nilai) {
  final teks = (nilai ?? '').trim();
  if (teks.isEmpty) return 'Alamat API wajib diisi';
  final uri = Uri.tryParse(teks);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return 'Format tidak valid. Contoh: http://10.0.2.2:8000';
  }
  return null;
}

/// Dipanggil sekali di main() sebelum runApp.
Future<void> muatAlamatApi() async {
  final prefs = await SharedPreferences.getInstance();
  alamatApi.value = prefs.getString(_kunciAlamat) ?? apiUrlBawaan;
}

Future<void> simpanAlamatApi(String nilai) async {
  final bersih = rapikanUrl(nilai);
  alamatApi.value = bersih;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kunciAlamat, bersih);
}

Future<void> resetAlamatApi() async {
  alamatApi.value = apiUrlBawaan;
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kunciAlamat);
}
