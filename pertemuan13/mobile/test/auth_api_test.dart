import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/models/pengguna.dart';
import 'package:tabungku/services/api_exception.dart';
import 'package:tabungku/services/auth_api.dart';
import 'package:tabungku/services/token_storage.dart';
import 'package:tabungku/state/sesi.dart';

const _profil = {
  'id': 1,
  'nama': 'Budi',
  'email': 'budi@contoh.id',
  'target_harian': 20000,
};

http.Response _json(Object isi, [int kode = 200]) =>
    http.Response(jsonEncode(isi), kode);

void main() {
  // Setiap tes mulai dari keadaan bersih: belum login, penyimpanan di memori.
  setUp(() {
    penyimpanToken = MemoryTokenStorage();
    accessToken = null;
    refreshTokenSesi = null;
    pengguna.value = null;
  });

  group('AuthApi', () {
    test('masuk: mengirim form, memuat profil, menyimpan kedua token',
        () async {
      final diterima = <http.Request>[];
      final api = AuthApi(client: MockClient((req) async {
        diterima.add(req);
        if (req.url.path == '/auth/login') {
          return _json({
            'access_token': 'token-abc',
            'refresh_token': 'refresh-abc',
            'token_type': 'bearer',
          });
        }
        return _json(_profil);
      }));

      final p = await api.masuk('budi@contoh.id', 'rahasia123');

      expect(diterima[0].method, 'POST');
      expect(diterima[0].url.path, '/auth/login');
      expect(diterima[0].headers['content-type'],
          contains('application/x-www-form-urlencoded'));
      expect(diterima[0].bodyFields,
          {'username': 'budi@contoh.id', 'password': 'rahasia123'});
      expect(diterima[1].url.path, '/users/me');
      expect(diterima[1].headers['Authorization'], 'Bearer token-abc');

      expect(p.nama, 'Budi');
      expect(accessToken, 'token-abc');
      expect(refreshTokenSesi, 'refresh-abc');
      expect(pengguna.value?.email, 'budi@contoh.id');
      expect(await penyimpanToken.baca(kunciToken), 'token-abc');
      expect(await penyimpanToken.baca(kunciRefresh), 'refresh-abc');
      expect(await penyimpanToken.baca(kunciProfil), isNotNull);
    });

    test('masuk gagal 401: pesan server dilempar dan sesi tidak disimpan',
        () async {
      final api = AuthApi(client: MockClient((req) async {
        return _json({'detail': 'Email atau password salah'}, 401);
      }));

      await expectLater(
        api.masuk('budi@contoh.id', 'salah'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kode, 'kode', 401)
              .having((e) => e.pesan, 'pesan', 'Email atau password salah'),
        ),
      );

      expect(accessToken, isNull);
      expect(refreshTokenSesi, isNull);
      expect(pengguna.value, isNull);
      expect(await penyimpanToken.baca(kunciToken), isNull);
    });

    test('daftar: mengirim JSON dan tidak menyimpan sesi', () async {
      late http.Request diterima;
      final api = AuthApi(client: MockClient((req) async {
        diterima = req;
        return _json(_profil, 201);
      }));

      final p = await api.daftar('Budi', 'budi@contoh.id', 'rahasia123');

      expect(diterima.method, 'POST');
      expect(diterima.url.path, '/auth/register');
      expect(diterima.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(diterima.body), {
        'nama': 'Budi',
        'email': 'budi@contoh.id',
        'password': 'rahasia123',
      });
      expect(p.id, 1);
      expect(pengguna.value, isNull);
    });

    test('refresh: mengirim refresh token dan membaca pasangan baru',
        () async {
      late http.Request diterima;
      final api = AuthApi(client: MockClient((req) async {
        diterima = req;
        return _json({
          'access_token': 'a2',
          'refresh_token': 'r2',
          'token_type': 'bearer',
        });
      }));

      final p = await api.refresh('refresh-lama');

      expect(diterima.method, 'POST');
      expect(diterima.url.path, '/auth/refresh');
      expect(jsonDecode(diterima.body), {'refresh_token': 'refresh-lama'});
      expect(p.access, 'a2');
      expect(p.refresh, 'r2');
    });

    test('refresh ditolak: ApiException membawa kode dan pesan', () async {
      final api = AuthApi(client: MockClient((req) async {
        return _json({
          'detail': 'Refresh token tidak valid atau sudah kedaluwarsa'
        }, 401);
      }));

      await expectLater(
        api.refresh('rusak'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kode, 'kode', 401)
              .having((e) => e.pesan, 'pesan',
                  'Refresh token tidak valid atau sudah kedaluwarsa'),
        ),
      );
    });
  });

  group('Sesi', () {
    test('muatSesi memulihkan sesi dari penyimpanan', () async {
      await penyimpanToken.tulis(kunciToken, 'token-xyz');
      await penyimpanToken.tulis(kunciRefresh, 'refresh-xyz');
      await penyimpanToken.tulis(kunciProfil, jsonEncode(_profil));

      await muatSesi();

      expect(accessToken, 'token-xyz');
      expect(refreshTokenSesi, 'refresh-xyz');
      expect(pengguna.value?.nama, 'Budi');
    });

    test('muatSesi tanpa data tersimpan: belum login', () async {
      await muatSesi();

      expect(accessToken, isNull);
      expect(pengguna.value, isNull);
    });

    test('muatSesi tanpa refresh token (sesi lama): belum login', () async {
      await penyimpanToken.tulis(kunciToken, 'token-lama');
      await penyimpanToken.tulis(kunciProfil, jsonEncode(_profil));

      await muatSesi();

      expect(accessToken, isNull);
      expect(pengguna.value, isNull);
    });

    test('simpanTokenBaru mengganti token tanpa mengubah profil', () async {
      await simpanSesi('a1', 'r1', Pengguna.fromJson(_profil));

      await simpanTokenBaru('a2', 'r2');

      expect(accessToken, 'a2');
      expect(refreshTokenSesi, 'r2');
      expect(await penyimpanToken.baca(kunciToken), 'a2');
      expect(await penyimpanToken.baca(kunciRefresh), 'r2');
      expect(pengguna.value?.nama, 'Budi');
    });

    test('hapusSesi mengosongkan penyimpanan, token, dan pengguna', () async {
      await simpanSesi('a1', 'r1', Pengguna.fromJson(_profil));

      await hapusSesi();

      expect(accessToken, isNull);
      expect(refreshTokenSesi, isNull);
      expect(pengguna.value, isNull);
      expect(await penyimpanToken.baca(kunciToken), isNull);
      expect(await penyimpanToken.baca(kunciRefresh), isNull);
      expect(await penyimpanToken.baca(kunciProfil), isNull);
    });
  });
}
