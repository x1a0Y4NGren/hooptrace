import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/motion/scoring_motion.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

ShotLocationCommitReceipt receipt(String id, {double x = .5, double y = .5}) {
  return ShotLocationCommitReceipt(
    eventId: 'event-$id',
    shotLocationId: 'location-$id',
    side: TeamSide.blue,
    points: 2,
    point: CourtPoint(x: x, y: y),
    source: ShotLocationCommitSource.courtFirst,
  );
}

void main() {
  test('motion theme exposes standard and accelerated timings', () {
    final light = const HoopTraceMotionTheme.light();
    final dark = const HoopTraceMotionTheme.dark();
    expect(light.scoreFlight, const Duration(milliseconds: 520));
    expect(light.impact, const Duration(milliseconds: 240));
    expect(light.acceleratedScoreFlight, const Duration(milliseconds: 300));
    expect(light.acceleratedImpact, const Duration(milliseconds: 140));
    expect(dark.acceleratedScoreFlight, light.acceleratedScoreFlight);
    expect(light, light.copyWith());
    expect(light.hashCode, light.copyWith().hashCode);
    expect(
      light
          .copyWith(acceleratedImpact: const Duration(seconds: 1))
          .acceleratedImpact,
      const Duration(seconds: 1),
    );
    expect(
      light
          .lerp(
            light.copyWith(acceleratedImpact: const Duration(seconds: 1)),
            .5,
          )
          .acceleratedImpact,
      const Duration(milliseconds: 570),
    );
  });

  test('cubic geometry samples exact endpoints and bounded controls', () {
    final path = ScoringMotionPath.build(
      source: const Offset(80, 520),
      destination: const Offset(680, 180),
      safeWorkspace: const Rect.fromLTWH(24, 24, 712, 520),
    );
    expect(
      (path.sample(0).position - const Offset(80, 520)).distance,
      lessThanOrEqualTo(1),
    );
    expect(path.sample(.5).position.dx.isFinite, isTrue);
    expect(
      (path.sample(1).position - const Offset(680, 180)).distance,
      lessThanOrEqualTo(1),
    );
    for (final point in [path.control1, path.control2]) {
      expect(path.safeWorkspace.contains(point), isTrue);
    }
    final sample = path.sample(1);
    expect(sample.trail.length, lessThanOrEqualTo(12));
    for (var i = 1; i < sample.trail.length; i++) {
      expect(
        sample.trail[i].opacity,
        lessThanOrEqualTo(sample.trail[i - 1].opacity),
      );
    }
    expect(sample.tangent.vector.distance.isFinite, isTrue);
  });

  test(
    'coordinator preserves FIFO order and accelerates after backlog three',
    () {
      final completed = <String>[];
      final coordinator = ScoringMotionCoordinator(
        motionTheme: const HoopTraceMotionTheme.light(),
        onComplete: (event) => completed.add(event.receipt.eventId),
      );
      for (var i = 0; i < 5; i++) {
        coordinator.submit(
          ScoringMotionEvent(
            receipt: receipt('$i'),
            sourceButton: const Offset(20, 20),
            courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
            safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
          ),
        );
      }
      expect(coordinator.pendingCount, 5);
      expect(coordinator.queuedEvents.map((event) => event.receipt.eventId), [
        'event-1',
        'event-2',
        'event-3',
        'event-4',
      ]);
      expect(
        coordinator.active!.timing.flight,
        const Duration(milliseconds: 520),
      );
      coordinator.advance(const Duration(milliseconds: 760));
      expect(
        coordinator.active!.timing.flight,
        const Duration(milliseconds: 300),
      );
      coordinator.advance(const Duration(milliseconds: 440));
      expect(completed, ['event-0', 'event-1']);
      coordinator.dispose();
    },
  );

  test('cancels active and queued events and dispose clears safely', () {
    final completed = <String>[];
    final coordinator = ScoringMotionCoordinator(
      onComplete: (event) => completed.add(event.id),
    );
    for (var i = 0; i < 3; i++) {
      coordinator.submit(
        ScoringMotionEvent(
          receipt: receipt('$i'),
          sourceButton: const Offset(20, 20),
          courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
          safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
        ),
      );
    }
    expect(coordinator.cancelByLocationId('location-0'), isTrue);
    expect(coordinator.cancelByEventId('event-2'), isTrue);
    expect(coordinator.pendingCount, 1);
    coordinator.dispose();
    coordinator.advance(const Duration(seconds: 5));
    expect(completed, isEmpty);
    expect(coordinator.pendingCount, 0);
  });

  test('reduced and disabled modes reveal immediately without travel', () {
    for (final mode in [
      ScoringMotionMode.reduced,
      ScoringMotionMode.disabled,
    ]) {
      final completed = <String>[];
      final coordinator = ScoringMotionCoordinator(
        mode: mode,
        onComplete: (event) => completed.add(event.id),
      );
      coordinator.submit(
        ScoringMotionEvent(
          receipt: receipt('instant-$mode'),
          sourceButton: const Offset(20, 20),
          courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
          safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
        ),
      );
      expect(completed, ['event-instant-$mode']);
      expect(coordinator.active, isNull);
      expect(coordinator.pendingCount, 0);
      coordinator.dispose();
    }
  });

  test(
    'receipt point maps to court overlay and asset failure reveals immediately',
    () {
      final event = ScoringMotionEvent(
        receipt: receipt('fallback', x: .25, y: .75),
        sourceButtonCoordinate: const Offset(20, 30),
        courtBounds: const Rect.fromLTWH(100, 200, 400, 200),
        safeWorkspace: const Rect.fromLTWH(0, 0, 600, 500),
        assetAvailable: false,
      );
      expect(event.sourceButton, const Offset(20, 30));
      expect(event.destination, const Offset(200, 350));
      final completed = <String>[];
      final fallbacks = <String>[];
      final coordinator = ScoringMotionCoordinator(
        onComplete: (item) => completed.add(item.id),
        onFallback: (item) => fallbacks.add(item.id),
      );
      coordinator.submit(event);
      expect(fallbacks, ['event-fallback']);
      expect(completed, ['event-fallback']);
      coordinator.dispose();
    },
  );

  testWidgets('overlay is a repaint-boundary custom painter primitive', (
    tester,
  ) async {
    final coordinator = ScoringMotionCoordinator();
    await tester.pumpWidget(
      MaterialApp(home: ScoringMotionOverlay(coordinator: coordinator)),
    );
    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is ScoringMotionPainter,
      ),
      findsOneWidget,
    );
    coordinator.dispose();
  });
}
