import 'package:flutter/material.dart';

/// Tema aplikasi Reservasi PAA.
/// Warna utama: biru gelap (sesuai spesifikasi login di 01_auth.md)
class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF1A3A5C);       // Biru gelap
  static const Color primaryVariant = Color(0xFF0D2137);     // Lebih gelap
  static const Color accentColor = Color(0xFF2E7DC0);        // Biru terang
  static const Color successColor = Color(0xFF27AE60);       // Hijau (slot kosong)
  static const Color warningColor = Color(0xFFF39C12);       // Kuning (slot pending)
  static const Color dangerColor = Color(0xFFE74C3C);        // Merah (slot booked)
  static const Color textPrimary = Color(0xFF1C2B3A);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color scaffoldBg = Color(0xFFF4F7FA);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
      ),
    );
  }
}
