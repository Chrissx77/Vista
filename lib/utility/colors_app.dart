import 'package:flutter/material.dart';

/// Tema unico dell'app, ispirato a uno stile moderno e minimal
/// (sfondo chiaro, accent verde acqua, card morbide, tipografia pulita).
///
/// Le schermate **non** devono usare `Colors.*` o `Color(0x…)`:
/// usare sempre questi token o `Theme.of(context)`.
class ColorsApp {
  ColorsApp._();

  // --- Palette base ---------------------------------------------------------

  /// Verde acqua principale (CTA, icone selezionate, link).
  static const Color primary = Color(0xFF008C7E);

  /// Verde acqua scuro per pressed / hover.
  static const Color primaryDark = Color(0xFF006F64);

  /// Sfondi morbidi accent (chip selezionato, sezioni soft).
  static const Color primarySoft = Color(0xFFE6F4F2);

  /// Rosso "trending" per badge in evidenza.
  static const Color accentRed = Color(0xFFCC1F2D);

  /// Rosa pastello per "Special Offer" / promo.
  static const Color accentPink = Color(0xFFFFE4E8);

  /// Testo su sfondo primario / accentRed.
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Superfici e testo ----------------------------------------------------

  /// Sfondo principale dell'app.
  static const Color surface = Color(0xFFFFFFFF);

  /// Sfondo elevato leggero (sezioni, card pulite).
  static const Color surfaceMuted = Color(0xFFF7F7F8);

  /// Sfondo per skeleton / placeholder immagine.
  static const Color surfaceSkeleton = Color(0xFFEDEDEF);

  /// Testo principale.
  static const Color onSurface = Color(0xFF111418);

  /// Testo secondario (sottotitoli, hint).
  static const Color onSurfaceMuted = Color(0xFF6B7280);

  /// Bordi sottili (input non focus, divider).
  static const Color outline = Color(0xFFE2E4E8);

  /// Bordo input in focus.
  static const Color focusBorder = primary;

  // --- Stati ----------------------------------------------------------------
  static const Color error = Color(0xFFD92D20);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF12B76A);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color iconPlaceholder = Color(0xFF9AA0A6);
  static const Color transparent = Color(0x00000000);

  // --- Ombre ---------------------------------------------------------------
  /// Ombra leggera per card e barre di ricerca.
  static List<BoxShadow> get softShadow => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  /// Ombra ancora più leggera, per chip / pill.
  static List<BoxShadow> get hairlineShadow => const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];

  // --- Tema Material --------------------------------------------------------
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: primarySoft,
      onSecondary: primary,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceMuted,
      onSurfaceVariant: onSurfaceMuted,
      error: error,
      onError: onError,
      outline: outline,
      outlineVariant: outline,
    );

    OutlineInputBorder roundedField({Color color = outline, double width = 1}) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      dividerColor: outline,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: transparent,
        centerTitle: false,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: transparent,
        surfaceTintColor: transparent,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 26);
          }
          return const IconThemeData(color: onSurfaceMuted, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color =
              states.contains(WidgetState.selected) ? primary : onSurfaceMuted;
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: onSurfaceMuted),
        hintStyle: const TextStyle(color: onSurfaceMuted),
        floatingLabelStyle: const TextStyle(color: primary),
        border: roundedField(),
        enabledBorder: roundedField(),
        focusedBorder: roundedField(color: focusBorder, width: 1.6),
        errorBorder: roundedField(color: error),
        focusedErrorBorder: roundedField(color: error, width: 1.6),
        prefixIconColor: onSurfaceMuted,
        suffixIconColor: onSurfaceMuted,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: outline,
          disabledForegroundColor: onSurfaceMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: outline,
          disabledForegroundColor: onSurfaceMuted,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: outline),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primarySoft,
        labelStyle: const TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        side: const BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: outline,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: onSurface,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        headlineMedium: TextStyle(
          color: onSurface,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        headlineSmall: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleLarge: TextStyle(
          color: onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: onSurfaceMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: onSurfaceMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: onSurfaceMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(color: surface, fontWeight: FontWeight.w500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      iconTheme: const IconThemeData(color: onSurface, size: 22),
    );
  }
}
