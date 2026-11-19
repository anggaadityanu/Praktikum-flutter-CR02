import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tabungku/data/kegiatan_repository.dart';
import 'package:tabungku/models/kegiatan.dart';
import 'package:tabungku/models/laporan.dart';
import 'package:tabungku/models/pengguna.dart';
import 'package:tabungku/pages/shell_page.dart';
import 'package:tabungku/services/api_client.dart';
import 'package:tabungku/services/cache_client.dart';
import 'package:tabungku/services/cache_store.dart';
import 'package:tabungku/services/kegiatan_api.dart';
import 'package:tabungku/services/token_storage.dart';
import 'package:tabungku/state/sesi.dart';

const _akunA = Pengguna(
  id: 1,
  nama: 'Budi',
  email: 'budi@contoh.id',
  targetHarian: 20000,
);
const _akunB = Pengguna(
  id: 2,
  nama: 'Ani',
  email: 'ani@contoh.id',
  targetHarian: 20000,
);

const _kunciA = '1|http://contoh.id/kegiatan';

Uri _uri(String path) => Uri.parse('http://contoh.id$path');

/// Server palsu yang dapat dimatikan, diperlambat, atau diganti jawabannya.
class _Server {
  bool mati = false;
  Duration? tunda;
  int kode = 200;
  String isi = '[{"id":1}]';
  final permintaan = <String>[];

