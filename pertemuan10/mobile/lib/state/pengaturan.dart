import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PilihanWarna {
  final String nama;
  final Color warna;
  const PilihanWarna(this.nama, this.warna);
}

const daftarWarna = [
  PilihanWarna('Violet', Color(0xFF6C4CF1)),
  PilihanWarna('Zamrud', Color(0xFF10B981)),
  PilihanWarna('Jingga', Color(0xFFF97316)),
  PilihanWarna('Mawar', Color(0xFFE11D48)),
  PilihanWarna('Langit', Color(0xFF0EA5E9)),
];

const targetMin = 5000;
const targetMaks = 100000;
const targetBawaan = 20000;

final ValueNotifier<ThemeMode> modeTema = ValueNotifier(ThemeMode.system);
final ValueNotifier<int> indeksWarna = ValueNotifier(0);
final ValueNotifier<int> targetHarian = ValueNotifier(targetBawaan);

/// Dipanggil sekali di main() sebelum runApp.
Future<void> muatPengaturan() async {
  final prefs = await SharedPreferences.getInstance();

  final mode = (prefs.getInt('mode') ?? 0)
      .clamp(0, ThemeMode.values.length - 1)
      .toInt();
  modeTema.value = ThemeMode.values[mode];

  indeksWarna.value = (prefs.getInt('warna') ?? 0)
      .clamp(0, daftarWarna.length - 1)
      .toInt();

  targetHarian.value = (prefs.getInt('target') ?? targetBawaan)
      .clamp(targetMin, targetMaks)
      .toInt();
}

Future<void> setModeTema(ThemeMode m) async {
  modeTema.value = m;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('mode', m.index);
}

Future<void> setIndeksWarna(int i) async {
  indeksWarna.value = i;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('warna', i);
}

Future<void> setTarget(int nilai) async {
  targetHarian.value = nilai;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('target', nilai);
}