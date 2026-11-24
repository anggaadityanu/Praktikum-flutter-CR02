import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/models/pengguna.dart';
import 'package:tabungku/services/api_client.dart';
import 'package:tabungku/services/token_storage.dart';
import 'package:tabungku/state/sesi.dart';

const _profil = {
  'id': 1,
  'nama': 'Budi',
  'email': 'budi@contoh.id',
  'target_harian': 20000,
};

const _pasanganBaru = {
  'access_token': 'baru',
  'refresh_token': 'refresh-baru',
  'token_type': 'bearer',
};

http.Response _json(Object isi, [int kode = 200]) =>
    http.Response(jsonEncode(isi), kode);

Uri _uri(String path) => Uri.parse('http://contoh.id$path');

/// Mensimulasikan server: token 'Bearer baru' diterima, token lain ditolak 401.
http.Response _balasKegiatan(http.Request req) =>
    req.headers['Authorization'] == 'Bearer baru'
        ? _json(<Object>[])
        : _json({'detail': 'Token tidak valid atau sudah kedaluwarsa'}, 401);

void main() {
  // Setiap tes dimulai dalam keadaan login dengan token yang sudah kedaluwarsa.
  setUp(() async {
    penyimpanToken = MemoryTokenStorage();
    ApiClient.resetUntukTes();
    await simpanSesi('lama', 'refresh-lama', Pengguna.fromJson(_profil));
  });

  group('Header Authorization', () {
    test('ditambahkan bila sudah login', () async {
      late http.BaseRequest diterima;
      final client = ApiClient(MockClient((req) async {
        diterima = req;
        return http.Response('[]', 200);
      }));

      await client.get(_uri('/kegiatan'));

      expect(diterima.headers['Authorization'], 'Bearer lama');
    });

    test('tidak ditambahkan bila belum login', () async {
      await hapusSesi();
      late http.BaseRequest diterima;
      final client = ApiClient(MockClient((req) async {
        diterima = req;
        return http.Response('[]', 200);
      }));

      await client.get(_uri('/kegiatan'));

      expect(diterima.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('Auto-refresh', () {
    test('401: token diperbarui lalu request diulang sekali', () async {
      final jejak = <String>[];
      final client = ApiClient(MockClient((req) async {
        jejak.add(
            '${req.method} ${req.url.path} ${req.headers['Authorization'] ?? '-'}');
        if (req.url.path == '/auth/refresh') {
          expect(jsonDecode(req.body), {'refresh_token': 'refresh-lama'});
          return _json(_pasanganBaru);
        }
        return _balasKegiatan(req);
      }));

      final res = await client.get(_uri('/kegiatan'));

      expect(res.statusCode, 200);
      expect(jejak, [
        'GET /kegiatan Bearer lama',
        'POST /auth/refresh -',
        'GET /kegiatan Bearer baru',
      ]);
      expect(accessToken, 'baru');
      expect(refreshTokenSesi, 'refresh-baru');
      expect(await penyimpanToken.baca(kunciToken), 'baru');
      expect(await penyimpanToken.baca(kunciRefresh), 'refresh-baru');
      expect(pengguna.value, isNotNull);
    });

    test('request POST diulang dengan isi dan header yang sama', () async {
      final isi = <String>[];
      final tipeKonten = <String?>[];
      final client = ApiClient(MockClient((req) async {
        if (req.url.path == '/auth/refresh') return _json(_pasanganBaru);
        isi.add(req.body);
        tipeKonten.add(req.headers['Content-Type']);
        return _balasKegiatan(req);
      }));

      await client.post(
        _uri('/kegiatan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'judul': 'Makan'}),
      );

      expect(isi, ['{"judul":"Makan"}', '{"judul":"Makan"}']);
      expect(tipeKonten.every((t) => t != null && t.contains('application/json')),
          isTrue);
    });

    test('request hanya diulang satu kali walau masih 401', () async {
      final jejak = <String>[];
      final client = ApiClient(MockClient((req) async {
        jejak.add(req.url.path);
        if (req.url.path == '/auth/refresh') return _json(_pasanganBaru);
        return _json({'detail': 'tetap ditolak'}, 401);
      }));

      final res = await client.get(_uri('/kegiatan'));

      expect(res.statusCode, 401);
      expect(jejak, ['/kegiatan', '/auth/refresh', '/kegiatan']);
    });

    test('tiga request bersamaan hanya memicu satu refresh', () async {
      var jumlahRefresh = 0;
      final client = ApiClient(MockClient((req) async {
        if (req.url.path == '/auth/refresh') {
          jumlahRefresh++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _json(_pasanganBaru);
        }
        return _balasKegiatan(req);
      }));

      final hasil = await Future.wait([
        client.get(_uri('/laporan/harian')),
        client.get(_uri('/laporan/rentang')),
        client.get(_uri('/kegiatan')),
      ]);

      expect(hasil.map((r) => r.statusCode), everyElement(200));
      expect(jumlahRefresh, 1);
      expect(accessToken, 'baru');
    });

    test('tanpa sesi (belum login): 401 tidak memicu refresh', () async {
      await hapusSesi();
      final jejak = <String>[];
      final client = ApiClient(MockClient((req) async {
        jejak.add(req.url.path);
        return _json({'detail': 'Not authenticated'}, 401);
      }));

      final res = await client.get(_uri('/kegiatan'));

      expect(res.statusCode, 401);
      expect(jejak, ['/kegiatan']);
    });
  });

  group('401 dari endpoint auth tidak memicu refresh', () {
    for (final path in ['/auth/login', '/auth/register']) {
      test(path, () async {
        final jejak = <String>[];
        final client = ApiClient(MockClient((req) async {
          jejak.add(req.url.path);
          return _json({'detail': 'Email atau password salah'}, 401);
        }));

        final res = await client.post(_uri(path), body: {'username': 'a'});

        expect(res.statusCode, 401);
        expect(jejak, [path]); // tidak ada panggilan ke /auth/refresh
        expect(pengguna.value, isNotNull); // sesi lama tidak dihapus
      });
    }
  });

  group('Auto-logout', () {
    for (final kode in [401, 403]) {
      test('refresh ditolak ($kode): sesi dihapus', () async {
        final jejak = <String>[];
        final client = ApiClient(MockClient((req) async {
          jejak.add(req.url.path);
          if (req.url.path == '/auth/refresh') {
            return _json({'detail': 'ditolak'}, kode);
          }
          return _json({'detail': 'Token tidak valid'}, 401);
        }));

        final res = await client.get(_uri('/kegiatan'));

        expect(res.statusCode, 401); // pemanggil tetap menerima 401 asli
        expect(jejak, ['/kegiatan', '/auth/refresh']);
        expect(pengguna.value, isNull);
        expect(accessToken, isNull);
        expect(refreshTokenSesi, isNull);
        expect(await penyimpanToken.baca(kunciToken), isNull);
        expect(await penyimpanToken.baca(kunciRefresh), isNull);
      });
    }

    test('server tidak dapat dihubungi saat refresh: TIDAK logout', () async {
      final client = ApiClient(MockClient((req) async {
        if (req.url.path == '/auth/refresh') {
          throw http.ClientException('tidak ada koneksi');
        }
        return _json({'detail': 'Token tidak valid'}, 401);
      }));

      await expectLater(
        client.get(_uri('/kegiatan')),
        throwsA(isA<http.ClientException>()),
      );

      expect(pengguna.value, isNotNull);
      expect(accessToken, 'lama');
      expect(refreshTokenSesi, 'refresh-lama');
      expect(await penyimpanToken.baca(kunciRefresh), 'refresh-lama');
    });

    test('server error 500 saat refresh: TIDAK logout', () async {
      final client = ApiClient(MockClient((req) async {
        if (req.url.path == '/auth/refresh') {
          return _json({'detail': 'galat internal'}, 500);
        }
        return _json({'detail': 'Token tidak valid'}, 401);
      }));

      final res = await client.get(_uri('/kegiatan'));

      expect(res.statusCode, 401);
      expect(pengguna.value, isNotNull);
      expect(accessToken, 'lama');
      expect(refreshTokenSesi, 'refresh-lama');
    });
  });
}
