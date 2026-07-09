import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

void main() {
  testWidgets('scoring page shows court-first landscape controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ScoringPage(matchId: 'match-1')),
    );

    expect(find.text('蓝方'), findsOneWidget);
    expect(find.text('红方'), findsOneWidget);
    expect(find.text('+1'), findsNWidgets(2));
    expect(find.text('+2'), findsNWidgets(2));
    expect(find.text('+3'), findsNWidgets(2));
    expect(find.byType(CustomPaint), findsWidgets);
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
    await tester.tap(find.byKey(const Key('confirm-location')));
    await tester.pump();

    expect(controller.state.score.blueScore, 3);
    expect(controller.state.pendingLocation, isNull);
    expect(controller.state.shotLocations.single.side, TeamSide.blue);
    expect(controller.state.shotLocations.single.isLocked, isTrue);
  });
}
