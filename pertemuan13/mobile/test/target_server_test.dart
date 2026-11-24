import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/models/pengguna.dart';
import 'package:tabungku/services/api_client.dart';
import 'package:tabungku/services/api_exception.dart';
import 'package:tabungku/services/auth_api.dart';
import 'package:tabungku/services/token_storage.dart';
import 'package:tabungku/state/pengaturan.dart';
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
  // Setiap tes mulai dari keadaan login dengan target 20.000.
  setUp(() async {
    penyimpanToken = MemoryTokenStorage();
    ApiClient.resetUntukTes();
    accessToken = null;
    refreshTokenSesi = null;
    pengguna.value = null;
    targetHarian.value = 20000;
    await simpanSesi('token-abc', 'refresh-abc', Pengguna.fromJson(_profil));
  });

  group('AuthApi.ubahTarget', () {
    test('PATCH /users/me dengan token; profil tersimpan diperbarui', () async {
      late http.Request diterima;
      final api = AuthApi(
        klienToken: ApiClient(MockClient((req) async {
          diterima = req;
          return _json({..._profil, 'target_harian': 35000});
        })),
      );

      final p = await api.ubahTarget(35000);

      expect(diterima.method, 'PATCH');
      expect(diterima.url.path, '/users/me');
      expect(diterima.headers['Authorization'], 'Bearer token-abc');
      expect(jsonDecode(diterima.body), {'target_harian': 35000});

      expect(p.targetHarian, 35000);
      expect(pengguna.value?.targetHarian, 35000);
      final tersimpan = jsonDecode((await penyimpanToken.baca(kunciProfil))!)
          as Map<String, dynamic>;
      expect(tersimpan['target_harian'], 35000);
      expect(accessToken, 'token-abc'); // token tidak berubah
    });

    test('token kedaluwarsa: diperbarui otomatis lalu PATCH diulang', () async {
      final jejak = <String>[];
      final api = AuthApi(
        klienToken: ApiClient(MockClient((req) async {
          jejak.add('${req.method} ${req.url.path}');
          if (req.url.path == '/auth/refresh') {
            return _json({
              'access_token': 'baru',
              'refresh_token': 'refresh-baru',
              'token_type': 'bearer',
            });
          }
          if (req.headers['Authorization'] == 'Bearer baru') {
            return _json({..._profil, 'target_harian': 50000});
          }
          return _json({'detail': 'Token tidak valid'}, 401);
        })),
      );

      final p = await api.ubahTarget(50000);

      expect(jejak, ['PATCH /users/me', 'POST /auth/refresh', 'PATCH /users/me']);
      expect(p.targetHarian, 50000);
      expect(accessToken, 'baru');
      expect(refreshTokenSesi, 'refresh-baru');
    });

    test('ditolak server (422): galat dilempar dan profil TIDAK berubah',
        () async {
      final api = AuthApi(
        klienToken: ApiClient(MockClient((req) async {
          return _json({
            'detail': [
              {'msg': 'Input should be less than or equal to 10000000'}
            ]
          }, 422);
        })),
      );

      await expectLater(
        api.ubahTarget(99999999),
        throwsA(isA<ApiException>().having((e) => e.kode, 'kode', 422)),
      );

      expect(pengguna.value?.targetHarian, 20000);
      final tersimpan = jsonDecode((await penyimpanToken.baca(kunciProfil))!)
          as Map<String, dynamic>;
      expect(tersimpan['target_harian'], 20000);
    });

    test('server tidak terjangkau: galat dilempar, profil dan sesi tetap',
        () async {
      final api = AuthApi(
        klienToken: ApiClient(MockClient((req) async {
          throw http.ClientException('tidak ada koneksi');
        })),
      );

      await expectLater(api.ubahTarget(30000), throwsA(isA<http.ClientException>()));

      expect(pengguna.value?.targetHarian, 20000);
      expect(accessToken, 'token-abc');
    });
  });

  group('targetHarian mengikuti pengguna yang login', () {
    test('nilai awal diambil dari profil, berganti saat pengguna berganti',
        () async {
      pengguna.value = Pengguna.fromJson({..._profil, 'target_harian': 30000});
      ikutiTargetPengguna();
      expect(targetHarian.value, 30000);

      // Akun kedua di HP yang sama punya target sendiri.
      pengguna.value = const Pengguna(
        id: 2,
        nama: 'Ani',
        email: 'ani@contoh.id',
        targetHarian: 45000,
      );
      expect(targetHarian.value, 45000);
    });

    test('profil diperbarui (ubahTarget): targetHarian ikut berubah', () async {
      ikutiTargetPengguna();
      final api = AuthApi(
        klienToken: ApiClient(MockClient((req) async {
          return _json({..._profil, 'target_harian': 70000});
        })),
      );

      await api.ubahTarget(70000);

      expect(targetHarian.value, 70000);
    });

    test('keluar: nilai terakhir tidak diubah, login ulang memakai profil baru',
        () async {
      ikutiTargetPengguna();
      expect(targetHarian.value, 20000);

      await hapusSesi();
      expect(targetHarian.value, 20000);

      await simpanSesi(
        'a2',
        'r2',
        Pengguna.fromJson({..._profil, 'target_harian': 55000}),
      );
      expect(targetHarian.value, 55000);
    });
  });
}
