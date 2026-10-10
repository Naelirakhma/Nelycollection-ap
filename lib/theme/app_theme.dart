import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2E2A4D);
  static const muted = Color(0xFF6A6682);
  static const border = Color(0xFFE6E0F0);
  static const field = Color(0xFFF7F4FB);
  static const pinkPastel = Color(0xFFFCD5E1);
  static const pinkStrong = Color(0xFFF29BB8);
  static const pinkAccent = Color(0xFFEE82A8);
  static const pinkText = Color(0xFFA62D5A);
  static const yellowPastel = Color(0xFFFFF0B8);
  static const yellowStrong = Color(0xFFF7D774);
  static const yellowText = Color(0xFF7A5C00);
  static const bluePastel = Color(0xFFD3E9FA);
  static const blueStrong = Color(0xFF7DB9E8);
  static const blueText = Color(0xFF1F5A8C);
  static const whatsapp = Color(0xFF1E7A4F);
}

abstract final class AppTheme {
  static ThemeData get light {
    final body = GoogleFonts.plusJakartaSansTextTheme();
    final headings = GoogleFonts.cormorantGaramond(
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    );
    final textTheme = body.copyWith(
      displayLarge: headings.copyWith(fontSize: 44),
      displayMedium: headings.copyWith(fontSize: 36),
      displaySmall: headings.copyWith(fontSize: 32),
      headlineLarge: headings.copyWith(fontSize: 30),
      headlineMedium: headings.copyWith(fontSize: 28),
      headlineSmall: headings.copyWith(fontSize: 26),
      titleLarge: body.titleLarge?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: body.titleMedium?.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink, fontSize: 14),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ink, fontSize: 14),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.muted, fontSize: 12),
      labelLarge: body.labelLarge?.copyWith(
        color: AppColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: body.labelMedium?.copyWith(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: body.labelSmall?.copyWith(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.pinkAccent,
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.background,
      secondary: AppColors.pinkAccent,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: const Color(0xFFB3261E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.background,
          minimumSize: const Size(44, 48),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.background,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.pinkText,
          minimumSize: const Size(44, 44),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(44, 48),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.pinkAccent, width: 1.5),
        ),
        labelStyle: textTheme.bodySmall,
        hintStyle: textTheme.bodySmall,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.pinkPastel,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.pinkText,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.pinkPastel,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        height: 76,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border),
    );
  }
}
