import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Hasil pemeriksaan GET /health.
///
/// Bila objek ini berhasil dibuat, berarti API **hidup** (server membalas).
/// Kondisi database dibaca dari [databaseOk].
class StatusServer {
  final String status;
  final String waktuServer;
  final bool databaseOk;
  final String? mysqlVersion;
  final String? detail;
  final Duration latensi;

  const StatusServer({
    required this.status,
    required this.waktuServer,
    required this.databaseOk,
    required this.latensi,
    this.mysqlVersion,
    this.detail,
  });
}

/// Memanggil GET /health dan mengukur lama responsnya.
///
/// - 200: API dan database sehat.
/// - 503: API hidup, tetapi database tidak dapat dihubungi (bukan galat).
/// - kode lain: dianggap galat dan dilempar sebagai Exception.
Future<StatusServer> cekServer({http.Client? client}) async {
  final c = client ?? http.Client();
  final jam = Stopwatch()..start();
  try {
    final res =
        await c.get(Uri.parse('${alamatApi.value}/health')).timeout(batasWaktu);
    jam.stop();

    if (res.statusCode != 200 && res.statusCode != 503) {
      throw Exception('Server membalas kode ${res.statusCode}');
    }

    final data = _bacaJson(res.bodyBytes);

    if (res.statusCode == 503) {
      return StatusServer(
        status: data['status'] as String? ?? 'degraded',
        waktuServer: data['waktu_server'] as String? ?? '-',
        databaseOk: false,
        detail: data['detail'] as String? ?? 'Database tidak dapat dihubungi.',
        latensi: jam.elapsed,
      );
    }

    return StatusServer(
      status: data['status'] as String? ?? 'ok',
      waktuServer: data['waktu_server'] as String? ?? '-',
      databaseOk: data['database'] == 'ok',
      mysqlVersion: data['mysql_version'] as String?,
      latensi: jam.elapsed,
    );
  } finally {
    if (client == null) c.close();
  }
}

Map<String, dynamic> _bacaJson(List<int> bytes) {
  try {
    final hasil = jsonDecode(utf8.decode(bytes));
    if (hasil is Map<String, dynamic>) return hasil;
  } catch (_) {
    // Isi balasan bukan JSON; abaikan dan pakai nilai bawaan.
  }
  return <String, dynamic>{};
}
