import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/services/health_service.dart';

void main() {
  test('200: API dan database sehat', () async {
    final client = MockClient((req) async {
      expect(req.url.path, '/health');
      return http.Response(
        jsonEncode({
          'status': 'ok',
          'waktu_server': '2026-10-30T10:00:00',
          'database': 'ok',
          'mysql_version': '8.4.13',
        }),
        200,
      );
    });

    final s = await cekServer(client: client);

    expect(s.status, 'ok');
    expect(s.databaseOk, isTrue);
    expect(s.mysqlVersion, '8.4.13');
    expect(s.detail, isNull);
  });

  test('503: API hidup, database mati (bukan galat)', () async {
    final client = MockClient((req) async {
      return http.Response(
        jsonEncode({
          'status': 'degraded',
          'waktu_server': '2026-10-30T10:00:00',
          'database': 'error',
          'mysql_version': null,
          'detail': 'Tidak dapat terhubung ke database MySQL.',
        }),
        503,
      );
    });

    final s = await cekServer(client: client);

    expect(s.databaseOk, isFalse);
    expect(s.mysqlVersion, isNull);
    expect(s.detail, 'Tidak dapat terhubung ke database MySQL.');
  });

  test('kode lain (500): dianggap galat', () async {
    final client = MockClient((req) async => http.Response('galat', 500));

    expect(cekServer(client: client), throwsException);
  });
}
