import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/design_system/design_system.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';

void main() {
  testWidgets('court marker selection synchronizes the editorial event rail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = _controller();

    await tester.pumpWidget(
      MaterialApp(home: ReplayPage(controller: controller)),
    );

    expect(find.byType(EditorialScaffold), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('replay-court-pane'))).width,
      greaterThan(
        tester.getSize(find.byKey(const Key('replay-timeline-pane'))).width,
      ),
    );

    await tester.tap(find.byKey(const Key('replay-court-marker-event-1')));
    await tester.pump();

    expect(controller.selectedEventId, 'event-1');
    final court = tester.widget<CourtView>(find.byType(CourtView));
    expect(court.highlightedShotLocationId, 'location-1');
    final semantics = tester.getSemantics(
      find.byKey(const Key('replay-event-event-1')),
    );
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
  });

  testWidgets('editorial replay remains usable in dark mode at 200 percent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: ReplayPage(controller: _controller()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(EditorialScaffold), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const Key('replay-kind-all'))).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('replay audit opens in the frozen editorial sheet', (
    tester,
  ) async {
    final base = _controller();
    final controller = ReplayController(
      data: base.data,
      loadAuditLogs: () async => [],
    );
    await tester.pumpWidget(
      MaterialApp(home: ReplayPage(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('replay-audit-history')));
    await tester.pumpAndSettle();

    expect(find.byType(EditorialSheet), findsOneWidget);
  });

  testWidgets('replay edit opens in the frozen editorial sheet', (
    tester,
  ) async {
    final base = _controller();
    final controller = ReplayController(
      data: base.data,
      onUpdateEventNote: (_, _, _) async {},
    )..setEditing(true);
    await tester.pumpWidget(
      MaterialApp(home: ReplayPage(controller: controller)),
    );

    await tester.ensureVisible(find.byKey(const Key('replay-event-event-1')));
    await tester.tap(find.byKey(const Key('replay-event-event-1')));
    await tester.pumpAndSettle();

    expect(find.byType(EditorialSheet), findsOneWidget);
  });
}

ReplayController _controller() => ReplayController(
  data: ReplayMatchData(
    matchId: 'editorial-replay',
    redName: 'Red',
    blueName: 'Blue',
    redScore: 2,
    blueScore: 0,
    duration: const Duration(seconds: 12),
    events: [
      ReplayEventData(
        id: 'event-1',
        kind: ReplayEventKind.score,
        side: TeamSide.red,
        points: 2,
        elapsed: const Duration(seconds: 12),
        shotPoint: CourtPoint(x: 0.32, y: 0.64),
        locationId: 'location-1',
      ),
    ],
  ),
);
