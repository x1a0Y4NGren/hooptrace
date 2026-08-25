import 'dart:ui' as ui;

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

/// The visual language used by the playbook surfaces and doodle widgets.
///
/// Keeping these values in a [ThemeExtension] means feature pages can opt in
/// without coupling themselves to a particular brightness or hard-coding a
/// canvas color.
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
    this.doodleOpacity = 0.22,
    this.strokeWidth = 1.5,
  });

  const HoopTraceVisualTheme.light()
    : this(
        paper: HoopTraceColors.offWhite,
        paperDeep: HoopTraceColors.cream,
        ink: HoopTraceColors.ink,
        inkMuted: const Color(0xFF6C5D52),
        accent: HoopTraceColors.orange,
        red: HoopTraceColors.redAccessible,
        blue: HoopTraceColors.blueAccessible,
        divider: const Color(0x332B2520),
      );

  const HoopTraceVisualTheme.dark()
    : this(
        paper: HoopTraceColors.charcoal,
        paperDeep: HoopTraceColors.charcoalSurface,
        ink: HoopTraceColors.darkInk,
        inkMuted: const Color(0xFFC7B9AC),
        accent: HoopTraceColors.orangeLight,
        red: HoopTraceColors.redLight,
        blue: HoopTraceColors.blueLight,
        divider: const Color(0x33FFF8E8),
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

/// Timing tokens shared by score feedback and the playbook press treatment.
@immutable
class HoopTraceMotionTheme extends ThemeExtension<HoopTraceMotionTheme> {
  const HoopTraceMotionTheme({
    required this.scoreFlight,
    required this.impact,
    required this.acceleratedScoreFlight,
    required this.acceleratedImpact,
    required this.reducedReveal,
    required this.press,
    required this.scoreTransition,
    required this.foulStamp,
    required this.undo,
  });

  const HoopTraceMotionTheme.light()
    : this(
        scoreFlight: const Duration(milliseconds: 520),
        impact: const Duration(milliseconds: 240),
        acceleratedScoreFlight: const Duration(milliseconds: 300),
        acceleratedImpact: const Duration(milliseconds: 140),
        reducedReveal: const Duration(milliseconds: 100),
        press: const Duration(milliseconds: 90),
        scoreTransition: const Duration(milliseconds: 180),
        foulStamp: const Duration(milliseconds: 240),
        undo: const Duration(milliseconds: 180),
      );

  const HoopTraceMotionTheme.dark() : this.light();

  final Duration scoreFlight;
  final Duration impact;
  final Duration acceleratedScoreFlight;
  final Duration acceleratedImpact;
  final Duration reducedReveal;
  final Duration press;
  final Duration scoreTransition;
  final Duration foulStamp;
  final Duration undo;

  @override
  HoopTraceMotionTheme copyWith({
    Duration? scoreFlight,
    Duration? impact,
    Duration? acceleratedScoreFlight,
    Duration? acceleratedImpact,
    Duration? reducedReveal,
    Duration? press,
    Duration? scoreTransition,
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
      scoreTransition: scoreTransition ?? this.scoreTransition,
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
      scoreTransition: blend(scoreTransition, other.scoreTransition),
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
      other.scoreTransition == scoreTransition &&
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
    scoreTransition,
    foulStamp,
    undo,
  );
}

// Descriptive aliases keep the public token vocabulary discoverable while the
// ThemeExtension names remain concise at call sites.
typedef HoopTraceVisualTokens = HoopTraceVisualTheme;
typedef HoopTraceMotionTokens = HoopTraceMotionTheme;

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

/// Returns a foreground that keeps avatar labels readable on a solid color.
///
/// The palette includes both light and dark team accents, so a fixed white
/// avatar label is not sufficient for every surface. The first candidate that
/// meets the normal-text contrast threshold is selected deterministically.
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
    extensions: [
      isDark
          ? const HoopTraceVisualTheme.dark()
          : const HoopTraceVisualTheme.light(),
      isDark
          ? const HoopTraceMotionTheme.dark()
          : const HoopTraceMotionTheme.light(),
    ],
  );
}
