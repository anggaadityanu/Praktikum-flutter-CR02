String rupiah(int n) =>
    'Rp${n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

String tanggalHariIni() {
  const b = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  final n = DateTime.now();
  return '${n.day.toString().padLeft(2, '0')} ${b[n.month - 1]} ${n.year}';
}