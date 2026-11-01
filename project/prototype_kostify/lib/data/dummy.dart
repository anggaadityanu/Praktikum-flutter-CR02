// ===== USER =====
const namaUser = 'Angga Nugraha';
const emailUser = 'angga.nugraha@email.com';

// ===== KOS =====
class Kamar {
  final String nama, alamat, kota, deskripsi, foto;
  final int harga, ulasan, sisaKamar;
  final double rating;
  final List<String> fasilitas;
  bool favorit;
  Kamar(this.nama, this.alamat, this.kota, this.deskripsi, this.harga,
      this.rating, this.ulasan, this.sisaKamar, this.fasilitas,
      {this.favorit = false, this.foto = ''});
}

const _deskripsi =
    'Kamar nyaman, bersih, dan strategis. Dekat kampus, pusat kuliner, serta akses transportasi.';

final daftarKamar = <Kamar>[
  Kamar('Kos Putri Melati', 'Jl. Kaliurang No. 45', 'Yogyakarta', _deskripsi,
      1500000, 4.8, 24, 3, ['Wi-Fi', 'AC', 'Kasur', 'Kamar mandi'],
      favorit: true,
      foto: 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=600&q=70'),
  Kamar('Kos Putra Mawar', 'Jl. Gejayan No. 12', 'Yogyakarta', _deskripsi,
      1200000, 4.6, 18, 3, ['Wi-Fi', 'AC', 'Kasur', 'Kamar mandi'],
      foto: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=600&q=70'),
  Kamar('Kostan Anggrek', 'Jl. Seturan No. 8', 'Yogyakarta', _deskripsi,
      1000000, 4.5, 12, 3, ['Wi-Fi', 'AC', 'Kasur', 'Kamar mandi'],
      foto: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=600&q=70'),
  Kamar('Kos Harmoni', 'Jl. Affandi No. 3', 'Yogyakarta', _deskripsi, 1200000,
      4.4, 9, 2, ['Wi-Fi', 'Kasur', 'Kamar mandi'],
      foto: 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=600&q=70'),
];

// Kamar yang sedang dihuni user
final Kamar kamarAnda = daftarKamar.first;
const nomorKamarAnda = '05';

// ===== TAGIHAN =====
class Tagihan {
  final String periode, jatuhTempo;
  final int nominal;
  String dibayar;
  bool lunas;
  Tagihan(this.periode, this.jatuhTempo, this.nominal,
      {this.lunas = false, this.dibayar = '-'});
}

final daftarTagihan = <Tagihan>[
  Tagihan('Juli 2023', '05 Juli 2023', 1500000),
  Tagihan('Juni 2023', '05 Juni 2023', 1500000,
      lunas: true, dibayar: '01 Juni 2023'),
];

const tanggalPembayaranTerakhir = '28 Juli 2023';
const biayaAdmin = 10000;

// ===== KELUHAN =====
class Keluhan {
  final String kategori, judul, deskripsi, tanggal;
  String status; // Baru / Diproses / Selesai
  Keluhan(this.kategori, this.judul, this.deskripsi, this.tanggal,
      {this.status = 'Baru'});
}

// sengaja kosong supaya tampilan awal sama dengan Figma
final daftarKeluhan = <Keluhan>[];

// ===== PENGATURAN =====
bool notifAktif = true;
String bahasaApp = 'Bahasa Indonesia';
String temaApp = 'Terang';
const versiApp = '1.0.0';