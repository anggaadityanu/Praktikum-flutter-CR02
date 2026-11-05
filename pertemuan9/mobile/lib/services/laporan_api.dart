import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/kegiatan.dart';
import '../models/laporan.dart';
import '../utils/format.dart';
import 'api_exception.dart';

/// Pembungkus endpoint /laporan. [client] bisa diganti MockClient saat diuji.
class LaporanApi {
  final http.Client _client;

  LaporanApi({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> _ambil(String path, Map<String, String> query) async {
    final uri = Uri.parse('${alamatApi.value}$path').replace(queryParameters: query);
    final res = await _client.get(uri).timeout(batasWaktu);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException.dariRespons(res);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Laporan satu hari. [tanggal] berformat yyyy-MM-dd.
  Future<LaporanHarian> harian(String tanggal) async {
    final data = await _ambil('/laporan/harian', {'tanggal': tanggal});
    return LaporanHarian.fromJson(data as Map<String, dynamic>);
  }

  /// Ringkasan setiap hari dari [mulai] sampai [sampai] (yyyy-MM-dd),
  /// termasuk hari tanpa kegiatan.
  Future<List<RingkasanHari>> rentang(String mulai, String sampai) async {
    final data = await _ambil('/laporan/rentang', {'mulai': mulai, 'sampai': sampai});
    return (data as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return RingkasanHari(
        tanggal: dariKunci(m['tanggal'] as String),
        ringkasan: Ringkasan.fromJson(m),
      );
    }).toList();
  }
}