  late final http.Client klien = MockClient((req) async {
    permintaan.add('${req.method} ${req.url.path}');
    if (mati) throw http.ClientException('tidak ada koneksi');
    if (tunda != null) await Future<void>.delayed(tunda!);
    return http.Response(
      isi,
      kode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

/// Repository kosong untuk menguji ShellPage tanpa server.
class _RepoKosong implements KegiatanRepository {
  @override
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''}) async => [];

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
      [];

  @override
  Future<void> tambah(Kegiatan k) async {}

  @override
  Future<void> ubah(Kegiatan k) async {}

  @override
  Future<void> setSelesai(Kegiatan k, bool selesai) async {}

  @override
  Future<void> hapus(int id) async {}
}

void main() {
  late MemoryCacheStore store;
  late _Server server;

  // Setiap tes mulai dalam keadaan login sebagai Budi, cache kosong, online.
  setUp(() async {
    penyimpanToken = MemoryTokenStorage();
    store = MemoryCacheStore();
    penyimpanCache = store;
    server = _Server();
    ApiClient.resetUntukTes();
    statusOffline.value = null;
    accessToken = null;
    refreshTokenSesi = null;
    pengguna.value = null;
    await simpanSesi('token-abc', 'refresh-abc', _akunA);
  });

  CacheClient klien({Duration? batas}) =>
      CacheClient(inner: server.klien, store: store, batasWaktu: batas);

  group('CacheClient', () {
    test('online: GET 200 disimpan ke cache dan banner tidak tampil', () async {
      final res = await klien().get(_uri('/kegiatan'));

      expect(res.statusCode, 200);
      expect(res.body, '[{"id":1}]');
      final entri = await store.baca(_kunciA);
      expect(entri, isNotNull);
      expect(entri!.isi, '[{"id":1}]');
      expect(statusOffline.value, isNull);
    });

    test('offline: isi cache dikembalikan sebagai 200 dan statusOffline terisi',
        () async {
      final c = klien();
      await c.get(_uri('/kegiatan')); // online: mengisi cache
      final waktuTersimpan = (await store.baca(_kunciA))!.waktu;

      server.mati = true;
      final res = await c.get(_uri('/kegiatan'));

      expect(res.statusCode, 200);
      expect(res.body, '[{"id":1}]');
      // Banner memakai waktu data yang tersimpan, bukan waktu sekarang.
      expect(statusOffline.value, waktuTersimpan);
    });

    test('offline tanpa cache: galat dilempar dan banner tidak tampil',
        () async {
      server.mati = true;

      await expectLater(
        klien().get(_uri('/kegiatan')),
        throwsA(isA<http.ClientException>()),
      );

      expect(statusOffline.value, isNull);
    });

    test('server terlalu lambat (timeout): isi cache dipakai', () async {
      final c = klien(batas: const Duration(milliseconds: 50));
      await c.get(_uri('/kegiatan')); // online dan cepat

      server.tunda = const Duration(milliseconds: 400);
      final res = await c.get(_uri('/kegiatan'));

      expect(res.statusCode, 200);
      expect(res.body, '[{"id":1}]');
      expect(statusOffline.value, isNotNull);
    });

    test('pulih online: banner hilang dan cache diperbarui', () async {
      final c = klien();
      await c.get(_uri('/kegiatan'));
      server.mati = true;
      await c.get(_uri('/kegiatan'));
      expect(statusOffline.value, isNotNull);

      server
        ..mati = false
        ..isi = '[{"id":1},{"id":2}]';
      await c.get(_uri('/kegiatan'));

      expect(statusOffline.value, isNull);
      expect((await store.baca(_kunciA))!.isi, '[{"id":1},{"id":2}]');
    });

    test('POST tidak di-cache dan tidak dilayani dari cache', () async {
      final c = klien();
      server.kode = 201;
      server.isi = '{"id":9}';

      final res = await c.post(_uri('/kegiatan'), body: '{}');
      expect(res.statusCode, 201);
      expect(store.jumlah, 0);

      // Walau ada cache untuk GET, POST saat offline tetap gagal.
      server
        ..kode = 200
        ..isi = '[{"id":1}]';
      await c.get(_uri('/kegiatan'));
      expect(store.jumlah, 1);
      server.mati = true;
      await expectLater(
        c.post(_uri('/kegiatan'), body: '{}'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('jawaban bukan 200 (misalnya 500) tidak disimpan', () async {
      server
        ..kode = 500
        ..isi = '{"detail":"galat"}';

      final res = await klien().get(_uri('/kegiatan'));

      expect(res.statusCode, 500);
      expect(store.jumlah, 0);
      expect(statusOffline.value, isNull);
    });

    test('akun lain tidak memakai cache akun sebelumnya', () async {
      final c = klien();
      await c.get(_uri('/kegiatan')); // cache milik Budi (id 1)
      expect(store.jumlah, 1);

      pengguna.value = _akunB; // ganti akun di HP yang sama
      server.mati = true;

      await expectLater(
        c.get(_uri('/kegiatan')),
        throwsA(isA<http.ClientException>()),
      );
      expect(statusOffline.value, isNull);
    });

    test('belum login: tidak ada yang disimpan dan tidak memakai cache',
        () async {
      pengguna.value = null;
      final c = klien();

      await c.get(_uri('/kegiatan'));
      expect(store.jumlah, 0);

      server.mati = true;
      await expectLater(
        c.get(_uri('/kegiatan')),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('keluar menghapus cache dan banner', () async {
      final c = klien();
      await c.get(_uri('/kegiatan'));
      server.mati = true;
      await c.get(_uri('/kegiatan'));
      expect(store.jumlah, 1);
      expect(statusOffline.value, isNotNull);

      await hapusSesi();

      expect(store.jumlah, 0);
      expect(statusOffline.value, isNull);
      expect(pengguna.value, isNull);
    });

    test('galat bukan jaringan: tidak memakai cache (bug tidak disembunyikan)',
        () async {
      final c = CacheClient(
        inner: MockClient((req) async => throw ArgumentError('bug program')),
        store: store,
      );
      await store.simpan(_kunciA, '[{"id":1}]', DateTime.now());

      await expectLater(
        c.get(_uri('/kegiatan')),
        throwsA(isA<ArgumentError>()),
      );
      expect(statusOffline.value, isNull);
    });

    test('URL berbeda memakai kunci berbeda', () async {
      final c = klien();
      await c.get(_uri('/kegiatan?tanggal=2026-10-06'));

      server.mati = true;
      // Tanggal lain belum pernah dimuat, jadi tidak ada cache-nya.
      await expectLater(
        c.get(_uri('/kegiatan?tanggal=2026-10-07')),
        throwsA(isA<http.ClientException>()),
      );
      // Tanggal yang sama dilayani dari cache.
      final res = await c.get(_uri('/kegiatan?tanggal=2026-10-06'));
      expect(res.statusCode, 200);
    });
  });

  group('Dipakai lewat KegiatanApi', () {
    test('daftar tetap tampil saat offline (dari cache)', () async {
      server.isi =
          '[{"id":1,"judul":"Makan siang","tanggal":"2026-10-06","selesai":false,'
          '"tipe":"pengeluaran","nominal":15000,"kategori":"Makan",'
          '"created_at":"2026-10-06T08:00:00","updated_at":"2026-10-06T08:00:00"}]';
      final api = KegiatanApi(client: klien());

      final online = await api.daftar(tanggal: '2026-10-06');
      expect(online.single.judul, 'Makan siang');
      expect(statusOffline.value, isNull);

      server.mati = true;
      final offline = await api.daftar(tanggal: '2026-10-06');

      expect(offline.single.judul, 'Makan siang');
      expect(offline.single.nominal, 15000);
      expect(statusOffline.value, isNotNull);
    });
  });

  group('Banner offline di ShellPage', () {
    testWidgets('muncul saat statusOffline terisi dan hilang saat pulih',
        (tester) async {
      repo = _RepoKosong();
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: ShellPage()));
      await tester.pumpAndSettle();
      addTearDown(() => tester.pumpWidget(const SizedBox()));
      expect(find.textContaining('Offline:'), findsNothing);

      statusOffline.value = DateTime(2026, 10, 6, 14, 5);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Offline: menampilkan data tersimpan (terakhir diperbarui pukul 14:05)',
        ),
        findsOneWidget,
      );

      statusOffline.value = null;
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline:'), findsNothing);
    });
  });
}
