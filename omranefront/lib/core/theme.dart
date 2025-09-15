import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Primary brand color provided by user: #24574a
final ColorScheme kColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF24574A),
  brightness: Brightness.light,
);

ThemeData buildTheme() {
  final base = ThemeData(
    colorScheme: kColorScheme,
    useMaterial3: true,
    textTheme: GoogleFonts.interTextTheme(),
  );

  return base.copyWith(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kColorScheme.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        color: kColorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: kColorScheme.surfaceContainerLowest,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kColorScheme.primary,
        foregroundColor: kColorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedColor: kColorScheme.primaryContainer,
      backgroundColor: kColorScheme.surfaceContainerLowest,
      labelStyle: TextStyle(color: kColorScheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: kColorScheme.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kColorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: kColorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
