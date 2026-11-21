import 'kategori.dart';

enum Tipe { tanpa, pemasukan, pengeluaran }

class Kegiatan {
  final int? id;
  final String judul;
  final String tanggal; // format yyyy-MM-dd
  final bool selesai;
  final Tipe tipe;
  final int nominal;

  /// Nama kategori, untuk ditampilkan. Berisi '-' bila bukan pengeluaran.
  final String kategori;

  /// Nomor kategori di server. Dikirim saat menyimpan; null bila bukan pengeluaran.
  final int? kategoriId;

  const Kegiatan({
    this.id,
    required this.judul,
    required this.tanggal,
    this.selesai = false,
    this.tipe = Tipe.tanpa,
    this.nominal = 0,
    this.kategori = '-',
    this.kategoriId,
  });

  /// Bentuk untuk SQLite (mode lokal): yang disimpan tetap NAMA kategori.
  Map<String, Object?> toMap() => {
        'id': id,
        'judul': judul,
        'tanggal': tanggal,
        'selesai': selesai ? 1 : 0,
        'tipe': tipe.name,
        'nominal': nominal,
        'kategori': kategori,
      };

  /// Dari SQLite: hanya ada nama, jadi nomornya dicari dari kategoriBawaan.
  factory Kegiatan.fromMap(Map<String, Object?> m) => Kegiatan(
        id: m['id'] as int,
        judul: m['judul'] as String,
        tanggal: m['tanggal'] as String,
        selesai: (m['selesai'] as int) == 1,
        tipe: Tipe.values.byName(m['tipe'] as String),
        nominal: m['nominal'] as int,
        kategori: m['kategori'] as String,
        kategoriId: idKategoriBawaan(m['kategori'] as String),
      );

  /// Bentuk JSON untuk API: `id` tidak dikirim (sudah ada di URL),
  /// `selesai` berupa boolean, dan kategori dikirim sebagai NOMOR (`kategori_id`).
  Map<String, Object?> toJson() => {
        'judul': judul,
        'tanggal': tanggal,
        'selesai': selesai,
        'tipe': tipe.name,
        'nominal': nominal,
        'kategori_id': kategoriId,
      };

  /// Dari server: ada `kategori_id` (nomor) dan `kategori` (nama untuk tampilan).
  factory Kegiatan.fromJson(Map<String, dynamic> j) => Kegiatan(
        id: j['id'] as int,
        judul: j['judul'] as String,
        tanggal: j['tanggal'] as String,
        selesai: j['selesai'] as bool,
        tipe: Tipe.values.byName(j['tipe'] as String),
        nominal: j['nominal'] as int,
        kategori: j['kategori'] as String,
        kategoriId: j['kategori_id'] as int?,
      );
}

class Ringkasan {
  final int jumlahKegiatan;
  final int selesai;
  final int pemasukan;
  final int pengeluaran;

  const Ringkasan({
    required this.jumlahKegiatan,
    required this.selesai,
    required this.pemasukan,
    required this.pengeluaran,
  });

  /// Membaca ringkasan dari JSON laporan server (nama field snake_case).
  factory Ringkasan.fromJson(Map<String, dynamic> j) => Ringkasan(
        jumlahKegiatan: j['jumlah_kegiatan'] as int,
        selesai: j['selesai'] as int,
        pemasukan: j['pemasukan'] as int,
        pengeluaran: j['pengeluaran'] as int,
      );

  int get tabungan => pemasukan - pengeluaran;
}

class TotalKategori {
  final String kategori;
  final int total;

  const TotalKategori({required this.kategori, required this.total});
}

extension TipeNama on Tipe {
  String get nama => switch (this) {
        Tipe.tanpa => 'Tanpa uang',
        Tipe.pemasukan => 'Pemasukan',
        Tipe.pengeluaran => 'Pengeluaran',
      };
}

class RingkasanHari {
  final DateTime tanggal;
  final Ringkasan ringkasan;

  const RingkasanHari({required this.tanggal, required this.ringkasan});
}