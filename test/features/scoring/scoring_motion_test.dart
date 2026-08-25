import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/motion/scoring_motion.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:lottie/lottie.dart';

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

  test('geometry midpoint is deterministic for top and side arcs', () {
    final top = ScoringMotionPath.build(
      source: const Offset(100, 300),
      destination: const Offset(300, 100),
      safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
    );
    expect(top.control1.dx, 100);
    expect(top.control1.dy, closeTo(237.77460, .00001));
    expect(top.control2.dx, 300);
    expect(top.control2.dy, closeTo(37.77460, .00001));
    expect(top.sample(.5).position.dx, closeTo(182.73, .01));
    expect(top.sample(.5).position.dy, closeTo(171.23, .01));

    final side = ScoringMotionPath.build(
      source: const Offset(20, 100),
      destination: const Offset(100, 120),
      safeWorkspace: const Rect.fromLTWH(0, 80, 120, 120),
    );
    expect(side.control1, const Offset(76, 100));
    expect(side.control2, const Offset(120, 120));
    expect(side.sample(.5).position.dx, closeTo(66.88, .01));
    expect(side.sample(.5).position.dy, closeTo(104.54, .01));
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
      coordinator.advance(const Duration(seconds: 10));
      expect(completed, [
        'event-0',
        'event-1',
        'event-2',
        'event-3',
        'event-4',
      ]);
      coordinator.dispose();
    },
  );

  test('completion callback submission preserves an existing FIFO queue', () {
    final completed = <String>[];
    late ScoringMotionCoordinator coordinator;
    coordinator = ScoringMotionCoordinator(
      onComplete: (event) {
        completed.add(event.id);
        if (event.id == 'event-0') {
          coordinator.submit(
            ScoringMotionEvent(
              receipt: receipt('reentrant'),
              sourceButton: const Offset(20, 20),
              courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
              safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
            ),
          );
        }
      },
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
    coordinator.advance(const Duration(seconds: 10));
    expect(completed, ['event-0', 'event-1', 'event-2', 'event-reentrant']);
    coordinator.dispose();
  });

  test('completion callback may dispose without restarting or notifying', () {
    late ScoringMotionCoordinator coordinator;
    coordinator = ScoringMotionCoordinator(
      onComplete: (_) => coordinator.dispose(),
    );
    coordinator.submit(
      ScoringMotionEvent(
        receipt: receipt('dispose-callback'),
        sourceButton: const Offset(20, 20),
        courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
        safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
      ),
    );
    expect(
      () => coordinator.advance(const Duration(seconds: 2)),
      returnsNormally,
    );
    expect(coordinator.pendingCount, 0);
  });

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

  test(
    'reduced mode performs a bounded color reveal while disabled is immediate',
    () {
      final reducedCompleted = <String>[];
      final reduced = ScoringMotionCoordinator(
        mode: ScoringMotionMode.reduced,
        onComplete: (event) => reducedCompleted.add(event.id),
      );
      reduced.submit(
        ScoringMotionEvent(
          receipt: receipt('reduced'),
          sourceButton: const Offset(20, 20),
          courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
          safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
        ),
      );
      expect(reduced.active, isNotNull);
      expect(reduced.active!.isColorReveal, isTrue);
      expect(reduced.active!.travelEnabled, isFalse);
      expect(reduced.active!.trailEnabled, isFalse);
      expect(reduced.active!.colorRevealProgress, 0);
      reduced.advance(const Duration(milliseconds: 99));
      expect(reduced.active, isNotNull);
      expect(reduced.active!.colorRevealProgress, closeTo(.99, .001));
      expect(reducedCompleted, isEmpty);
      reduced.advance(const Duration(milliseconds: 1));
      expect(reducedCompleted, ['event-reduced']);
      reduced.dispose();

      final disabledCompleted = <String>[];
      final disabled = ScoringMotionCoordinator(
        mode: ScoringMotionMode.disabled,
        onComplete: (event) => disabledCompleted.add(event.id),
      );
      disabled.submit(
        ScoringMotionEvent(
          receipt: receipt('disabled'),
          sourceButton: const Offset(20, 20),
          courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
          safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
        ),
      );
      expect(disabledCompleted, ['event-disabled']);
      expect(disabled.active, isNull);
      disabled.dispose();
    },
  );

  test('queued location cancellation removes its event timing entry', () {
    final coordinator = ScoringMotionCoordinator();
    for (var i = 0; i < 4; i++) {
      coordinator.submit(
        ScoringMotionEvent(
          receipt: receipt('$i'),
          sourceButton: const Offset(20, 20),
          courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
          safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
        ),
      );
    }
    expect(coordinator.cancelByLocationId('location-2'), isTrue);
    coordinator.advance(const Duration(milliseconds: 760));
    expect(coordinator.active!.event.id, 'event-1');
    coordinator.advance(const Duration(milliseconds: 440));
    expect(coordinator.active!.event.id, 'event-3');
    expect(
      coordinator.active!.timing.flight,
      const Duration(milliseconds: 300),
    );
    coordinator.dispose();
  });

  test('runtime asset failure reveals and advances the queued motion', () {
    final completed = <String>[];
    final fallback = <String>[];
    final coordinator = ScoringMotionCoordinator(
      onComplete: (event) => completed.add(event.id),
      onFallback: (event) => fallback.add(event.id),
    );
    for (var i = 0; i < 2; i++) {
      coordinator.submit(
        ScoringMotionEvent(
          receipt: receipt('runtime-$i'),
          sourceButton: const Offset(20, 20),
          courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
          safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
        ),
      );
    }
    expect(coordinator.fail('event-runtime-0'), isTrue);
    expect(fallback, ['event-runtime-0']);
    expect(completed, ['event-runtime-0']);
    expect(coordinator.active!.event.id, 'event-runtime-1');
    coordinator.dispose();
  });

  testWidgets('overlay requests team-colored ball and splash assets by phase', (
    tester,
  ) async {
    final assets = <String>[];
    final colors = <Color>[];
    final coordinator = ScoringMotionCoordinator();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: ScoringMotionOverlay(
          coordinator: coordinator,
          assetBuilder: (context, active, color) {
            assets.add(active.assetName);
            colors.add(color);
            return ColoredBox(color: color);
          },
        ),
      ),
    );
    coordinator.submit(
      ScoringMotionEvent(
        receipt: receipt('assets'),
        sourceButton: const Offset(20, 20),
        courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
        safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
      ),
    );
    await tester.pump();
    expect(assets.last, 'assets/animations/paint_ball.json');
    expect(
      colors.last,
      teamColorForScheme(TeamSide.blue, buildHoopTraceTheme().colorScheme),
    );
    coordinator.advance(const Duration(milliseconds: 520));
    await tester.pump();
    expect(assets.last, 'assets/animations/paint_splash.json');
    expect(
      colors.last,
      teamColorForScheme(TeamSide.blue, buildHoopTraceTheme().colorScheme),
    );
    coordinator.dispose();
  });

  testWidgets('default overlay uses offline Lottie assets', (tester) async {
    final coordinator = ScoringMotionCoordinator();
    await tester.pumpWidget(
      MaterialApp(home: ScoringMotionOverlay(coordinator: coordinator)),
    );
    coordinator.submit(
      ScoringMotionEvent(
        receipt: receipt('default-assets'),
        sourceButton: const Offset(20, 20),
        courtBounds: const Rect.fromLTWH(0, 0, 400, 400),
        safeWorkspace: const Rect.fromLTWH(0, 0, 400, 400),
      ),
    );
    await tester.pump();
    expect(find.byType(LottieBuilder), findsOneWidget);
    coordinator.dispose();
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
