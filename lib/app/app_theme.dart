import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

/// Compatibility palette for feature pages awaiting the editorial migration.
/// New code should consume [HoopTraceEditorialTheme] semantic colors instead.
class HoopTraceColors {
  const HoopTraceColors._();

  static const offWhite = Color(0xFFF4F3EF);
  static const cream = Color(0xFFFFFFFF);
  static const orange = Color(0xFFFF5A1F);
  static const orangeLight = Color(0xFFFF6A32);
  static const red = Color(0xFFA41E29);
  static const redLight = Color(0xFFFF747D);
  static const redAccessible = red;
  static const blue = Color(0xFF064BA3);
  static const blueLight = Color(0xFF69A1FF);
  static const blueAccessible = blue;
  static const ink = Color(0xFF101112);
  static const charcoal = Color(0xFF0C0D0E);
  static const charcoalSurface = Color(0xFF151719);
  static const charcoalContainer = Color(0xFF202326);
  static const darkInk = Color(0xFFF4F3EF);
}

class HoopTraceSpacing {
  const HoopTraceSpacing._();

  static const page = 16.0;
  static const pageMedium = 24.0;
  static const pageWide = 40.0;
  static const section = 24.0;
  static const sectionWide = 40.0;
  static const card = 12.0;
  static const compact = 8.0;
  static const hairline = 4.0;

  static double pageFor(double width) {
    if (width >= 960) return pageWide;
    if (width >= 600) return pageMedium;
    return page;
  }

  static double sectionFor(double width) =>
      width >= 600 ? sectionWide : section;
}

class HoopTraceRadii {
  const HoopTraceRadii._();

  static const card = 4.0;
  static const control = 4.0;
  static const pill = 999.0;
}

class HoopTraceTypography {
  const HoopTraceTypography._();

  static const displayFamily = 'Barlow Condensed';
  static const body = 16.0;
  static const label = 14.0;
  static const title = 22.0;

  static double mastheadFor(double width) {
    if (width >= 960) return 64;
    if (width >= 600) return 52;
    return 40;
  }

  static double scoreFor(double width) => width >= 600 ? 72 : 56;
}

class HoopTraceStatusColors {
  const HoopTraceStatusColors._();

  static const positive = Color(0xFF176B45);
  static const warning = Color(0xFF7A4B00);
  static const negative = HoopTraceColors.red;
  static const info = HoopTraceColors.blue;
}

/// Semantic colors for the black-court editorial visual language.
@immutable
class HoopTraceEditorialTheme extends ThemeExtension<HoopTraceEditorialTheme> {
  const HoopTraceEditorialTheme({
    required this.canvas,
    required this.surface,
    required this.inverseSurface,
    required this.ink,
    required this.mutedInk,
    required this.rule,
    required this.arenaAccent,
    required this.teamBlue,
    required this.teamRed,
    required this.foregroundOnTeam,
    required this.focus,
    required this.success,
    required this.warning,
    required this.danger,
  });

  const HoopTraceEditorialTheme.light()
    : this(
        canvas: const Color(0xFFF4F3EF),
        surface: const Color(0xFFFFFFFF),
        inverseSurface: const Color(0xFF101112),
        ink: const Color(0xFF101112),
        mutedInk: const Color(0xFF5C6063),
        rule: const Color(0xFF878B8D),
        arenaAccent: const Color(0xFFFF5A1F),
        teamBlue: const Color(0xFF064BA3),
        teamRed: const Color(0xFFA41E29),
        foregroundOnTeam: const Color(0xFFF4F3EF),
        focus: const Color(0xFFFF5A1F),
        success: const Color(0xFF176B45),
        warning: const Color(0xFF7A4B00),
        danger: const Color(0xFFA41E29),
      );

  const HoopTraceEditorialTheme.dark()
    : this(
        canvas: const Color(0xFF0C0D0E),
        surface: const Color(0xFF151719),
        inverseSurface: const Color(0xFFF4F3EF),
        ink: const Color(0xFFF4F3EF),
        mutedInk: const Color(0xFFAEB3B7),
        rule: const Color(0xFF777D82),
        arenaAccent: const Color(0xFFFF6A32),
        teamBlue: const Color(0xFF69A1FF),
        teamRed: const Color(0xFFFF747D),
        foregroundOnTeam: const Color(0xFF101112),
        focus: const Color(0xFFFF6A32),
        success: const Color(0xFF55D996),
        warning: const Color(0xFFF5B942),
        danger: const Color(0xFFFF747D),
      );

  final Color canvas;
  final Color surface;
  final Color inverseSurface;
  final Color ink;
  final Color mutedInk;
  final Color rule;
  final Color arenaAccent;
  final Color teamBlue;
  final Color teamRed;
  final Color foregroundOnTeam;
  final Color focus;
  final Color success;
  final Color warning;
  final Color danger;

