import 'package:flutter/material.dart';

/// Palette e tema chiaro dell’app: usare sempre questi token
/// (o `Theme.of(context).colorScheme` derivato da [lightTheme]),
/// mai `Colors.*` o `Color(0x…)` nelle schermate.
class ColorsApp {
  ColorsApp._();

  // --- Palette base ---------------------------------------------------------
  static const Color primary = Color(0xFF413C38);
  static const Color secondary = Color(0xFFe4e0dc);
  static const Color primaryTextColor = Color(0xFFFFFFFF);
  static const Color secondaryTextColor = Color(0xFFb2a8a1);
  static const Color buttonColor = Color(0xFFe4e0dc);

  // --- Superfici e testo --------------------------------------------------
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color onSurfaceMuted = Color(0x8A1A1A1A);
  static const Color outline = secondaryTextColor;
  static const Color focusBorder = primary;

  // --- Stati e accessori ---------------------------------------------------
  static const Color error = Color(0xFFC62828);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color iconPlaceholder = Color(0xFF9E9E9E);
  static const Color transparent = Color(0x00000000);

  // --- Tema Material (unica fonte per schermate via Theme.of) --------------
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: primaryTextColor,
      secondary: secondary,
      onSecondary: primary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      onError: onError,
      outline: outline,
    );

    final roundedField = OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: const BorderSide(color: outline),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      dividerColor: outline.withValues(alpha: 0.35),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: primaryTextColor,
        elevation: 0,
        surfaceTintColor: transparent,
        iconTheme: const IconThemeData(color: primaryTextColor),
        titleTextStyle: const TextStyle(
          color: primaryTextColor,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: buttonColor,
        surfaceTintColor: transparent,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: onSurfaceMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? primary
              : onSurfaceMuted;
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        labelStyle: const TextStyle(color: onSurfaceMuted),
        hintStyle: const TextStyle(color: onSurfaceMuted),
        border: roundedField,
        enabledBorder: roundedField,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: focusBorder, width: 2),
        ),
        prefixIconColor: onSurfaceMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: primary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryTextColor,
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: onSurface, fontSize: 16),
        bodyMedium: TextStyle(
          color: outline,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: outline,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        titleLarge: TextStyle(
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: primary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: const TextStyle(color: surface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
