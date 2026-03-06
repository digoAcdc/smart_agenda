import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static const Color _brandPrimary = Color(0xFF8FCF45);
  static const Color _brandPrimaryContainer = Color(0xFFE7F4D2);

  static ThemeData light() {
    const seed = _brandPrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    const seed = _brandPrimary;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: _brandPrimary,
        onPrimary: Colors.white,
        primaryContainer: _brandPrimaryContainer,
      ),
      extensions: <ThemeExtension<dynamic>>[
        const AppPaletteColors(
          appBackground: Color(0xFFF4F6F3),
          surfaceSoft: Color(0xFFEFF2EE),
          scheduleHeader: Color(0xFFE9EFE6),
          scheduleTimeColumn: Color(0xFFE4ECE2),
          scheduleCellEmpty: Color(0xFFF2F5F1),
          scheduleCellFilled: Color(0xFFE7F4D8),
        ),
        AppSemanticColors(
          success: const Color(0xFF34C759),
          warning: const Color(0xFFFFA726),
          danger: const Color(0xFFFF5C5C),
          info: _brandPrimary,
          pending: const Color(0xFF7DBA3C),
        ),
      ],
    );
    final activeScheme = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F6F3),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: activeScheme.surface,
        foregroundColor: activeScheme.onSurface,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.35),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: activeScheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: activeScheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
        labelStyle: base.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: activeScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceSm + 2,
          vertical: DesignTokens.spaceSm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          borderSide: BorderSide(color: activeScheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          textStyle: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(DesignTokens.buttonHeight),
          side: BorderSide(color: activeScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(
            BorderSide(color: activeScheme.outlineVariant),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),
    );
  }
}
