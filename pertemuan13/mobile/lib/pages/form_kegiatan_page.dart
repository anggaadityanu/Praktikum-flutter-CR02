import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/api_config.dart'; // BARU: modeData
import '../data/kegiatan_repository.dart';
import '../models/kategori.dart';
import '../models/kegiatan.dart';
import '../utils/format.dart';
import '../widgets/bukti_struk.dart'; // BARU
import '../widgets/galat_view.dart';

IconData _ikonTipe(Tipe t) => switch (t) {
      Tipe.tanpa => Icons.horizontal_rule,
      Tipe.pemasukan => Icons.south_west,
      Tipe.pengeluaran => Icons.north_east,
    };

class FormKegiatanPage extends StatefulWidget {
  final Kegiatan? kegiatan; // null = tambah, isi = ubah
  const FormKegiatanPage({super.key, this.kegiatan});

  @override
  State<FormKegiatanPage> createState() => _FormKegiatanPageState();
}

class _FormKegiatanPageState extends State<FormKegiatanPage> {
  final _kunciForm = GlobalKey<FormState>();
  late final TextEditingController _judulC;
  late final TextEditingController _nominalC;
  late DateTime _tanggal;
  late Tipe _tipe;

  /// Kategori yang dipilih. Null = belum memilih.
  Kategori? _kategori;

  /// Pesan galat bila pengeluaran disimpan tanpa kategori.
  String? _galatKategori;

  /// Daftar kategori dari server (diambil saat form dibuka).
  late Future<List<Kategori>> _daftarKategori;

  // BARU: foto yang baru dipilih (belum diunggah) dan penanda
  // "foto lama di server ingin dihapus".
  FotoBaru? _fotoBaru;
  bool _hapusFotoLama = false;

  bool _menyimpan = false;

  bool get _modeUbah => widget.kegiatan != null;

  // BARU: foto struk hanya ada saat memakai server (bukan mode lokal SQLite).
  bool get _bisaFoto => modeData != 'lokal';

  @override
  void initState() {
    super.initState();
    final k = widget.kegiatan;
    _judulC = TextEditingController(text: k?.judul ?? '');
    _nominalC = TextEditingController(
      text: (k != null && k.nominal > 0) ? k.nominal.toString() : '',
    );
    _tanggal = k != null ? dariKunci(k.tanggal) : DateTime.now();
    _tipe = k?.tipe ?? Tipe.tanpa;
    // Mode ubah: kategori lama langsung terpilih.
    if (k != null && k.kategoriId != null) {
      _kategori = Kategori(id: k.kategoriId!, nama: k.kategori);
    }
    _daftarKategori = repo.daftarKategori();
  }

  @override
  void dispose() {
    _judulC.dispose();
    _nominalC.dispose();
    super.dispose();
  }

  /// Memuat ulang daftar kategori (tombol "Coba lagi" bila gagal).
  void _muatKategori() {
    setState(() {
      _daftarKategori = repo.daftarKategori();
    });
  }

  Future<void> _pilihTanggal() async {
    final dipilih = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (dipilih != null) setState(() => _tanggal = dipilih);
  }

