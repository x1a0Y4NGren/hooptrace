import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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

typedef HoopTraceMotionTokens = HoopTraceMotionTheme;
