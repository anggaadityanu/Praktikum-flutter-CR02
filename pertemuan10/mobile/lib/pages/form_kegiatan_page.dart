import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/db_helper.dart';
import '../models/kegiatan.dart';
import '../utils/format.dart';

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
  late String _kategori;
  bool _menyimpan = false;

  bool get _modeUbah => widget.kegiatan != null;

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
    _kategori =
        (k != null && k.kategori != '-') ? k.kategori : daftarKategori.first;
  }

  @override
  void dispose() {
    _judulC.dispose();
    _nominalC.dispose();
    super.dispose();
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
    setState(() => _menyimpan = true);

    final adaUang = _tipe != Tipe.tanpa;
    final k = Kegiatan(
      id: widget.kegiatan?.id,
      judul: _judulC.text.trim(),
      tanggal: kunciTanggal(_tanggal),
      selesai: widget.kegiatan?.selesai ?? false,
      tipe: _tipe,
      nominal: adaUang ? int.parse(_nominalC.text) : 0,
      kategori: _tipe == Tipe.pengeluaran ? _kategori : '-',
    );

    if (_modeUbah) {
      await DbHelper.ubah(k);
    } else {
      await DbHelper.tambah(k);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final c in daftarKategori)
                          ChoiceChip(
                            label: Text(c),
                            selected: _kategori == c,
                            onSelected: (_) => setState(() => _kategori = c),
                          ),
                      ],
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