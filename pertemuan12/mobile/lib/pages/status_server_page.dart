import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/health_service.dart';

String _pesanGalat(Object e) {
  if (e is TimeoutException) {
    return 'Tidak ada balasan dalam ${batasWaktu.inSeconds} detik.';
  }
  if (e is SocketException || e is http.ClientException) {
    return 'Tidak dapat terhubung. Pastikan Docker berjalan dan alamat API benar.';
  }
  return e.toString().replaceFirst('Exception: ', '');
}

class StatusServerPage extends StatefulWidget {
  const StatusServerPage({super.key});

  @override
  State<StatusServerPage> createState() => _StatusServerPageState();
}

class _StatusServerPageState extends State<StatusServerPage> {
  late Future<StatusServer> _future;

  @override
  void initState() {
    super.initState();
    _future = cekServer();
  }

  void _periksaLagi() {
    setState(() {
      _future = cekServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final hijau = Colors.green.shade600;
    final oranye = Colors.orange.shade800;

    return Scaffold(
      appBar: AppBar(title: const Text('Status Server')),
      body: FutureBuilder<StatusServer>(
        future: _future,
        builder: (context, snapshot) {
          final memuat = snapshot.connectionState != ConnectionState.done;
          final data = (!memuat && snapshot.hasData) ? snapshot.data : null;
          final galat = (!memuat && snapshot.hasError) ? snapshot.error : null;

          // ---- Kondisi API ----
          final String apiLabel;
          final String apiRingkasan;
          final Color apiWarna;
          if (memuat) {
            apiLabel = 'Memeriksa';
            apiRingkasan = 'Menghubungi server...';
            apiWarna = skema.outline;
          } else if (data != null) {
            apiLabel = 'Hidup';
            apiRingkasan =
                'Membalas dalam ${data.latensi.inMilliseconds} ms\nWaktu server ${data.waktuServer.replaceFirst('T', ' ')}';
            apiWarna = hijau;
          } else {
            apiLabel = 'Mati';
            apiRingkasan =
                galat != null ? _pesanGalat(galat) : 'Tidak ada balasan.';
            apiWarna = skema.error;
          }

          // ---- Kondisi database ----
          final String dbLabel;
          final String dbRingkasan;
          final Color dbWarna;
          if (memuat) {
            dbLabel = 'Memeriksa';
            dbRingkasan = 'Menunggu hasil dari API...';
            dbWarna = skema.outline;
          } else if (data == null) {
            dbLabel = 'Tidak diketahui';
            dbRingkasan = 'Tidak dapat diperiksa karena API tidak terjangkau.';
            dbWarna = skema.outline;
          } else if (data.databaseOk) {
            dbLabel = 'Terhubung';
            dbRingkasan = 'MySQL ${data.mysqlVersion ?? '-'}';
            dbWarna = hijau;
          } else {
            dbLabel = 'Bermasalah';
            dbRingkasan = data.detail ?? 'Database tidak dapat dihubungi.';
            dbWarna = skema.error;
          }

          // ---- Ringkasan keseluruhan ----
          final String bannerTeks;
          final IconData bannerIkon;
          final Color bannerWarna;
          if (memuat) {
            bannerTeks = 'Memeriksa server...';
            bannerIkon = Icons.hourglass_top;
            bannerWarna = skema.primary;
          } else if (data == null) {
            bannerTeks = 'Server tidak terjangkau';
            bannerIkon = Icons.cloud_off_outlined;
            bannerWarna = skema.error;
          } else if (!data.databaseOk) {
            bannerTeks = 'API hidup, database bermasalah';
            bannerIkon = Icons.warning_amber_rounded;
            bannerWarna = oranye;
          } else {
            bannerTeks = 'Semua layanan normal';
            bannerIkon = Icons.cloud_done_outlined;
            bannerWarna = hijau;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bannerWarna.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    memuat
                        ? SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: bannerWarna,
                            ),
                          )
                        : Icon(bannerIkon, size: 30, color: bannerWarna),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        bannerTeks,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: bannerWarna,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card.outlined(
                child: ListTile(
                  leading: Icon(Icons.link, color: skema.primary),
                  title: Text(
                    'Alamat API',
                    style: TextStyle(
                      fontSize: 12,
                      color: skema.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    alamatApi.value,
                    style: TextStyle(fontSize: 15, color: skema.onSurface),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _LayananTile(
                ikon: Icons.api,
                nama: 'API',
                ringkasan: apiRingkasan,
                label: apiLabel,
                warna: apiWarna,
              ),
              _LayananTile(
                ikon: Icons.storage_outlined,
                nama: 'Database (MySQL)',
                ringkasan: dbRingkasan,
                label: dbLabel,
                warna: dbWarna,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: memuat ? null : _periksaLagi,
                icon: const Icon(Icons.refresh),
                label: const Text('Periksa lagi'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LayananTile extends StatelessWidget {
  final IconData ikon;
  final String nama;
  final String ringkasan;
  final String label;
  final Color warna;

  const _LayananTile({
    required this.ikon,
    required this.nama,
    required this.ringkasan,
    required this.label,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: warna.withOpacity(0.12),
              child: Icon(ikon, color: warna),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: warna.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: warna,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ringkasan,
                    style: TextStyle(
                      fontSize: 13,
                      color: skema.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
