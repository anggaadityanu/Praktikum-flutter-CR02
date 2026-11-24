/// Satu kategori pengeluaran, seperti yang dikirim server (GET /kategori).
class Kategori {
  final int id;
  final String nama;

  const Kategori({required this.id, required this.nama});

  factory Kategori.fromJson(Map<String, dynamic> j) =>
      Kategori(id: j['id'] as int, nama: j['nama'] as String);
}

/// Kategori untuk mode lokal (SQLite). Id 1 sampai 5 sengaja sama dengan
/// data awal di server (migrasi 0003), jadi keduanya konsisten.
const kategoriBawaan = [
  Kategori(id: 1, nama: 'Makan'),
  Kategori(id: 2, nama: 'Transport'),
  Kategori(id: 3, nama: 'Belajar'),
  Kategori(id: 4, nama: 'Hiburan'),
  Kategori(id: 5, nama: 'Lainnya'),
];

/// Mencari id kategori bawaan dari namanya. Hasilnya null bila namanya tidak ada.
int? idKategoriBawaan(String nama) {
  for (final k in kategoriBawaan) {
    if (k.nama == nama) return k.id;
  }
  return null;
}