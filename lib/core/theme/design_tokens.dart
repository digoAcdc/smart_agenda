import 'package:flutter/material.dart';

class DesignTokens {
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;

  static const double spaceXxs = 6;
  static const double spaceXs = 8;
  static const double spaceSm = 12;
  static const double spaceMd = 16;
  static const double spaceMl = 20;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double buttonHeight = 52;
  static const double cardMinHeight = 84;
  static const double chipHeight = 28;
  static const double bottomNavHeight = 68;

  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionStandard = Duration(milliseconds: 240);
  static const Duration motionSlow = Duration(milliseconds: 300);

  static const double opacityPressed = 0.12;
  static const double opacitySoft = 0.08;
  static const double opacityMuted = 0.62;

  static const Curve curveStandard = Curves.easeOut;
  static const Curve curveEmphasized = Curves.fastOutSlowIn;
}

@immutable
class AppPaletteColors extends ThemeExtension<AppPaletteColors> {
  const AppPaletteColors({
    required this.appBackground,
    required this.surfaceSoft,
    required this.scheduleHeader,
    required this.scheduleTimeColumn,
    required this.scheduleCellEmpty,
    required this.scheduleCellFilled,
  });

  final Color appBackground;
  final Color surfaceSoft;
  final Color scheduleHeader;
  final Color scheduleTimeColumn;
  final Color scheduleCellEmpty;
  final Color scheduleCellFilled;

  @override
  AppPaletteColors copyWith({
    Color? appBackground,
    Color? surfaceSoft,
    Color? scheduleHeader,
    Color? scheduleTimeColumn,
    Color? scheduleCellEmpty,
    Color? scheduleCellFilled,
  }) {
    return AppPaletteColors(
      appBackground: appBackground ?? this.appBackground,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      scheduleHeader: scheduleHeader ?? this.scheduleHeader,
      scheduleTimeColumn: scheduleTimeColumn ?? this.scheduleTimeColumn,
      scheduleCellEmpty: scheduleCellEmpty ?? this.scheduleCellEmpty,
      scheduleCellFilled: scheduleCellFilled ?? this.scheduleCellFilled,
    );
  }

  @override
  AppPaletteColors lerp(ThemeExtension<AppPaletteColors>? other, double t) {
    if (other is! AppPaletteColors) return this;
    return AppPaletteColors(
      appBackground:
          Color.lerp(appBackground, other.appBackground, t) ?? appBackground,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t) ?? surfaceSoft,
      scheduleHeader:
          Color.lerp(scheduleHeader, other.scheduleHeader, t) ?? scheduleHeader,
      scheduleTimeColumn: Color.lerp(
              scheduleTimeColumn, other.scheduleTimeColumn, t) ??
          scheduleTimeColumn,
      scheduleCellEmpty:
          Color.lerp(scheduleCellEmpty, other.scheduleCellEmpty, t) ??
              scheduleCellEmpty,
      scheduleCellFilled:
          Color.lerp(scheduleCellFilled, other.scheduleCellFilled, t) ??
              scheduleCellFilled,
    );
  }
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.pending,
  });

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color pending;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? pending,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      pending: pending ?? this.pending,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      info: Color.lerp(info, other.info, t) ?? info,
      pending: Color.lerp(pending, other.pending, t) ?? pending,
    );
  }
}

extension SemanticColorsExtension on BuildContext {
  AppPaletteColors get palette =>
      Theme.of(this).extension<AppPaletteColors>() ??
      const AppPaletteColors(
        appBackground: Color(0xFFF4F6F3),
        surfaceSoft: Color(0xFFEFF2EE),
        scheduleHeader: Color(0xFFE9EFE6),
        scheduleTimeColumn: Color(0xFFE4ECE2),
        scheduleCellEmpty: Color(0xFFF2F5F1),
        scheduleCellFilled: Color(0xFFDDEBFF),
      );

  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      const AppSemanticColors(
        success: Color(0xFF34C759),
        warning: Color(0xFFFFA726),
        danger: Color(0xFFFF5C5C),
        info: Color(0xFF4F46E5),
        pending: Color(0xFF7E57C2),
      );
}
