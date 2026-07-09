import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/pending_location_bar.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

void main() {
  testWidgets('scoring page shows court-first landscape controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ScoringPage(matchId: 'match-1')),
    );

    expect(find.text('蓝方'), findsOneWidget);
    expect(find.text('红方'), findsOneWidget);
    expect(find.text('犯规 0'), findsNWidgets(2));
    expect(find.text('犯规'), findsNWidgets(2));
    expect(find.text('+1'), findsNWidgets(2));
    expect(find.text('+2'), findsNWidgets(2));
    expect(find.text('+3'), findsNWidgets(2));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('scoring page does not overflow on emulator landscape size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: ScoringPage(matchId: 'match-1')),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(foulText), findsNWidgets(2));
  });

  testWidgets('scoring page does not overflow while pending bar is visible', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ScoringController(matchId: 'match-1')
      ..addScore(side: TeamSide.red, points: 2);

    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(confirmLocationText), findsOneWidget);
  });

  testWidgets('pending location controls do not resize the court', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1095, 616));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ScoringController(matchId: 'match-1');

    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );
    final sizeBeforePending = tester.getSize(find.byType(CourtView));

    controller.addScore(side: TeamSide.red, points: 2);
    await tester.pump();
    final sizeWithPending = tester.getSize(find.byType(CourtView));

    expect(sizeWithPending, sizeBeforePending);
    expect(find.text(confirmLocationText), findsOneWidget);
  });

  testWidgets('choosing not to mark a shot records score immediately', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'match-1');

    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('red-score-2')));
    await tester.pump();
    expect(find.text('标记投篮位置？'), findsOneWidget);
    expect(find.text('可在球场上点选或拖动圆点后确认。'), findsOneWidget);
    await tester.tap(find.text('不标记'));
    await tester.pump();

    expect(controller.state.score.redScore, 2);
    expect(controller.state.pendingLocation, isNull);
    expect(controller.state.shotLocations, isEmpty);
  });

  testWidgets('confirming a pending marker records a locked location', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'match-1');

    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('blue-score-3')));
    await tester.pump();
    await tester.tap(find.text('标记'));
    await tester.pump();
    expect(find.text('确认落点'), findsOneWidget);
    expect(find.text('跳过落点'), findsOneWidget);
    expect(find.text('撤销'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-location')));
    await tester.pump();

    expect(controller.state.score.blueScore, 3);
    expect(controller.state.pendingLocation, isNull);
    expect(controller.state.shotLocations.single.side, TeamSide.blue);
    expect(controller.state.shotLocations.single.isLocked, isTrue);
  });

  testWidgets('tapping score while pending shows a resolve prompt', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'match-1');

    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('red-score-2')));
    await tester.pump();
    await tester.tap(find.text(scoringMarkText));
    await tester.pump();
    await tester.tap(find.byKey(const Key('blue-score-3')));
    await tester.pump();

    expect(find.text(scoringResolvePendingText), findsOneWidget);
    expect(controller.state.score.redScore, 2);
    expect(controller.state.score.blueScore, 0);
  });

  testWidgets('scoring page swaps injected controllers when rebuilt', (
    tester,
  ) async {
    final first = ScoringController(matchId: 'match-1');
    final second = ScoringController(matchId: 'match-2');

    await tester.pumpWidget(MaterialApp(home: ScoringPage(controller: first)));
    await tester.pumpWidget(MaterialApp(home: ScoringPage(controller: second)));

    await tester.tap(find.byKey(const Key('red-score-1')));
    await tester.pump();

    expect(first.state.events, isEmpty);
    expect(second.state.score.redScore, 1);
  });
}
