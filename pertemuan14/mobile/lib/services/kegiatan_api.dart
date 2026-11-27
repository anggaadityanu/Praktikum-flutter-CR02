import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/kegiatan.dart';
import 'cache_client.dart';
import 'api_exception.dart';

/// Pembungkus REST API /kegiatan. [client] bisa diganti MockClient saat diuji.
class KegiatanApi {
  final http.Client _client;

  KegiatanApi({http.Client? client}) : _client = client ?? CacheClient();

  static const _json = {'Content-Type': 'application/json'};

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${alamatApi.value}$path').replace(queryParameters: query);

  /// Respons di luar 2xx dilempar sebagai ApiException.
  http.Response _cek(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException.dariRespons(res);
    }
    return res;
  }

  Map<String, dynamic> _objek(http.Response res) =>
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

  /// Semua parameter opsional; yang kosong tidak dikirim ke server.
  Future<List<Kegiatan>> daftar({
    String? tanggal,
    String? q,
    Tipe? tipe,
    String? urut,
    int? limit,
  }) async {
    final query = <String, String>{
      if (tanggal != null) 'tanggal': tanggal,
      if (q != null && q.isNotEmpty) 'q': q,
      if (tipe != null) 'tipe': tipe.name,
      if (urut != null) 'urut': urut,
      if (limit != null) 'limit': '$limit',
    };
    final res = _cek(
      await _client
          .get(_uri('/kegiatan', query.isEmpty ? null : query))
          .timeout(batasWaktu),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return data
        .map((e) => Kegiatan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Kegiatan> tambah(Kegiatan k) async {
    final res = _cek(
      await _client
          .post(_uri('/kegiatan'), headers: _json, body: jsonEncode(k.toJson()))
          .timeout(batasWaktu),
    );
    return Kegiatan.fromJson(_objek(res));
  }

  /// PUT: mengganti seluruh isi kegiatan [k] (id wajib terisi).
  Future<Kegiatan> ubah(Kegiatan k) async {
    final id = k.id;
    if (id == null) {
      throw ArgumentError('Kegiatan yang diubah harus punya id');
    }
    final res = _cek(
      await _client
          .put(_uri('/kegiatan/$id'), headers: _json, body: jsonEncode(k.toJson()))
          .timeout(batasWaktu),
    );
    return Kegiatan.fromJson(_objek(res));
  }

  /// PATCH: hanya mengirim field `selesai`.
  Future<Kegiatan> setSelesai(int id, bool selesai) async {
    final res = _cek(
      await _client
          .patch(
            _uri('/kegiatan/$id'),
            headers: _json,
            body: jsonEncode({'selesai': selesai}),
          )
          .timeout(batasWaktu),
    );
    return Kegiatan.fromJson(_objek(res));
  }

  /// DELETE: server membalas 204 tanpa isi.
  Future<void> hapus(int id) async {
    _cek(await _client.delete(_uri('/kegiatan/$id')).timeout(batasWaktu));
  }

  /// Upload foto bukti (multipart/form-data, nama field `berkas`).
  Future<Kegiatan> unggahBukti(int id, List<int> isi, String namaBerkas) async {
    final req = http.MultipartRequest('POST', _uri('/kegiatan/$id/bukti'))
      ..files.add(
        http.MultipartFile.fromBytes(
          'berkas',
          isi,
          filename: namaBerkas,
          contentType: MediaType.parse(jenisGambar(namaBerkas)),
        ),
      );
    // Upload butuh waktu lebih lama dari request biasa.
    final res = _cek(
      await http.Response.fromStream(
        await _client.send(req).timeout(const Duration(seconds: 60)),
      ),
    );
    return Kegiatan.fromJson(_objek(res));
  }

  /// Menghapus foto bukti saja; kegiatannya tetap ada.
  Future<Kegiatan> hapusBukti(int id) async {
    final res = _cek(
      await _client.delete(_uri('/kegiatan/$id/bukti')).timeout(batasWaktu),
    );
    return Kegiatan.fromJson(_objek(res));
  }
}

/// Content-Type dari ekstensi file (server hanya menerima tiga jenis ini).
String jenisGambar(String namaBerkas) {
  final n = namaBerkas.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}