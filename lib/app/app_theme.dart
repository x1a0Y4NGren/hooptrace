import 'package:flutter/material.dart';

import 'package:hooptrace/app/design_system/editorial_motion.dart';
import 'package:hooptrace/app/design_system/editorial_theme.dart';
import 'package:hooptrace/app/design_system/editorial_tokens.dart';

export 'package:hooptrace/app/design_system/editorial_color_helpers.dart';
export 'package:hooptrace/app/design_system/editorial_motion.dart';
export 'package:hooptrace/app/design_system/editorial_theme.dart';
export 'package:hooptrace/app/design_system/editorial_tokens.dart';

ThemeData buildHoopTraceTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final editorial = isDark
      ? const HoopTraceEditorialTheme.dark()
      : const HoopTraceEditorialTheme.light();
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: editorial.arenaAccent,
        brightness: brightness,
        primary: editorial.arenaAccent,
        surface: editorial.surface,
      ).copyWith(
        onPrimary: const Color(0xFF101112),
        onSurface: editorial.ink,
        surfaceContainerLowest: editorial.canvas,
        surfaceContainerLow: editorial.surface,
        surfaceContainer: isDark
            ? const Color(0xFF202326)
            : const Color(0xFFE8E7E2),
        surfaceContainerHigh: isDark
            ? const Color(0xFF292C2F)
            : const Color(0xFFDEDDD8),
        surfaceContainerHighest: isDark
            ? const Color(0xFF32363A)
            : const Color(0xFFD3D2CD),
        outline: editorial.rule,
        outlineVariant: editorial.rule,
        error: editorial.danger,
        onError: editorial.foregroundOnTeam,
        inverseSurface: editorial.inverseSurface,
        onInverseSurface: editorial.canvas,
      );
  final baseTextTheme = ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
  ).textTheme;
  final textTheme = baseTextTheme
      .copyWith(
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: HoopTraceTypography.body,
          height: 1.45,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: HoopTraceTypography.label,
          height: 1.45,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: HoopTraceTypography.label,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: HoopTraceTypography.title,
          fontWeight: FontWeight.w700,
        ),
      )
      .apply(bodyColor: editorial.ink, displayColor: editorial.ink);

  ButtonStyle buttonStyle({required bool filled}) => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return editorial.surface;
      return filled ? editorial.arenaAccent : Colors.transparent;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return editorial.mutedInk;
      return filled ? const Color(0xFF101112) : editorial.ink;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: editorial.focus, width: 2);
      }
      return BorderSide(
        color: states.contains(WidgetState.disabled)
            ? editorial.rule
            : (filled ? editorial.arenaAccent : editorial.ink),
      );
    }),
    overlayColor: WidgetStatePropertyAll(
      editorial.arenaAccent.withValues(alpha: 0.14),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: editorial.canvas,
    canvasColor: editorial.canvas,
    focusColor: editorial.focus,
    disabledColor: editorial.mutedInk,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: editorial.canvas,
      foregroundColor: editorial.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: editorial.rule)),
    ),
    cardTheme: CardThemeData(
      color: editorial.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: editorial.rule),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: HoopTraceSpacing.compact,
      minTileHeight: 48,
      shape: RoundedRectangleBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: editorial.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: editorial.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: editorial.focus, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: editorial.rule, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle(filled: true)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: buttonStyle(filled: false),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? editorial.mutedInk
              : editorial.ink,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    ),
    extensions: [
      editorial,
      isDark
          ? const HoopTraceVisualTheme.dark()
          : const HoopTraceVisualTheme.light(),
      isDark
          ? const HoopTraceMotionTheme.dark()
          : const HoopTraceMotionTheme.light(),
    ],
  );
}
