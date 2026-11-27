import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/config/api_config.dart';
import 'package:tabungku/models/kegiatan.dart';
import 'package:tabungku/models/laporan.dart';
import 'package:tabungku/services/api_exception.dart';
import 'package:tabungku/services/laporan_api.dart';
import 'package:tabungku/widgets/kartu_bulanan.dart';

LaporanBulanan _contoh({
  int masuk = 80000,
  int keluar = 25000,
  int tercapai = 3,
}) =>
    LaporanBulanan(
      tahun: 2026,
      bulan: 10,
      jumlahHari: 31,
      hariTargetTercapai: tercapai,
      ringkasan: Ringkasan(
        jumlahKegiatan: 4,
        selesai: 1,
        pemasukan: masuk,
        pengeluaran: keluar,
      ),
      perKategori: const [TotalKategori(kategori: 'Makan', total: 20000)],
    );

Widget _bungkus(Widget isi) => MaterialApp(home: Scaffold(body: isi));

void main() {
  group('LaporanApi.bulanan', () {
    setUp(() => alamatApi.value = 'http://uji');

    test('memanggil /laporan/bulanan dan membaca hasilnya', () async {
      final api = LaporanApi(
        client: MockClient((req) async {
          expect(req.url.path, '/laporan/bulanan');
          expect(req.url.queryParameters, {'tahun': '2026', 'bulan': '10'});
          return http.Response(
            jsonEncode({
              'tahun': 2026,
              'bulan': 10,
              'jumlah_hari': 31,
              'hari_target_tercapai': 3,
              'jumlah_kegiatan': 4,
              'selesai': 1,
              'pemasukan': 80000,
              'pengeluaran': 25000,
              'tabungan': 55000,
              'per_kategori': [
                {'kategori': 'Makan', 'total': 20000},
              ],
            }),
            200,
          );
        }),
      );

      final b = await api.bulanan(2026, 10);
      expect(b.jumlahHari, 31);
      expect(b.hariTargetTercapai, 3);
      expect(b.ringkasan.pemasukan, 80000);
      expect(b.ringkasan.tabungan, 55000);
      expect(b.perKategori.single.kategori, 'Makan');
      expect(b.perKategori.single.total, 20000);
    });

    test('bulan tidak valid dibalas 422 dan dilempar sebagai ApiException',
        () async {
      final api = LaporanApi(
        client: MockClient(
          (_) async => http.Response(jsonEncode({'detail': 'tidak valid'}), 422),
        ),
      );
      expect(
        () => api.bulanan(2026, 13),
        throwsA(isA<ApiException>().having((e) => e.kode, 'kode', 422)),
      );
    });
  });

  group('KartuBulanan', () {
    testWidgets('menampilkan judul, tiga angka, dan teks progress',
        (tester) async {
      await tester.pumpWidget(
        _bungkus(KartuBulanan(laporan: _contoh(), hariBerjalan: 20)),
      );

      expect(find.text('Bulan ini · Oktober 2026'), findsOneWidget);
      expect(find.text('Rp 80.000'), findsOneWidget); // masuk
      expect(find.text('Rp 25.000'), findsOneWidget); // keluar
      expect(find.text('Rp 55.000'), findsOneWidget); // tabungan
      expect(
        find.text('Target harian tercapai 3 dari 20 hari'),
        findsOneWidget,
      );
    });

    testWidgets('progress bar = hari tercapai / hari berjalan', (tester) async {
      await tester.pumpWidget(
        _bungkus(KartuBulanan(laporan: _contoh(tercapai: 5), hariBerjalan: 20)),
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(0.25, 0.0001));
    });

    testWidgets('tabungan negatif tampil dengan tanda minus', (tester) async {
      await tester.pumpWidget(
        _bungkus(
          KartuBulanan(
            laporan: _contoh(masuk: 10000, keluar: 15000, tercapai: 0),
            hariBerjalan: 10,
          ),
        ),
      );

      expect(find.text('-Rp 5.000'), findsOneWidget);
    });
  });
}