  Future<void> _simpan() async {
    if (!_kunciForm.currentState!.validate()) return;

    // ChoiceChip bukan kolom form, jadi kategori dicek manual di sini.
    final pengeluaran = _tipe == Tipe.pengeluaran;
    if (pengeluaran && _kategori == null) {
      setState(() => _galatKategori = 'Pilih kategori pengeluaran');
      return;
    }

    setState(() => _menyimpan = true);

    final adaUang = _tipe != Tipe.tanpa;
    final k = Kegiatan(
      id: widget.kegiatan?.id,
      judul: _judulC.text.trim(),
      tanggal: kunciTanggal(_tanggal),
      selesai: widget.kegiatan?.selesai ?? false,
      tipe: _tipe,
      nominal: adaUang ? int.parse(_nominalC.text) : 0,
      kategori: pengeluaran ? _kategori!.nama : '-',
      kategoriId: pengeluaran ? _kategori!.id : null,
    );

    // Disimpan sekarang karena setelah halaman ditutup, context tidak aman dipakai.
    final pesan = ScaffoldMessenger.of(context);

    // LANGKAH 1: simpan kegiatan. Hasilnya dipakai untuk mengetahui id-nya.
    final Kegiatan tersimpan;
    try {
      tersimpan = _modeUbah ? await repo.ubah(k) : await repo.tambah(k);
    } catch (e) {
      // Form tetap terbuka agar isian tidak hilang.
      if (mounted) {
        tampilkanGalat(context, e);
        setState(() => _menyimpan = false);
      }
      return;
    }

    // LANGKAH 2: foto diunggah SETELAH kegiatan tersimpan, karena unggahan
    // butuh id kegiatan.
    var fotoGagal = false;
    final id = tersimpan.id;
    if (id != null && _bisaFoto) {
      try {
        final foto = _fotoBaru;
        if (adaUang && foto != null) {
          await repo.unggahBukti(id, foto.isi, foto.nama);
        } else if ((_hapusFotoLama || !adaUang) &&
            widget.kegiatan?.bukti != null) {
          await repo.hapusBukti(id);
        }
      } catch (_) {
        fotoGagal = true;
      }
    }

    if (!mounted) return;
    Navigator.pop(context, true);
    // Kegiatan sudah tersimpan; cukup beri tahu bahwa fotonya gagal.
    if (fotoGagal) {
      pesan.showSnackBar(
        const SnackBar(
          content: Text('Kegiatan tersimpan, tetapi foto gagal diunggah'),
        ),
      );
    }
  }

  /// Chip kategori dari server, dengan keadaan memuat dan gagal.
  Widget _pilihanKategori() {
    return FutureBuilder<List<Kategori>>(
      future: _daftarKategori,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return TextButton.icon(
            onPressed: _muatKategori,
            icon: const Icon(Icons.refresh),
            label: const Text('Gagal memuat kategori. Coba lagi'),
          );
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final daftar = [...snapshot.data!];
        // Kategori lama yang sudah dinonaktifkan admin tetap ditampilkan,
        // supaya kegiatan lama masih bisa disimpan ulang.
        final dipilih = _kategori;
        if (dipilih != null && !daftar.any((c) => c.id == dipilih.id)) {
          daftar.add(dipilih);
        }

        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in daftar)
              ChoiceChip(
                label: Text(c.nama),
                selected: _kategori?.id == c.id,
                onSelected: (_) => setState(() {
                  _kategori = c;
                  _galatKategori = null;
                }),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_modeUbah ? 'Ubah Kegiatan' : 'Kegiatan Baru'),
      ),
      body: Form(
        key: _kunciForm,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _judulC,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Nama kegiatan',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama kegiatan wajib diisi'
                  : null,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(tanggalIndo(_tanggal)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Jenis keuangan', style: tema.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final t in Tipe.values)
                  ChoiceChip(
                    avatar: Icon(_ikonTipe(t), size: 18),
                    label: Text(t.nama),
                    showCheckmark: false,
                    selected: _tipe == t,
                    onSelected: (_) => setState(() => _tipe = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tipe != Tipe.tanpa) ...[
                    TextFormField(
                      controller: _nominalC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nominal wajib diisi';
                        }
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) {
                          return 'Nominal harus lebih dari 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_tipe == Tipe.pengeluaran) ...[
                    Text('Kategori', style: tema.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _pilihanKategori(),
                    if (_galatKategori != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _galatKategori!,
                          style: TextStyle(color: tema.colorScheme.error),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  // BARU: bagian foto struk, muncul bila ada uang dan memakai server.
                  if (_tipe != Tipe.tanpa && _bisaFoto) ...[
                    Text('Bukti struk (opsional)',
                        style: tema.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    BuktiStruk(
                      urlLama:
                          _hapusFotoLama ? null : widget.kegiatan?.buktiUrl,
                      fotoBaru: _fotoBaru,
                      onPilih: (f) => setState(() {
                        _fotoBaru = f;
                        _hapusFotoLama = false;
                      }),
                      onHapus: () => setState(() {
                        _fotoBaru = null;
                        _hapusFotoLama = widget.kegiatan?.bukti != null;
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _menyimpan ? null : _simpan,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}