  @override
  HoopTraceEditorialTheme copyWith({
    Color? canvas,
    Color? surface,
    Color? inverseSurface,
    Color? ink,
    Color? mutedInk,
    Color? rule,
    Color? arenaAccent,
    Color? teamBlue,
    Color? teamRed,
    Color? foregroundOnTeam,
    Color? focus,
    Color? success,
    Color? warning,
    Color? danger,
  }) {
    return HoopTraceEditorialTheme(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      inverseSurface: inverseSurface ?? this.inverseSurface,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      rule: rule ?? this.rule,
      arenaAccent: arenaAccent ?? this.arenaAccent,
      teamBlue: teamBlue ?? this.teamBlue,
      teamRed: teamRed ?? this.teamRed,
      foregroundOnTeam: foregroundOnTeam ?? this.foregroundOnTeam,
      focus: focus ?? this.focus,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
    );
  }

  @override
  HoopTraceEditorialTheme lerp(
    covariant HoopTraceEditorialTheme? other,
    double t,
  ) {
    if (other == null) return this;
    return HoopTraceEditorialTheme(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      inverseSurface: Color.lerp(inverseSurface, other.inverseSurface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      arenaAccent: Color.lerp(arenaAccent, other.arenaAccent, t)!,
      teamBlue: Color.lerp(teamBlue, other.teamBlue, t)!,
      teamRed: Color.lerp(teamRed, other.teamRed, t)!,
      foregroundOnTeam: Color.lerp(
        foregroundOnTeam,
        other.foregroundOnTeam,
        t,
      )!,
      focus: Color.lerp(focus, other.focus, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Compatibility extension for feature pages awaiting migration.
@immutable
class HoopTraceVisualTheme extends ThemeExtension<HoopTraceVisualTheme> {
  const HoopTraceVisualTheme({
    required this.paper,
    required this.paperDeep,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.red,
    required this.blue,
    required this.divider,
    this.doodleOpacity = 0.16,
    this.strokeWidth = 1,
  });

  const HoopTraceVisualTheme.light()
    : this(
        paper: HoopTraceColors.offWhite,
        paperDeep: HoopTraceColors.cream,
        ink: HoopTraceColors.ink,
        inkMuted: const Color(0xFF5C6063),
        accent: HoopTraceColors.orange,
        red: HoopTraceColors.red,
        blue: HoopTraceColors.blue,
        divider: const Color(0xFF878B8D),
      );

  const HoopTraceVisualTheme.dark()
    : this(
        paper: HoopTraceColors.charcoal,
        paperDeep: HoopTraceColors.charcoalSurface,
        ink: HoopTraceColors.darkInk,
        inkMuted: const Color(0xFFAEB3B7),
        accent: HoopTraceColors.orangeLight,
        red: HoopTraceColors.redLight,
        blue: HoopTraceColors.blueLight,
        divider: const Color(0xFF777D82),
      );

  final Color paper;
  final Color paperDeep;
  final Color ink;
  final Color inkMuted;
  final Color accent;
  final Color red;
  final Color blue;
  final Color divider;
  final double doodleOpacity;
  final double strokeWidth;

  @override
  HoopTraceVisualTheme copyWith({
    Color? paper,
    Color? paperDeep,
    Color? ink,
    Color? inkMuted,
    Color? accent,
    Color? red,
    Color? blue,
    Color? divider,
    double? doodleOpacity,
    double? strokeWidth,
  }) {
    return HoopTraceVisualTheme(
      paper: paper ?? this.paper,
      paperDeep: paperDeep ?? this.paperDeep,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      accent: accent ?? this.accent,
      red: red ?? this.red,
      blue: blue ?? this.blue,
      divider: divider ?? this.divider,
      doodleOpacity: doodleOpacity ?? this.doodleOpacity,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  @override
  HoopTraceVisualTheme lerp(covariant HoopTraceVisualTheme? other, double t) {
    if (other == null) return this;
    return HoopTraceVisualTheme(
      paper: Color.lerp(paper, other.paper, t)!,
      paperDeep: Color.lerp(paperDeep, other.paperDeep, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      red: Color.lerp(red, other.red, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      doodleOpacity: ui.lerpDouble(doodleOpacity, other.doodleOpacity, t)!,
      strokeWidth: ui.lerpDouble(strokeWidth, other.strokeWidth, t)!,
    );
  }
}

@immutable
class HoopTraceMotionTheme extends ThemeExtension<HoopTraceMotionTheme> {
  const HoopTraceMotionTheme({
    required this.scoreFlight,
    required this.impact,
    required this.acceleratedScoreFlight,
    required this.acceleratedImpact,
    required this.reducedReveal,
    required this.press,
    required this.state,
    required this.sheet,
    required this.pageReveal,
    required this.foulStamp,
    required this.undo,
  });

  const HoopTraceMotionTheme.light()
    : this(
        scoreFlight: const Duration(milliseconds: 480),
        impact: const Duration(milliseconds: 180),
        acceleratedScoreFlight: const Duration(milliseconds: 320),
        acceleratedImpact: const Duration(milliseconds: 120),
        reducedReveal: const Duration(milliseconds: 120),
        press: const Duration(milliseconds: 90),
        state: const Duration(milliseconds: 180),
        sheet: const Duration(milliseconds: 220),
        pageReveal: const Duration(milliseconds: 220),
        foulStamp: const Duration(milliseconds: 180),
        undo: const Duration(milliseconds: 180),
      );

  const HoopTraceMotionTheme.dark() : this.light();

  final Duration scoreFlight;
  final Duration impact;
  final Duration acceleratedScoreFlight;
  final Duration acceleratedImpact;
  final Duration reducedReveal;
  final Duration press;
  final Duration state;
  final Duration sheet;
  final Duration pageReveal;
  final Duration foulStamp;
  final Duration undo;

  Duration get scoreTransition => state;
  Duration get splash => impact;

  @override
  HoopTraceMotionTheme copyWith({
    Duration? scoreFlight,
    Duration? impact,
    Duration? acceleratedScoreFlight,
    Duration? acceleratedImpact,
    Duration? reducedReveal,
    Duration? press,
    Duration? state,
    Duration? scoreTransition,
    Duration? sheet,
    Duration? pageReveal,
    Duration? foulStamp,
    Duration? undo,
  }) {
    return HoopTraceMotionTheme(
      scoreFlight: scoreFlight ?? this.scoreFlight,
      impact: impact ?? this.impact,
      acceleratedScoreFlight:
          acceleratedScoreFlight ?? this.acceleratedScoreFlight,
      acceleratedImpact: acceleratedImpact ?? this.acceleratedImpact,
      reducedReveal: reducedReveal ?? this.reducedReveal,
      press: press ?? this.press,
      state: state ?? scoreTransition ?? this.state,
      sheet: sheet ?? this.sheet,
      pageReveal: pageReveal ?? this.pageReveal,
      foulStamp: foulStamp ?? this.foulStamp,
      undo: undo ?? this.undo,
    );
  }

  @override
  HoopTraceMotionTheme lerp(covariant HoopTraceMotionTheme? other, double t) {
    if (other == null) return this;
    Duration blend(Duration a, Duration b) => Duration(
      microseconds: ui
          .lerpDouble(
            a.inMicroseconds.toDouble(),
            b.inMicroseconds.toDouble(),
            t,
          )!
          .round(),
    );
    return HoopTraceMotionTheme(
      scoreFlight: blend(scoreFlight, other.scoreFlight),
      impact: blend(impact, other.impact),
      acceleratedScoreFlight: blend(
        acceleratedScoreFlight,
        other.acceleratedScoreFlight,
      ),
      acceleratedImpact: blend(acceleratedImpact, other.acceleratedImpact),
      reducedReveal: blend(reducedReveal, other.reducedReveal),
      press: blend(press, other.press),
      state: blend(state, other.state),
      sheet: blend(sheet, other.sheet),
      pageReveal: blend(pageReveal, other.pageReveal),
      foulStamp: blend(foulStamp, other.foulStamp),
      undo: blend(undo, other.undo),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HoopTraceMotionTheme &&
      other.scoreFlight == scoreFlight &&
      other.impact == impact &&
      other.acceleratedScoreFlight == acceleratedScoreFlight &&
      other.acceleratedImpact == acceleratedImpact &&
      other.reducedReveal == reducedReveal &&
      other.press == press &&
      other.state == state &&
      other.sheet == sheet &&
      other.pageReveal == pageReveal &&
      other.foulStamp == foulStamp &&
      other.undo == undo;

  @override
  int get hashCode => Object.hash(
    scoreFlight,
    impact,
    acceleratedScoreFlight,
    acceleratedImpact,
    reducedReveal,
    press,
    state,
    sheet,
    pageReveal,
    foulStamp,
    undo,
  );
}

typedef HoopTraceVisualTokens = HoopTraceVisualTheme;
typedef HoopTraceMotionTokens = HoopTraceMotionTheme;

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
  return side == TeamSide.red ? HoopTraceColors.red : HoopTraceColors.blue;
}

Color accessibleForegroundFor(Color background) {
  const candidates = [Colors.black, Colors.white];
  final backgroundLuminance = background.computeLuminance();
  for (final candidate in candidates) {
    final foregroundLuminance = candidate.computeLuminance();
    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;
    if ((lighter + 0.05) / (darker + 0.05) >= 4.5) return candidate;
  }
  return Colors.black;
}

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
