import 'dart:convert';

import 'package:http/http.dart' as http;

/// Galat dari server yang sudah diterjemahkan menjadi pesan siap tampil.
class ApiException implements Exception {
  final int? kode;
  final String pesan;

  const ApiException(this.pesan, {this.kode});

  /// Membaca field `detail` dari respons FastAPI:
  /// - HTTPException  -> {"detail": "Kegiatan tidak ditemukan"}
  /// - validasi (422) -> {"detail": [{"loc": [...], "msg": "..."}]}
  factory ApiException.dariRespons(http.Response res) {
    var pesan = 'Server membalas kode ${res.statusCode}';
    try {
      final isi = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final detail = isi['detail'];
      if (detail is String) {
        pesan = detail;
      } else if (detail is List) {
        pesan = detail
            .map((e) => ((e as Map<String, dynamic>)['msg'] as String)
                .replaceFirst('Value error, ', ''))
            .join('\n');
      }
    } catch (_) {
      // Badan respons bukan JSON (misalnya halaman galat 502 dari proxy);
      // pakai pesan bawaan di atas.
    }
    return ApiException(pesan, kode: res.statusCode);
  }

  @override
  String toString() => pesan;
}
