import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/pending_location_bar.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

import '../../test_helpers/test_database.dart';

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

  testWidgets('compact header accommodates long player names', (tester) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ScoringController(
      setup: const MatchSetup(
        matchId: 'compact-header',
        redName: '集成测试红方长名称',
        blueName: '集成测试蓝方长名称',
        ruleTemplateId: 'free',
        targetScore: null,
        timerEnabled: false,
        timeLimitMinutes: 10,
        winByTwo: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ScoringPage(controller: controller, onOpenReplay: () {}),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('集成测试蓝方长名称 0'), findsOneWidget);
    expect(find.text('0 集成测试红方长名称'), findsOneWidget);
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

  testWidgets('replay entry opens only after pending location is resolved', (
    tester,
  ) async {
    var openCount = 0;
    final controller = ScoringController(matchId: 'match-1');

    await tester.pumpWidget(
      MaterialApp(
        home: ScoringPage(
          controller: controller,
          onOpenReplay: () => openCount++,
        ),
      ),
    );

    await tester.tap(find.text(scoringReplayText));
    expect(openCount, 1);

    await tester.tap(find.byKey(const Key('red-score-1')));
    await tester.pump();
    await tester.tap(find.text(scoringMarkText));
    await tester.pump();
    await tester.tap(find.text(scoringReplayText));
    await tester.pump();

    expect(openCount, 1);
    expect(find.text(scoringResolvePendingText), findsOneWidget);
  });

  testWidgets('command-backed pending undo awaits soft-delete command', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final command = StartMatchCommand(
        commandId: 'page-undo-start-command',
        matchId: 'page-undo-match',
        redName: 'Red',
        blueName: 'Blue',
        ruleTemplate: const RuleTemplate(
          id: 'free',
          name: 'Free',
          scoreButtons: [1, 2, 3],
        ),
        createdAt: DateTime.utc(2026, 8, 23, 9),
        startedAt: DateTime.utc(2026, 8, 23, 9),
      );
      final projection = await service.start(command);
      final controller = ScoringController.fromCommittedProjection(
        projection,
        service,
      );

      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
      await tester.pump();
      expect(find.text(undoText), findsOneWidget);

      await tester.tap(find.text(undoText));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );

      final event = await database.select(database.matchEvents).getSingle();
      expect(event.isDeleted, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });

  testWidgets('retryable confirm failure offers retry and commits location', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await withTestDatabase((database) async {
      var beforeCommitCalls = 0;
      final service = MatchCommandService(
        database,
        failureInjector: (point) {
          if (point == MatchCommandFailurePoint.beforeCommit &&
              beforeCommitCalls++ == 2) {
            throw StateError('confirm failed once');
          }
        },
      );
      final start = await service.start(
        StartMatchCommand(
          commandId: 'page-retry-start-command',
          matchId: 'page-retry-match',
          redName: 'Red',
          blueName: 'Blue',
          ruleTemplate: const RuleTemplate(
            id: 'free',
            name: 'Free',
            scoreButtons: [1, 2, 3],
          ),
          createdAt: DateTime.utc(2026, 8, 23, 9),
          startedAt: DateTime.utc(2026, 8, 23, 9),
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );

      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-location')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();

      expect(find.text('重试'), findsOneWidget);
      expect(controller.state.pendingLocation, isNotNull);
      final retryAction = tester.widget<SnackBarAction>(
        find.byType(SnackBarAction),
      );
      retryAction.onPressed();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();

      expect(controller.state.pendingLocation, isNull);
      expect(await database.select(database.shotLocations).get(), hasLength(1));
    });
  });
}
