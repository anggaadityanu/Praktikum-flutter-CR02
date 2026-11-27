import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/pengguna.dart';
import '../state/sesi.dart';
import 'api_client.dart';
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

/// Register, login, refresh, profil, dan pengaturan akun.
///
/// Dua client dipakai: [_client] (tanpa token) untuk register, login, dan
/// refresh yang tidak boleh memicu pembaruan otomatis, serta [_klienToken]
/// (ApiClient) untuk endpoint yang butuh login.
class AuthApi {
  final http.Client _client;
  final http.Client _klienToken;

  AuthApi({http.Client? client, http.Client? klienToken})
      : _client = client ?? http.Client(),
        _klienToken = klienToken ?? client ?? ApiClient();

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

  /// Menyimpan target tabungan harian ke akun (server), lalu memperbarui
  /// profil tersimpan. Bila server menolak, galat dilempar dan profil tetap.
  Future<Pengguna> ubahTarget(int target) async {
    final res = await _klienToken
        .patch(
          _uri('/users/me'),
          headers: _json,
          body: jsonEncode({'target_harian': target}),
        )
        .timeout(batasWaktu);
    if (res.statusCode != 200) throw ApiException.dariRespons(res);
    final p = Pengguna.fromJson(_objek(res));
    await simpanProfil(p);
    return p;
  }
}
