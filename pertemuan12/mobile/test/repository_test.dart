import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/data/api_kegiatan_repository.dart';
import 'package:tabungku/data/kegiatan_repository.dart';
import 'package:tabungku/models/kategori.dart';
import 'package:tabungku/models/kegiatan.dart';
import 'package:tabungku/models/laporan.dart';
import 'package:tabungku/pages/beranda_page.dart';
import 'package:tabungku/services/api_exception.dart';
import 'package:tabungku/services/kegiatan_api.dart';
import 'package:tabungku/services/laporan_api.dart';
import 'package:tabungku/utils/format.dart';
import 'package:tabungku/widgets/galat_view.dart';
import 'package:tabungku/widgets/kegiatan_tile.dart';

/// Repository palsu: data, galat, dan hitungan panggilan dapat diatur test.
class FakeRepository implements KegiatanRepository {
  List<Kegiatan> daftar = [];
  Object? galat; // dilempar saat membaca data
  Object? galatTulis; // dilempar saat setSelesai
  int jumlahPanggil = 0; // berapa kali pada() dipanggil
  bool? terakhirSelesai;

  @override
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''}) async {
    jumlahPanggil++;
    if (galat != null) throw galat!;
    return daftar;
  }

  @override
  Future<Ringkasan> ringkasan(String tanggal) async => const Ringkasan(
        jumlahKegiatan: 0,
        selesai: 0,
        pemasukan: 0,
        pengeluaran: 0,
      );

  @override
  Future<LaporanHarian> laporanHarian(String tanggal) async => LaporanHarian(
        tanggal: tanggal,
        ringkasan: await ringkasan(tanggal),
        perKategori: const [],
      );

  @override
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai) async =>
      [];

  @override
  Future<List<Kegiatan>> cari({
    String kata = '',
    Tipe? tipe,
    String? kategori,
  }) async =>
      daftar;

  @override
  Future<List<Kategori>> daftarKategori() async => kategoriBawaan;

  // Operasi tulis menaikkan versiData, seperti repository sungguhan.
  @override
  Future<void> tambah(Kegiatan k) async {
    daftar = [...daftar, k];
    versiData.value++;
  }

  @override
  Future<void> ubah(Kegiatan k) async {
    daftar = [for (final e in daftar) e.id == k.id ? k : e];
    versiData.value++;
  }

  @override
  Future<void> setSelesai(Kegiatan k, bool selesai) async {
    if (galatTulis != null) throw galatTulis!;
    terakhirSelesai = selesai;
    daftar = [
      for (final e in daftar)
        e.id == k.id
            ? Kegiatan(
                id: e.id,
                judul: e.judul,
                tanggal: e.tanggal,
                selesai: selesai,
                tipe: e.tipe,
                nominal: e.nominal,
                kategori: e.kategori,
              )
            : e,
    ];
    versiData.value++;
  }

  @override
  Future<void> hapus(int id) async {
    daftar = daftar.where((e) => e.id != id).toList();
    versiData.value++;
  }
}

Widget _app() => const MaterialApp(home: Scaffold(body: BerandaPage()));

/// Memasang repository palsu, membuka halaman Hari Ini, dan membersihkannya
/// setelah tes (agar pendengar versiData ikut dilepas).
Future<void> _bukaBeranda(WidgetTester tester, FakeRepository fake) async {
  repo = fake;
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox()));
}

Kegiatan _makanSiang() => Kegiatan(
      id: 1,
      judul: 'Makan siang',
      tanggal: kunciTanggal(DateTime.now()),
      tipe: Tipe.pengeluaran,
      nominal: 15000,
      kategori: 'Makan',
    );

/// Contoh respons server untuk satu kegiatan.
Map<String, Object?> _json({int id = 1, String kategori = 'Makan'}) => {
      'id': id,
      'judul': 'Makan siang',
      'tanggal': '2026-10-06',
      'selesai': false,
      'tipe': 'pengeluaran',
      'nominal': 15000,
      'kategori': kategori,
      'created_at': '2026-10-06T08:00:00',
      'updated_at': '2026-10-06T08:00:00',
    };

Map<String, Object?> _hari(String tanggal, {int masuk = 0, int keluar = 0}) => {
      'tanggal': tanggal,
      'jumlah_kegiatan': (masuk + keluar) > 0 ? 1 : 0,
      'selesai': 0,
      'pemasukan': masuk,
      'pengeluaran': keluar,
      'tabungan': masuk - keluar,
    };

