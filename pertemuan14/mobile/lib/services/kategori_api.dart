import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/kategori.dart';
import 'api_exception.dart';
import 'cache_client.dart';

/// Pembungkus endpoint GET /kategori. [client] bisa diganti MockClient saat diuji.
class KategoriApi {
  final http.Client _client;

  // CacheClient: kategori terakhir yang berhasil dimuat tetap tersedia saat offline.
  KategoriApi({http.Client? client}) : _client = client ?? CacheClient();

  /// Kategori aktif, urut sesuai pengaturan admin.
  Future<List<Kategori>> daftar() async {
    final uri = Uri.parse('${alamatApi.value}/kategori');
    final res = await _client.get(uri).timeout(batasWaktu);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException.dariRespons(res);
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return data
        .map((e) => Kategori.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}