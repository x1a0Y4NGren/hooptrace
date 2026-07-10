import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';

void main() {
  ReplayController buildController() {
    return ReplayController(
      data: ReplayMatchData(
        matchId: 'match-1',
        redName: '赤焰',
        blueName: '海浪',
        redScore: 11,
        blueScore: 9,
        duration: const Duration(minutes: 13, seconds: 5),
        events: [
          ReplayEventData(
            id: 'event-1',
            kind: ReplayEventKind.score,
            side: TeamSide.red,
            points: 2,
            elapsed: const Duration(seconds: 15),
            shotPoint: CourtPoint(x: 0.3, y: 0.7),
          ),
          const ReplayEventData(
            id: 'event-2',
            kind: ReplayEventKind.foul,
            side: TeamSide.blue,
            elapsed: Duration(minutes: 1, seconds: 2),
            note: '防守犯规',
          ),
        ],
      ),
    );
  }

  testWidgets('renders score, locked court, overview and filterable timeline', (
    tester,
  ) async {
    final controller = buildController();
    await tester.pumpWidget(
      MaterialApp(home: ReplayPage(controller: controller)),
    );

    expect(find.text('赤焰'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('海浪'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('总览'), findsOneWidget);
    expect(find.text('事件时间线'), findsOneWidget);
    expect(find.byKey(const Key('replay-event-event-1')), findsOneWidget);
    expect(find.byKey(const Key('replay-event-event-2')), findsOneWidget);

    final court = tester.widget<CourtView>(find.byType(CourtView));
    expect(court.mode, CourtViewMode.readOnly);
    expect(court.pendingLocation, isNull);
    expect(court.onPendingLocationChanged, isNull);

    await tester.ensureVisible(find.byKey(const Key('replay-kind-fouls')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('replay-kind-fouls')));
    await tester.pump();
    expect(find.byKey(const Key('replay-event-event-1')), findsNothing);
    expect(find.byKey(const Key('replay-event-event-2')), findsOneWidget);
  });

  testWidgets('shows finish action only when callback is provided', (
    tester,
  ) async {
    var finishCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReplayPage(
          controller: buildController(),
          onFinishMatch: () async => finishCalls++,
        ),
      ),
    );

    final finishButton = find.byKey(const Key('replay-finish-match'));
    expect(finishButton, findsOneWidget);
    expect(tester.getSize(finishButton).height, greaterThanOrEqualTo(48));
    await tester.tap(finishButton);
    await tester.pump();
    expect(finishCalls, 1);

    await tester.pumpWidget(
      MaterialApp(home: ReplayPage(controller: buildController())),
    );
    expect(find.byKey(const Key('replay-finish-match')), findsNothing);
  });

  testWidgets('adapts to portrait and landscape without overflow', (
    tester,
  ) async {
    for (final size in [
      const Size(390, 844),
      const Size(640, 360),
      const Size(1000, 700),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(home: ReplayPage(controller: buildController())),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('replay-kind-all'))).height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.binding.setSurfaceSize(null);
  });
}
