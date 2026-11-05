import 'package:flutter_test/flutter_test.dart';
import 'package:tabungku/config/api_config.dart';

void main() {
  test('validasiUrl menerima alamat yang benar', () {
    expect(validasiUrl('http://10.0.2.2:8000'), isNull);
    expect(validasiUrl('https://api.contoh.com'), isNull);
  });

  test('validasiUrl menolak alamat yang salah', () {
    expect(validasiUrl(''), isNotNull);
    expect(validasiUrl('10.0.2.2:8000'), isNotNull);
    expect(validasiUrl('ftp://server'), isNotNull);
    expect(validasiUrl('http://'), isNotNull);
    expect(validasiUrl('bukan url'), isNotNull);
  });

  test('rapikanUrl membuang spasi dan garis miring di akhir', () {
    expect(rapikanUrl(' http://10.0.2.2:8000/ '), 'http://10.0.2.2:8000');
  });
}
