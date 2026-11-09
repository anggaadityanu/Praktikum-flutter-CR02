import 'package:flutter_test/flutter_test.dart';
import 'package:tabungku/utils/validasi.dart';

void main() {
  test('password yang benar diterima', () {
    expect(validasiPasswordBaru('rahasia123'), isNull);
    expect(validasiPasswordBaru('a1b2c3d4'), isNull);
  });

  test('kosong dan terlalu pendek ditolak', () {
    expect(validasiPasswordBaru(null), 'Password wajib diisi');
    expect(validasiPasswordBaru(''), 'Password wajib diisi');
    expect(validasiPasswordBaru('abc123'), 'Password minimal 8 karakter');
  });

  test('terlalu panjang ditolak', () {
    expect(validasiPasswordBaru('a1' * 37), 'Password maksimal 72 karakter');
  });

  test('hanya huruf atau hanya angka ditolak', () {
    expect(validasiPasswordBaru('abcdefgh'),
        'Password harus mengandung minimal satu angka');
    expect(validasiPasswordBaru('12345678'),
        'Password harus mengandung minimal satu huruf');
  });
}
