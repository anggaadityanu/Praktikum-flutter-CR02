import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class K {
  static const primary = Color(0xFF12A05C);
  static const primaryDark = Color(0xFF0B7A44);
  static const mint = Color(0xFFE3F5EB);
  static const bg = Color(0xFFF4F7F5);
  static const border = Color(0xFFDCEBE3);
  static const warn = Color(0xFFFFE9C7);
  static const danger = Color(0xFFD64545);
}

ThemeData kostifyTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: K.primary, primary: K.primary),
      scaffoldBackgroundColor: K.bg,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: K.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: K.mint,
        labelTextStyle: WidgetStatePropertyAll(
            GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: K.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: K.border),
        ),
      ),
    );