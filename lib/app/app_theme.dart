import 'package:flutter/material.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class HoopTraceColors {
  const HoopTraceColors._();

  static const offWhite = Color(0xFFFFF8E8);
  static const cream = Color(0xFFF4EADB);
  static const orange = Color(0xFFFF7A1A);
  static const orangeLight = Color(0xFFFFA65C);
  static const red = Color(0xFFD94735);
  static const redLight = Color(0xFFFF8A78);
  static const redAccessible = Color(0xFFB3261E);
  static const blue = Color(0xFF2F67D8);
  static const blueLight = Color(0xFF89AEFF);
  static const blueAccessible = Color(0xFF1D4ED8);
  static const ink = Color(0xFF2B2520);
  static const charcoal = Color(0xFF171513);
  static const charcoalSurface = Color(0xFF24201D);
  static const charcoalContainer = Color(0xFF302A25);
  static const darkInk = Color(0xFFFFF8E8);
}

/// Shared spacing tokens keep the scoring, replay and settings surfaces
/// aligned without making every feature invent its own rhythm.
class HoopTraceSpacing {
  const HoopTraceSpacing._();

  static const page = 16.0;
  static const section = 24.0;
  static const card = 12.0;
  static const compact = 8.0;
}

class HoopTraceRadii {
  const HoopTraceRadii._();

  static const card = 16.0;
  static const control = 12.0;
  static const pill = 999.0;
}

class HoopTraceTypography {
  const HoopTraceTypography._();

  static const body = 16.0;
  static const label = 14.0;
  static const title = 20.0;
}

/// Semantic state colors are kept separate from the palette so stateful
/// controls do not need to know whether the app is using a light or dark
/// surface.
class HoopTraceStatusColors {
  const HoopTraceStatusColors._();

  static const positive = Color(0xFF2F7D4A);
  static const warning = Color(0xFFB56A00);
  static const negative = HoopTraceColors.red;
  static const info = HoopTraceColors.blue;
}

/// Team accents are selected for the surface they sit on, rather than using
/// the same saturated brand color in both light and dark themes.
Color teamColorForScheme(
  TeamSide side,
  ColorScheme scheme, {
  Color? background,
}) {
  final lightAccent = background == null
      ? scheme.brightness == Brightness.dark
      : background.computeLuminance() < 0.35;
  if (lightAccent) {
    return side == TeamSide.red
        ? HoopTraceColors.redLight
        : HoopTraceColors.blueLight;
  }
  return side == TeamSide.red
      ? HoopTraceColors.redAccessible
      : HoopTraceColors.blueAccessible;
}

ThemeData buildHoopTraceTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: HoopTraceColors.orange,
        brightness: brightness,
        primary: isDark ? HoopTraceColors.orangeLight : HoopTraceColors.orange,
        surface: isDark ? HoopTraceColors.charcoal : HoopTraceColors.offWhite,
      ).copyWith(
        onSurface: isDark ? HoopTraceColors.darkInk : HoopTraceColors.ink,
        surfaceContainerLowest: isDark
            ? HoopTraceColors.charcoal
            : HoopTraceColors.offWhite,
        surfaceContainer: isDark
            ? HoopTraceColors.charcoalSurface
            : HoopTraceColors.cream,
        surfaceContainerHighest: isDark
            ? HoopTraceColors.charcoalContainer
            : HoopTraceColors.cream,
        onPrimary: HoopTraceColors.charcoal,
        error: isDark ? HoopTraceColors.redLight : HoopTraceColors.red,
        onError: isDark ? HoopTraceColors.charcoal : Colors.white,
      );
  final baseTextTheme = ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
  ).textTheme;
  final textTheme = baseTextTheme
      .copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: HoopTraceTypography.body,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: HoopTraceTypography.label,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: HoopTraceTypography.label,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: HoopTraceTypography.title,
        ),
      )
      .apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: HoopTraceSpacing.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoopTraceRadii.control),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HoopTraceRadii.control),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colorScheme.onSurface.withValues(alpha: isDark ? 0.18 : 0.12),
    ),
  );
}
