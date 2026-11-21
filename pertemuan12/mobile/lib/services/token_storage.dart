import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraksi penyimpanan token. Kode aplikasi hanya bergantung pada kelas ini,
/// sehingga test dapat memakai [MemoryTokenStorage] tanpa plugin native.
abstract class TokenStorage {
  Future<String?> baca(String kunci);
  Future<void> tulis(String kunci, String nilai);
  Future<void> hapusSemua();
}

/// Disimpan terenkripsi: Keystore (Android) dan Keychain (iOS).
class SecureTokenStorage implements TokenStorage {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> baca(String kunci) => _storage.read(key: kunci);

  @override
  Future<void> tulis(String kunci, String nilai) =>
      _storage.write(key: kunci, value: nilai);

  @override
  Future<void> hapusSemua() => _storage.deleteAll();
}

/// Penyimpanan di memori (untuk pengujian).
class MemoryTokenStorage implements TokenStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> baca(String kunci) async => _data[kunci];

  @override
  Future<void> tulis(String kunci, String nilai) async => _data[kunci] = nilai;

  @override
  Future<void> hapusSemua() async => _data.clear();
}