void main() {
  group('Halaman Hari Ini dengan FakeRepository', () {
    testWidgets('galat -> tombol Coba lagi -> data tampil', (tester) async {
      final fake = FakeRepository()..galat = Exception('server mati');
      await _bukaBeranda(tester, fake);

      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.textContaining('Tidak dapat terhubung'), findsOneWidget);

      fake.galat = null;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Coba lagi'), findsNothing);
      expect(find.textContaining('Belum ada kegiatan'), findsOneWidget);
    });

    testWidgets('daftar dari repository tampil di KegiatanTile', (tester) async {
      final fake = FakeRepository()..daftar = [_makanSiang()];
      await _bukaBeranda(tester, fake);

      final tile = find.byType(KegiatanTile);
      expect(tile, findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('Makan siang')),
          findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('Makan')),
          findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('-Rp 15.000')),
          findsOneWidget);
      expect(find.textContaining('Belum ada kegiatan'), findsNothing);
    });

    testWidgets('repo.hapus() memicu halaman memuat ulang', (tester) async {
      final fake = FakeRepository()..daftar = [_makanSiang()];
      await _bukaBeranda(tester, fake);
      final sebelum = fake.jumlahPanggil;
      expect(find.text('Makan siang'), findsOneWidget);

      await repo.hapus(1);
      await tester.pumpAndSettle();

      expect(fake.jumlahPanggil, greaterThan(sebelum));
      expect(find.text('Makan siang'), findsNothing);
      expect(find.textContaining('Belum ada kegiatan'), findsOneWidget);
    });

    testWidgets('mencentang memanggil setSelesai lalu tampilan ikut berubah',
        (tester) async {
      final fake = FakeRepository()..daftar = [_makanSiang()];
      await _bukaBeranda(tester, fake);
      expect(find.byIcon(Icons.check), findsNothing);
      final sebelum = fake.jumlahPanggil;

      await tester.tap(find.descendant(
        of: find.byType(KegiatanTile),
        matching: find.byType(AnimatedContainer),
      ));
      await tester.pumpAndSettle();

      expect(fake.terakhirSelesai, isTrue);
      expect(fake.jumlahPanggil, greaterThan(sebelum));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('gagal mencentang: SnackBar tampil', (tester) async {
      final fake = FakeRepository()
        ..daftar = [_makanSiang()]
        ..galatTulis = Exception('jaringan putus');
      await _bukaBeranda(tester, fake);

      await tester.tap(find.descendant(
        of: find.byType(KegiatanTile),
        matching: find.byType(AnimatedContainer),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(fake.terakhirSelesai, isNull); // tidak ada yang berhasil tersimpan
    });
  });

  group('GalatView', () {
    testWidgets('galat dari server: pesan server ditampilkan', (tester) async {
      var ditekan = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GalatView(
            galat: const ApiException('Kegiatan tidak ditemukan', kode: 404),
            onCobaLagi: () => ditekan++,
          ),
        ),
      ));

      expect(find.text('Kegiatan tidak ditemukan'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      expect(ditekan, 1);
    });

    testWidgets('galat lain: dianggap masalah koneksi', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GalatView(galat: Exception('apa saja'), onCobaLagi: () {}),
        ),
      ));

      expect(find.textContaining('Tidak dapat terhubung'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    });
  });

  group('ApiKegiatanRepository', () {
    test('tambah menaikkan versiData setelah server berhasil', () async {
      final r = ApiKegiatanRepository(
        kegiatan: KegiatanApi(
          client: MockClient((req) async => http.Response(jsonEncode(_json()), 201)),
        ),
      );
      final sebelum = versiData.value;

      await r.tambah(const Kegiatan(judul: 'Makan siang', tanggal: '2026-10-06'));

      expect(versiData.value, sebelum + 1);
    });

    test('tambah gagal (422): galat dilempar dan versiData TIDAK naik', () async {
      final r = ApiKegiatanRepository(
        kegiatan: KegiatanApi(
          client: MockClient((req) async =>
              http.Response(jsonEncode({'detail': 'ditolak'}), 422)),
        ),
      );
      final sebelum = versiData.value;

      await expectLater(
        r.tambah(const Kegiatan(judul: 'Makan siang', tanggal: '2026-10-06')),
        throwsA(isA<ApiException>().having((e) => e.kode, 'kode', 422)),
      );

      expect(versiData.value, sebelum);
    });

    test('hapus: DELETE lalu versiData naik', () async {
      late http.Request diterima;
      final r = ApiKegiatanRepository(
        kegiatan: KegiatanApi(
          client: MockClient((req) async {
            diterima = req;
            return http.Response('', 204);
          }),
        ),
      );
      final sebelum = versiData.value;

      await r.hapus(7);

      expect(diterima.method, 'DELETE');
      expect(diterima.url.path, '/kegiatan/7');
      expect(versiData.value, sebelum + 1);
    });

    test('setSelesai: PATCH memakai id kegiatan lalu versiData naik', () async {
      late http.Request diterima;
      final r = ApiKegiatanRepository(
        kegiatan: KegiatanApi(
          client: MockClient((req) async {
            diterima = req;
            return http.Response(jsonEncode({..._json(id: 5), 'selesai': true}), 200);
          }),
        ),
      );
      final sebelum = versiData.value;

      await r.setSelesai(
        const Kegiatan(id: 5, judul: 'Makan siang', tanggal: '2026-10-06'),
        true,
      );

      expect(diterima.method, 'PATCH');
      expect(diterima.url.path, '/kegiatan/5');
      expect(jsonDecode(diterima.body), {'selesai': true});
      expect(versiData.value, sebelum + 1);
    });

    test('pada: tanggal dan q diteruskan, q kosong tidak dikirim', () async {
      final query = <Map<String, String>>[];
      final r = ApiKegiatanRepository(
        kegiatan: KegiatanApi(
          client: MockClient((req) async {
            query.add(req.url.queryParameters);
            return http.Response('[]', 200);
          }),
        ),
      );

      await r.pada('2026-10-06', q: ' makan ');
      await r.pada('2026-10-06', q: '   ');

      expect(query[0], {'tanggal': '2026-10-06', 'q': 'makan'});
      expect(query[1], {'tanggal': '2026-10-06'});
    });

    test('rentang: satu request untuk seluruh rentang', () async {
      final diterima = <http.Request>[];
      final r = ApiKegiatanRepository(
        laporan: LaporanApi(
          client: MockClient((req) async {
            diterima.add(req);
            return http.Response(
              jsonEncode([
                _hari('2026-10-04'),
                _hari('2026-10-05', keluar: 30000),
                _hari('2026-10-06', masuk: 50000, keluar: 25000),
              ]),
              200,
            );
          }),
        ),
      );

      final hasil = await r.rentang(DateTime(2026, 10, 4), DateTime(2026, 10, 6));

      expect(diterima, hasLength(1));
      expect(diterima.single.url.path, '/laporan/rentang');
      expect(diterima.single.url.queryParameters,
          {'mulai': '2026-10-04', 'sampai': '2026-10-06'});
      expect(hasil, hasLength(3));
      expect(hasil.first.tanggal, DateTime(2026, 10, 4));
      expect(hasil[1].ringkasan.tabungan, -30000);
      expect(hasil.last.ringkasan.tabungan, 25000);
    });

    test('cari: kategori disaring di klien, server diminta terbaru dan limit 200',
        () async {
      late http.Request diterima;
      final r = ApiKegiatanRepository(
        kegiatan: KegiatanApi(
          client: MockClient((req) async {
            diterima = req;
            return http.Response(
              jsonEncode([
                _json(id: 1, kategori: 'Makan'),
                _json(id: 2, kategori: 'Transport'),
                _json(id: 3, kategori: 'Makan'),
              ]),
              200,
            );
          }),
        ),
      );

      final hasil =
          await r.cari(kata: 'siang', tipe: Tipe.pengeluaran, kategori: 'Makan');

      expect(diterima.url.queryParameters, {
        'q': 'siang',
        'tipe': 'pengeluaran',
        'urut': 'terbaru',
        'limit': '200',
      });
      expect(hasil.map((k) => k.id), [1, 3]);
    });

    test('ringkasan dibaca dari laporan harian', () async {
      final r = ApiKegiatanRepository(
        laporan: LaporanApi(
          client: MockClient((req) async {
            expect(req.url.path, '/laporan/harian');
            return http.Response(
              jsonEncode({
                'tanggal': '2026-10-06',
                'jumlah_kegiatan': 4,
                'selesai': 2,
                'pemasukan': 50000,
                'pengeluaran': 25000,
                'tabungan': 25000,
                'per_kategori': [
                  {'kategori': 'Makan', 'total': 15000},
                ],
              }),
              200,
            );
          }),
        ),
      );

      final ringkasan = await r.ringkasan('2026-10-06');

      expect(ringkasan.jumlahKegiatan, 4);
      expect(ringkasan.selesai, 2);
      expect(ringkasan.tabungan, 25000);
    });
  });
}
