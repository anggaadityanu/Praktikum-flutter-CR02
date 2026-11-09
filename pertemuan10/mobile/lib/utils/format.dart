const _namaHari = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];
const _namaBulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

/// DateTime -> "2026-10-24" (format penyimpanan di database)
String kunciTanggal(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "2026-10-24" -> DateTime
DateTime dariKunci(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// 25000 -> "Rp 25.000", -5000 -> "-Rp 5.000"
String rupiah(int nilai) {
  final teks = nilai.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < teks.length; i++) {
    if (i > 0 && (teks.length - i) % 3 == 0) buf.write('.');
    buf.write(teks[i]);
  }
  return '${nilai < 0 ? '-' : ''}Rp $buf';
}

/// "Sabtu, 24 Oktober 2026"
String tanggalIndo(DateTime d) =>
    '${_namaHari[d.weekday - 1]}, ${d.day} ${_namaBulan[d.month - 1]} ${d.year}';

/// 2026-10-24 -> "Sab"
String hariSingkat(DateTime d) => _namaHari[d.weekday - 1].substring(0, 3);

/// 2026-10-24 -> "Sab, 24 Okt"
String tanggalPendek(DateTime d) =>
    '${hariSingkat(d)}, ${d.day} ${_namaBulan[d.month - 1].substring(0, 3)}';