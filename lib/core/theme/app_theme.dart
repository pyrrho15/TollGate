import 'package:flutter/material.dart';

/// The app's single source of truth for visual styling.
///
/// Widgets should read colors and shapes through `Theme.of(context)` rather than
/// hard-coding values, so the whole UI stays consistent and themeable.
class AppTheme {
  AppTheme._();

  /// Brand color the whole Material 3 palette is derived from.
  static const Color seed = Color(0xFF3D5AFE);

  /// Corner radius shared by cards and rounded surfaces.
  static const double cardRadius = 20;

  /// Standard horizontal page gutter.
  static const double gutter = 16;

  /// Convenience brand colors for the supported feeds.
  static const Color youtube = Color(0xFFFF0033);
  static const Color instagram = Color(0xFFE1306C);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final isLight = brightness == Brightness.light;

    // A subtly tinted page background makes the near-white cards read as
    // distinct surfaces without needing drop shadows.
    final background =
        isLight ? scheme.surfaceContainerLowest : scheme.surface;
    final border = scheme.outlineVariant.withValues(alpha: isLight ? 0.6 : 0.4);

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: BorderSide(color: border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color:
            isLight ? scheme.surfaceContainerLowest : scheme.surfaceContainerLow,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: scheme.onSurfaceVariant,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : null,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : null,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
