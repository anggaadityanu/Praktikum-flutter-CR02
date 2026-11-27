import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../state/sesi.dart';
import 'api_client.dart';
import 'cache_store.dart';

/// Bila server tidak menjawab dalam waktu ini, isi cache dipakai.
/// Sengaja lebih pendek daripada batas waktu request (10 detik) agar
/// pemulihan dari cache terjadi lebih dulu.
const batasWaktuCache = Duration(seconds: 8);

/// Strategi network first: server dicoba dulu, cache hanya cadangan.
///
/// - GET berstatus 200 disimpan ke cache.
/// - Bila jaringan gagal (galat I/O, koneksi, atau waktu habis), isi cache
///   dikembalikan sebagai respons 200 dan [statusOffline] terisi waktu data itu.
/// - Selain GET, dan bila belum login, request diteruskan apa adanya.
/// - Kunci cache memuat id pengguna agar dua akun tidak berbagi data.
class CacheClient extends http.BaseClient {
  final http.Client _inner;
  final CacheStore? _store;
  final Duration _batas;

  CacheClient({http.Client? inner, CacheStore? store, Duration? batasWaktu})
      : _inner = inner ?? ApiClient(),
        _store = store,
        _batas = batasWaktu ?? batasWaktuCache;

  CacheStore get _penyimpan => _store ?? penyimpanCache;

  bool _galatJaringan(Object e) =>
      e is IOException || e is TimeoutException || e is http.ClientException;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final idPengguna = pengguna.value?.id;
    if (request.method != 'GET' || idPengguna == null) {
      return _inner.send(request);
    }
    final kunci = '$idPengguna|${request.url}';

    http.StreamedResponse res;
    try {
      res = await _inner.send(request).timeout(_batas);
    } catch (e) {
      if (!_galatJaringan(e)) rethrow;

      CacheEntri? entri;
      try {
        entri = await _penyimpan.baca(kunci);
      } catch (_) {
        entri = null; // cache rusak: perlakukan seperti tidak ada
      }
      if (entri == null) rethrow; // offline dan tidak ada data tersimpan

      statusOffline.value = entri.waktu;
      final bytes = utf8.encode(entri.isi);
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
        contentLength: bytes.length,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    // Server menjawab. Hanya 200 yang disimpan; jawaban lain (misalnya 401
    // atau 500) diteruskan apa adanya.
    if (res.statusCode != 200) return res;

    final bytes = await res.stream.toBytes();
    try {
      await _penyimpan.simpan(kunci, utf8.decode(bytes), DateTime.now());
    } catch (_) {
      // Gagal menyimpan cache tidak boleh menggagalkan respons yang sah.
    }
    statusOffline.value = null; // kembali online
    return http.StreamedResponse(
      Stream.value(bytes),
      200,
      contentLength: bytes.length,
      request: res.request,
      headers: res.headers,
      reasonPhrase: res.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
