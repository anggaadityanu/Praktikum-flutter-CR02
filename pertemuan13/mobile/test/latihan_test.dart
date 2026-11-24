import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabungku/data/kegiatan_repository.dart';
import 'package:tabungku/models/kategori.dart';
import 'package:tabungku/models/kegiatan.dart';
import 'package:tabungku/models/laporan.dart';
import 'package:tabungku/pages/beranda_page.dart';
import 'package:tabungku/utils/format.dart';
import 'package:tabungku/utils/ukur_waktu.dart';
import 'package:tabungku/widgets/kegiatan_tile.dart';

/// Repository palsu yang dapat "menahan" jawaban agar keadaan di tengah
/// proses (sedang memuat, menunggu server) dapat diperiksa.
class RepoTunda implements KegiatanRepository {
  List<Kegiatan> daftar = [];
  Completer<void>? tahanBaca; // bila terisi, pada() menunggu
  Completer<void>? tahanTulis; // bila terisi, setSelesai() menunggu
  String? qTerakhir;

  @override
  Future<List<Kegiatan>> pada(String tanggal, {String q = ''}) async {
    qTerakhir = q;
    final t = tahanBaca;
    if (t != null) await t.future;
    final kata = q.trim().toLowerCase();
    return daftar
        .where((k) => kata.isEmpty || k.judul.toLowerCase().contains(kata))
        .toList();
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
  Future<LaporanBulanan> laporanBulanan(int tahun, int bulan) async =>
      LaporanBulanan(
        tahun: tahun,
        bulan: bulan,
        jumlahHari: 30,
        hariTargetTercapai: 0,
        ringkasan: const Ringkasan(
          jumlahKegiatan: 0,
          selesai: 0,
          pemasukan: 0,
          pengeluaran: 0,
        ),
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

  @override
  Future<Kegiatan> tambah(Kegiatan k) async => k;

  @override
  Future<Kegiatan> ubah(Kegiatan k) async => k;

  @override
  Future<void> setSelesai(Kegiatan k, bool selesai) async {
    final t = tahanTulis;
    if (t != null) await t.future; // bila di-completeError, dilempar ke pemanggil
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
  Future<void> hapus(int id) async {}

  @override
  Future<void> unggahBukti(int id, List<int> isi, String namaBerkas) async {}

  @override
  Future<void> hapusBukti(int id) async {}
}

/// Repository yang tiap request laporannya butuh 80 ms (untuk Latihan 3).
class RepoLambat extends RepoTunda {
  @override
  Future<LaporanHarian> laporanHarian(String tanggal) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return super.laporanHarian(tanggal);
  }

  @override
  Future<List<RingkasanHari>> rentang(DateTime mulai, DateTime sampai) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return [];
  }
}

Kegiatan _makanSiang() => Kegiatan(
      id: 1,
      judul: 'Makan siang',
      tanggal: kunciTanggal(DateTime.now()),
      tipe: Tipe.pengeluaran,
      nominal: 15000,
      kategori: 'Makan',
    );

Widget _app() => const MaterialApp(home: Scaffold(body: BerandaPage()));

void _ukuranLayar(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _buka(WidgetTester tester, RepoTunda fake) async {
  repo = fake;
  _ukuranLayar(tester);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  addTearDown(() => tester.pumpWidget(const SizedBox()));
}

Finder _centang() => find.descendant(
      of: find.byType(KegiatanTile),
      matching: find.byType(AnimatedContainer),
    );

void main() {
  group('Latihan 1: progres tipis saat memuat ulang', () {
    testWidgets('lingkaran saat pertama kali, garis tipis saat memuat ulang',
        (tester) async {
      final fake = RepoTunda()
        ..daftar = [_makanSiang()]
        ..tahanBaca = Completer<void>();
      repo = fake;
      _ukuranLayar(tester);
      addTearDown(() => tester.pumpWidget(const SizedBox()));

      await tester.pumpWidget(_app());
      await tester.pump();

      // Pertama kali: lingkaran di tengah layar, belum ada garis tipis.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      fake.tahanBaca!.complete();
      fake.tahanBaca = null;
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Makan siang'), findsOneWidget);

      // Memuat ulang: data lama tetap terlihat dan muncul garis tipis.
      fake.tahanBaca = Completer<void>();
      versiData.value++;
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Makan siang'), findsOneWidget);

      fake.tahanBaca!.complete();
      fake.tahanBaca = null;
      await tester.pumpAndSettle();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('Latihan 2: optimistic update', () {
    testWidgets('centang tampil sebelum server menjawab', (tester) async {
      final fake = RepoTunda()..daftar = [_makanSiang()];
      await _buka(tester, fake);
      expect(find.byIcon(Icons.check), findsNothing);

      fake.tahanTulis = Completer<void>();
      await tester.tap(_centang());
      await tester.pump();

      // Server belum menjawab, tetapi tampilan sudah berubah.
      expect(find.byIcon(Icons.check), findsOneWidget);

      fake.tahanTulis!.complete();
      fake.tahanTulis = null;
      await tester.pumpAndSettle();

      // Setelah data dari server tiba, tetap tercentang.
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('dikembalikan dan SnackBar tampil bila server menolak',
        (tester) async {
      final fake = RepoTunda()..daftar = [_makanSiang()];
      await _buka(tester, fake);

      fake.tahanTulis = Completer<void>();
      await tester.tap(_centang());
      await tester.pump();
      expect(find.byIcon(Icons.check), findsOneWidget);

      fake.tahanTulis!.completeError(Exception('jaringan putus'));
      fake.tahanTulis = null;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.check), findsNothing); // dikembalikan
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('Latihan 3: ukur waktu muat', () {
    test('Future.wait lebih cepat daripada dua request berurutan', () async {
      final hasil = await ukurLaporan(RepoLambat(), ulang: 2);

      // Berurutan kira-kira 80 + 80 ms; paralel kira-kira 80 ms.
      expect(hasil.berurutanMs, greaterThanOrEqualTo(150));
      expect(hasil.paralelMs, lessThan(hasil.berurutanMs));
      expect(hasil.ulang, 2);
    });
  });

  group('Latihan 4: pencarian judul di Hari Ini', () {
    testWidgets('q dikirim ke repository setelah jeda mengetik', (tester) async {
      final fake = RepoTunda()..daftar = [_makanSiang()];
      await _buka(tester, fake);
      expect(fake.qTerakhir, '');

      await tester.enterText(find.byType(TextField), 'makan');
      await tester.pump(const Duration(milliseconds: 100));
      expect(fake.qTerakhir, ''); // masih menunggu pengguna berhenti mengetik

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(fake.qTerakhir, 'makan');
      expect(find.text('Makan siang'), findsOneWidget);
    });

    testWidgets('hasil kosong menampilkan pesan khusus pencarian',
        (tester) async {
      final fake = RepoTunda()..daftar = [_makanSiang()];
      await _buka(tester, fake);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Makan siang'), findsNothing);
      expect(find.textContaining('Tidak ada kegiatan yang cocok'), findsOneWidget);
      expect(find.textContaining('Belum ada kegiatan'), findsNothing);
    });
  });
}
