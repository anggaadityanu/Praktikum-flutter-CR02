import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/pengguna.dart';
import '../state/sesi.dart';
import 'api_exception.dart';

/// Pasangan token hasil login atau refresh.
class PasanganToken {
  final String access;
  final String refresh;

  const PasanganToken(this.access, this.refresh);

  factory PasanganToken.fromJson(Map<String, dynamic> j) => PasanganToken(
        j['access_token'] as String,
        j['refresh_token'] as String,
      );
}

/// Register, login, refresh, dan profil. Memakai http.Client biasa
/// (bukan ApiClient): endpoint ini tidak boleh memicu refresh otomatis.
class AuthApi {
  final http.Client _client;

  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  static const _json = {'Content-Type': 'application/json'};

  Uri _uri(String path) => Uri.parse('${alamatApi.value}$path');

  Map<String, dynamic> _objek(http.Response res) =>
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

  /// Membuat akun baru. Belum menyimpan sesi (panggil [masuk] sesudahnya).
  Future<Pengguna> daftar(String nama, String email, String password) async {
    final res = await _client
        .post(
          _uri('/auth/register'),
          headers: _json,
          body: jsonEncode({'nama': nama, 'email': email, 'password': password}),
        )
        .timeout(batasWaktu);
    if (res.statusCode != 201) throw ApiException.dariRespons(res);
    return Pengguna.fromJson(_objek(res));
  }

  /// Login memakai form (username berisi email), lalu memuat profil
  /// dan menyimpan sesi (access dan refresh token).
  Future<Pengguna> masuk(String email, String password) async {
    final res = await _client
        .post(_uri('/auth/login'), body: {'username': email, 'password': password})
        .timeout(batasWaktu);
    if (res.statusCode != 200) throw ApiException.dariRespons(res);
    final pasangan = PasanganToken.fromJson(_objek(res));

    final p = await profil(pasangan.access);
    await simpanSesi(pasangan.access, pasangan.refresh, p);
    return p;
  }

  /// Menukar refresh token dengan pasangan token baru.
  Future<PasanganToken> refresh(String refreshToken) async {
    final res = await _client
        .post(
          _uri('/auth/refresh'),
          headers: _json,
          body: jsonEncode({'refresh_token': refreshToken}),
        )
        .timeout(batasWaktu);
    if (res.statusCode != 200) throw ApiException.dariRespons(res);
    return PasanganToken.fromJson(_objek(res));
  }

  Future<Pengguna> profil(String token) async {
    final res = await _client
        .get(_uri('/users/me'), headers: {'Authorization': 'Bearer $token'})
        .timeout(batasWaktu);
    if (res.statusCode != 200) throw ApiException.dariRespons(res);
    return Pengguna.fromJson(_objek(res));
  }
}
