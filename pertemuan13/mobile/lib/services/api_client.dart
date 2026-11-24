import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../state/sesi.dart';
import 'api_exception.dart';
import 'auth_api.dart';

/// Endpoint yang tidak boleh memicu refresh saat membalas 401
/// (401 di sini berarti "kredensial salah", bukan "token kedaluwarsa").
const _tanpaRefresh = {'/auth/login', '/auth/register', '/auth/refresh'};

/// Pola decorator: membungkus http.Client lain, menambahkan header
/// `Authorization: Bearer <token>`, dan memperbarui token otomatis.
///
/// Saat server membalas 401:
/// 1. minta pasangan token baru lewat refresh token,
/// 2. simpan token baru, lalu ulangi request **sekali**,
/// 3. bila refresh **ditolak** server (401/403), hapus sesi (auto-logout),
/// 4. bila server **tidak dapat dihubungi**, sesi dipertahankan.
class ApiClient extends http.BaseClient {
  final http.Client _inner;

  ApiClient([http.Client? inner]) : _inner = inner ?? http.Client();

  /// Refresh yang sedang berjalan. Request lain yang juga mendapat 401
  /// ikut menunggu Future ini, sehingga hanya ada satu refresh bersamaan.
  static Future<bool>? _sedangBerjalan;

  @visibleForTesting
  static void resetUntukTes() => _sedangBerjalan = null;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Satu request hanya boleh dikirim sekali, jadi siapkan salinannya dulu.
    final salinan = request is http.Request ? _salin(request) : null;

    final tokenAwal = accessToken;
    if (tokenAwal != null) {
      request.headers['Authorization'] = 'Bearer $tokenAwal';
    }

    final res = await _inner.send(request);

    if (res.statusCode != 401 ||
        salinan == null ||
        tokenAwal == null ||
        refreshTokenSesi == null ||
        _tanpaRefresh.contains(request.url.path)) {
      return res;
    }

    if (accessToken == tokenAwal) {
      // Token belum diganti siapa pun: perbarui (atau gabung ke refresh
      // yang sedang berjalan).
      bool berhasil;
      try {
        berhasil = await _perbarui();
      } catch (_) {
        await res.stream.drain<void>();
        rethrow; // galat jaringan: sesi dipertahankan
      }
      if (!berhasil) return res; // refresh ditolak: kembalikan 401 asli
    } else if (accessToken == null) {
      return res; // sesi sudah dihapus oleh request lain
    }
    // else: request lain sudah memperbarui token; cukup ulangi.

    await res.stream.drain<void>();
    salinan.headers['Authorization'] = 'Bearer $accessToken';
    return _inner.send(salinan); // diulang sekali, tanpa perulangan lagi
  }

  Future<bool> _perbarui() {
    return _sedangBerjalan ??=
        _lakukanRefresh().whenComplete(() => _sedangBerjalan = null);
  }

  Future<bool> _lakukanRefresh() async {
    final token = refreshTokenSesi;
    if (token == null) return false;
    try {
      final pasangan = await AuthApi(client: _inner).refresh(token);
      await simpanTokenBaru(pasangan.access, pasangan.refresh);
      return true;
    } on ApiException catch (e) {
      // Server menjawab: 401/403 berarti sesi memang tidak berlaku lagi.
      // Kode lain (misalnya 500) adalah masalah server, bukan sesi.
      if (e.kode == 401 || e.kode == 403) await hapusSesi();
      return false;
    }
    // Galat jaringan (SocketException, TimeoutException, ClientException)
    // sengaja tidak ditangkap: dilempar ke pemanggil dan sesi tetap utuh.
  }

  http.Request _salin(http.Request r) => http.Request(r.method, r.url)
    ..headers.addAll(r.headers)
    ..bodyBytes = r.bodyBytes
    ..followRedirects = r.followRedirects
    ..maxRedirects = r.maxRedirects
    ..persistentConnection = r.persistentConnection;

  @override
  void close() => _inner.close();
}
