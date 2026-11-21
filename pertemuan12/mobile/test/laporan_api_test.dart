import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/models/kegiatan.dart';
import 'package:tabungku/services/api_exception.dart';
import 'package:tabungku/services/laporan_api.dart';

/// Contoh Skenario Satu Hari (modul 7).
const _harianContoh = {
  'tanggal': '2026-10-06',
  'jumlah_kegiatan': 4,
  'selesai': 2,
  'pemasukan': 50000,
  'pengeluaran': 25000,
  'tabungan': 25000,
  'per_kategori': [
    {'kategori': 'Makan', 'total': 15000},
    {'kategori': 'Transport', 'total': 10000},
  ],
};

http.Response _balas(Object isi, [int kode = 200]) =>
    http.Response(jsonEncode(isi), kode);

void main() {
  test('Ringkasan.fromJson membaca field snake_case dan menghitung tabungan', () {
    final r = Ringkasan.fromJson(_harianContoh);
    expect(r.jumlahKegiatan, 4);
    expect(r.selesai, 2);
    expect(r.pemasukan, 50000);
    expect(r.pengeluaran, 25000);
    expect(r.tabungan, 25000);
  });

  group('LaporanApi.harian', () {
    test('mengirim tanggal di URL dan membaca skenario satu hari', () async {
      late http.Request diterima;
      final api = LaporanApi(client: MockClient((req) async {
        diterima = req;
        return _balas(_harianContoh);
      }));

      final laporan = await api.harian('2026-10-06');

      expect(diterima.method, 'GET');
      expect(diterima.url.path, '/laporan/harian');
      expect(diterima.url.queryParameters, {'tanggal': '2026-10-06'});
      expect(laporan.tanggal, '2026-10-06');
      expect(laporan.ringkasan.jumlahKegiatan, 4);
      expect(laporan.ringkasan.selesai, 2);
      expect(laporan.ringkasan.tabungan, 25000);
      expect(laporan.perKategori.map((t) => t.kategori).toList(),
          ['Makan', 'Transport']);
      expect(laporan.perKategori.map((t) => t.total).toList(), [15000, 10000]);
    });

    test('hari tanpa kegiatan: semua nol dan kategori kosong', () async {
      final api = LaporanApi(client: MockClient((req) async {
        return _balas({
          'tanggal': '2026-10-01',
          'jumlah_kegiatan': 0,
          'selesai': 0,
          'pemasukan': 0,
          'pengeluaran': 0,
          'tabungan': 0,
          'per_kategori': <Object>[],
        });
      }));

      final laporan = await api.harian('2026-10-01');

      expect(laporan.ringkasan.jumlahKegiatan, 0);
      expect(laporan.ringkasan.tabungan, 0);
      expect(laporan.perKategori, isEmpty);
    });
  });

  group('LaporanApi.rentang', () {
    test('mengirim mulai dan sampai, hasil per hari termasuk hari kosong', () async {
      late http.Request diterima;
      final api = LaporanApi(client: MockClient((req) async {
        diterima = req;
        return _balas([
          {
            'tanggal': '2026-10-04',
            'jumlah_kegiatan': 0,
            'selesai': 0,
            'pemasukan': 0,
            'pengeluaran': 0,
            'tabungan': 0,
          },
          {
            'tanggal': '2026-10-05',
            'jumlah_kegiatan': 1,
            'selesai': 1,
            'pemasukan': 0,
            'pengeluaran': 30000,
            'tabungan': -30000,
          },
          _harianContoh,
        ]);
      }));

      final hasil = await api.rentang('2026-10-04', '2026-10-06');

      expect(diterima.url.path, '/laporan/rentang');
      expect(diterima.url.queryParameters,
          {'mulai': '2026-10-04', 'sampai': '2026-10-06'});
      expect(hasil, hasLength(3));
      expect(hasil[0].tanggal, DateTime(2026, 10, 4));
      expect(hasil[0].ringkasan.jumlahKegiatan, 0);
      expect(hasil[1].ringkasan.tabungan, -30000);
      expect(hasil[2].ringkasan.tabungan, 25000);
    });

    test('400: pesan dari server dibaca sebagai ApiException', () async {
      final api = LaporanApi(client: MockClient((req) async {
        return _balas({'detail': 'Rentang maksimal 31 hari'}, 400);
      }));

      await expectLater(
        api.rentang('2026-09-01', '2026-10-05'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kode, 'kode', 400)
              .having((e) => e.pesan, 'pesan', 'Rentang maksimal 31 hari'),
        ),
      );
    });
  });
}
