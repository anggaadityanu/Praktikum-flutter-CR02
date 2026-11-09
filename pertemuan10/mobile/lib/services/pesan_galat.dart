import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_exception.dart';

/// Mengubah galat apa pun menjadi pesan yang mudah dipahami pengguna.
String pesanGalat(Object e) {
  if (e is ApiException) return e.pesan;
  if (e is TimeoutException) {
    return 'Server tidak merespons dalam ${batasWaktu.inSeconds} detik.';
  }
  if (e is SocketException || e is http.ClientException) {
    return 'Tidak dapat terhubung ke server. Pastikan Docker berjalan dan alamat API benar.';
  }
  return 'Terjadi kesalahan: $e';
}
