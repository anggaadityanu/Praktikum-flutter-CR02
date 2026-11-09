import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/pengguna.dart';
import '../services/token_storage.dart';

const kunciToken = 'access_token';
const kunciRefresh = 'refresh_token';
const kunciProfil = 'profil';

/// Pengguna yang sedang login; null berarti belum login.
final ValueNotifier<Pengguna?> pengguna = ValueNotifier<Pengguna?>(null);

/// Token di memori agar tidak membaca storage di setiap request.
String? accessToken;
String? refreshTokenSesi;

TokenStorage penyimpanToken = SecureTokenStorage();

/// Dipanggil sekali di main(): memulihkan sesi dari penyimpanan aman.
Future<void> muatSesi() async {
  try {
    final access = await penyimpanToken.baca(kunciToken);
    final refresh = await penyimpanToken.baca(kunciRefresh);
    final profil = await penyimpanToken.baca(kunciProfil);
    // Sesi lama (tanpa refresh token) tidak dapat diperbarui: login ulang.
    if (access == null || refresh == null || profil == null) return;
    accessToken = access;
    refreshTokenSesi = refresh;
    pengguna.value =
        Pengguna.fromJson(jsonDecode(profil) as Map<String, dynamic>);
  } catch (_) {
    // Penyimpanan rusak atau tidak terbaca: anggap belum login.
    accessToken = null;
    refreshTokenSesi = null;
    pengguna.value = null;
  }
}

Future<void> simpanSesi(String access, String refresh, Pengguna p) async {
  await penyimpanToken.tulis(kunciToken, access);
  await penyimpanToken.tulis(kunciRefresh, refresh);
  await penyimpanToken.tulis(kunciProfil, jsonEncode(p.toJson()));
  accessToken = access;
  refreshTokenSesi = refresh;
  pengguna.value = p;
}

/// Mengganti pasangan token hasil refresh tanpa mengubah profil.
Future<void> simpanTokenBaru(String access, String refresh) async {
  await penyimpanToken.tulis(kunciToken, access);
  await penyimpanToken.tulis(kunciRefresh, refresh);
  accessToken = access;
  refreshTokenSesi = refresh;
}

Future<void> hapusSesi() async {
  await penyimpanToken.hapusSemua();
  accessToken = null;
  refreshTokenSesi = null;
  pengguna.value = null;
}
