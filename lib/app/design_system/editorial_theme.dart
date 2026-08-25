import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:hooptrace/app/design_system/editorial_tokens.dart';

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

typedef HoopTraceVisualTokens = HoopTraceVisualTheme;
