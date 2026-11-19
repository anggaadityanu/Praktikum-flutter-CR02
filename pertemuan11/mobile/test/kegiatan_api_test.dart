import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/models/kegiatan.dart';
import 'package:tabungku/services/api_exception.dart';
import 'package:tabungku/services/kegiatan_api.dart';

/// Contoh respons server (bentuk KegiatanOut).
const _contoh = {
  'id': 1,
  'judul': 'Makan siang',
  'tanggal': '2026-10-06',
  'selesai': false,
  'tipe': 'pengeluaran',
  'nominal': 15000,
  'kategori': 'Makan',
  'created_at': '2026-10-06T08:00:00',
  'updated_at': '2026-10-06T08:00:00',
};

http.Response _balas(Object isi, [int kode = 200]) =>
    http.Response(jsonEncode(isi), kode);

void main() {
  group('Konversi JSON', () {
    test('toJson tidak membawa id dan memakai nama tipe', () {
      const k = Kegiatan(
        id: 7,
        judul: 'Makan siang',
        tanggal: '2026-10-06',
        tipe: Tipe.pengeluaran,
        nominal: 15000,
        kategori: 'Makan',
      );
      expect(k.toJson(), {
        'judul': 'Makan siang',
        'tanggal': '2026-10-06',
        'selesai': false,
        'tipe': 'pengeluaran',
        'nominal': 15000,
        'kategori': 'Makan',
      });
    });

    test('fromJson membaca respons server', () {
      final k = Kegiatan.fromJson(_contoh);
      expect(k.id, 1);
      expect(k.judul, 'Makan siang');
      expect(k.tipe, Tipe.pengeluaran);
      expect(k.nominal, 15000);
      expect(k.selesai, isFalse);
    });
  });

  group('KegiatanApi', () {
    test('daftar: filter tanggal masuk ke URL', () async {
      late http.Request diterima;
      final api = KegiatanApi(client: MockClient((req) async {
        diterima = req;
        return _balas([_contoh]);
      }));

      final hasil = await api.daftar(tanggal: '2026-10-06');

      expect(diterima.method, 'GET');
      expect(diterima.url.path, '/kegiatan');
      expect(diterima.url.queryParameters, {'tanggal': '2026-10-06'});
      expect(hasil, hasLength(1));
      expect(hasil.first.judul, 'Makan siang');
    });

    test('daftar: tanpa tanggal tidak ada query di URL', () async {
      late http.Request diterima;
      final api = KegiatanApi(client: MockClient((req) async {
        diterima = req;
        return _balas(<Object>[]);
      }));

      await api.daftar();

      expect(diterima.url.hasQuery, isFalse);
    });

    test('tambah: POST mengirim JSON tanpa id', () async {
      late http.Request diterima;
      final api = KegiatanApi(client: MockClient((req) async {
        diterima = req;
        return _balas(_contoh, 201);
      }));

      final hasil = await api.tambah(const Kegiatan(
        judul: 'Makan siang',
        tanggal: '2026-10-06',
        tipe: Tipe.pengeluaran,
        nominal: 15000,
        kategori: 'Makan',
      ));

      expect(diterima.method, 'POST');
      expect(diterima.url.path, '/kegiatan');
      expect(diterima.headers['Content-Type'], contains('application/json'));
      final isi = jsonDecode(diterima.body) as Map<String, dynamic>;
      expect(isi['judul'], 'Makan siang');
      expect(isi['nominal'], 15000);
      expect(isi.containsKey('id'), isFalse);
      expect(hasil.id, 1);
    });

    test('setSelesai: PATCH hanya mengirim selesai', () async {
      late http.Request diterima;
      final api = KegiatanApi(client: MockClient((req) async {
        diterima = req;
        return _balas({..._contoh, 'selesai': true});
      }));

      final hasil = await api.setSelesai(5, true);

      expect(diterima.method, 'PATCH');
      expect(diterima.url.path, '/kegiatan/5');
      expect(jsonDecode(diterima.body), {'selesai': true});
      expect(hasil.selesai, isTrue);
    });

    test('hapus: DELETE membalas 204 tanpa isi', () async {
      late http.Request diterima;
      final api = KegiatanApi(client: MockClient((req) async {
        diterima = req;
        return http.Response('', 204);
      }));

      await api.hapus(2);

      expect(diterima.method, 'DELETE');
      expect(diterima.url.path, '/kegiatan/2');
    });

    test('422: pesan dibaca dari detail dan awalan Value error dibuang', () async {
      final api = KegiatanApi(client: MockClient((req) async {
        return _balas({
          'detail': [
            {
              'type': 'value_error',
              'loc': ['body', 'judul'],
              'msg': 'Value error, judul wajib diisi',
            }
          ]
        }, 422);
      }));

      await expectLater(
        api.setSelesai(1, true),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kode, 'kode', 422)
              .having((e) => e.pesan, 'pesan', 'judul wajib diisi'),
        ),
      );
    });

    test('404: detail berupa teks langsung dipakai sebagai pesan', () async {
      final api = KegiatanApi(client: MockClient((req) async {
        return _balas({'detail': 'Kegiatan tidak ditemukan'}, 404);
      }));

      await expectLater(
        api.hapus(99),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kode, 'kode', 404)
              .having((e) => e.pesan, 'pesan', 'Kegiatan tidak ditemukan'),
        ),
      );
    });

    test('respons bukan JSON: pakai pesan bawaan dengan kode status', () async {
      final api = KegiatanApi(client: MockClient((req) async {
        return http.Response('<html>Bad Gateway</html>', 502);
      }));

      await expectLater(
        api.daftar(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kode, 'kode', 502)
              .having((e) => e.pesan, 'pesan', 'Server membalas kode 502'),
        ),
      );
    });
  });
}
