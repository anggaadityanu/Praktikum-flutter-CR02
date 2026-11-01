import 'package:flutter/material.dart';
import '../data/dummy.dart';
import '../nav.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/foto_kos.dart';
import 'detail_kamar_screen.dart';

IconData ikonFasilitas(String f) {
  switch (f) {
    case 'Wi-Fi':
      return Icons.wifi;
    case 'AC':
      return Icons.ac_unit;
    case 'Kasur':
      return Icons.bed_outlined;
    default:
      return Icons.bathtub_outlined;
  }
}

class CariKamarScreen extends StatefulWidget {
  const CariKamarScreen({super.key});

  @override
  State<CariKamarScreen> createState() => _CariKamarScreenState();
}

class _CariKamarScreenState extends State<CariKamarScreen> {
  String _query = '';
  String _lokasi = 'Semua';
  String _harga = 'Semua';
  final Set<String> _fasilitas = {};

  static const _opsiLokasi = [
    'Semua', 'Kaliurang', 'Gejayan', 'Seturan', 'Affandi'
  ];
  static const _opsiHarga = [
    'Semua', 'Di bawah Rp1.100.000', 'Rp1.100.000 - Rp1.300.000',
    'Di atas Rp1.300.000'
  ];
  static const _opsiFasilitas = ['Wi-Fi', 'AC', 'Kasur', 'Kamar mandi'];

  List<Kamar> get _hasil => daftarKamar.where((k) {
        final q = _query.toLowerCase();
        if (q.isNotEmpty &&
            !('${k.nama} ${k.alamat} ${k.kota}'.toLowerCase().contains(q))) {
          return false;
        }
        if (_lokasi != 'Semua' && !k.alamat.contains(_lokasi)) return false;
        if (!_fasilitas.every(k.fasilitas.contains)) return false;
        switch (_harga) {
          case 'Di bawah Rp1.100.000':
            return k.harga < 1100000;
          case 'Rp1.100.000 - Rp1.300.000':
            return k.harga >= 1100000 && k.harga <= 1300000;
          case 'Di atas Rp1.300.000':
            return k.harga > 1300000;
        }
        return true;
      }).toList();

  Future<String?> _pilihSatu(String judul, List<String> opsi, String aktif) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(judul,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            for (final o in opsi)
              ListTile(
                title: Text(o),
                trailing: o == aktif
                    ? const Icon(Icons.check, color: K.primary)
                    : null,
                onTap: () => Navigator.pop(context, o),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pilihFasilitas() async {
    final temp = {..._fasilitas};
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fasilitas',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                for (final f in _opsiFasilitas)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: K.primary,
                    title: Text(f),
                    value: temp.contains(f),
                    onChanged: (v) => setSheet(
                        () => v == true ? temp.add(f) : temp.remove(f)),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Terapkan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok == true) setState(() => _fasilitas..clear()..addAll(temp));
  }

  void _reset() => setState(() {
        _lokasi = 'Semua';
        _harga = 'Semua';
        _fasilitas.clear();
      });

  @override
  Widget build(BuildContext context) {
    final data = _hasil;
    final adaFilter =
        _lokasi != 'Semua' || _harga != 'Semua' || _fasilitas.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => tabNotifier.value = tabBeranda,
        ),
        title: const Text('Cari Kamar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: adaFilter ? _reset : null,
            tooltip: 'Reset filter',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Cari kos, lokasi, atau nama kos',
                suffixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterButton(
                  _lokasi == 'Semua' ? 'Lokasi' : _lokasi,
                  aktif: _lokasi != 'Semua',
                  onTap: () async {
                    final v = await _pilihSatu('Lokasi', _opsiLokasi, _lokasi);
                    if (v != null) setState(() => _lokasi = v);
                  },
                ),
                _FilterButton(
                  _fasilitas.isEmpty
                      ? 'Fasilitas'
                      : 'Fasilitas (${_fasilitas.length})',
                  aktif: _fasilitas.isNotEmpty,
                  onTap: _pilihFasilitas,
                ),
                _FilterButton(
                  _harga == 'Semua' ? 'Harga' : _harga,
                  aktif: _harga != 'Semua',
                  onTap: () async {
                    final v = await _pilihSatu('Harga', _opsiHarga, _harga);
                    if (v != null) setState(() => _harga = v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: data.isEmpty
                ? const Center(
                    child: Text('Kos tidak ditemukan',
                        style: TextStyle(color: Colors.black45)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _KosItem(
                      data[i],
                      onFav: () =>
                          setState(() => data[i].favorit = !data[i].favorit),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailKamarScreen(data[i])),
                        );
                        setState(() {});
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool aktif;
  final VoidCallback onTap;
  const _FilterButton(this.label, {required this.aktif, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: aktif ? K.mint : Colors.white,
            foregroundColor: aktif ? K.primaryDark : Colors.black87,
            side: BorderSide(color: aktif ? K.primary : K.border),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      );
}

class _KosItem extends StatelessWidget {
  final Kamar k;
  final VoidCallback onFav, onTap;
  const _KosItem(this.k, {required this.onFav, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FotoKos(width: 84, height: 84, asset: k.foto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(k.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        GestureDetector(
                          onTap: onFav,
                          child: Icon(
                            k.favorit ? Icons.favorite : Icons.favorite_border,
                            color: K.primary,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    Text(k.alamat,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 14, color: K.primary),
                        const SizedBox(width: 4),
                        Text('Tersedia ${k.sisaKamar} kamar',
                            style: const TextStyle(
                                fontSize: 11, color: K.primary)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${rupiah(k.harga)}/bln',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final f in k.fasilitas.take(3))
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(ikonFasilitas(f),
                                size: 15, color: Colors.black45),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}