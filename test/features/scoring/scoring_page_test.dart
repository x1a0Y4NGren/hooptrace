import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
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

  testWidgets('timer-disabled scoring hides clock commands and ticks', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(
        _startPageCommand('page-no-timer', timerEnabled: false),
      );
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            clockTick: const Duration(milliseconds: 10),
          ),
        ),
      );

      expect(controller.state.timerEnabled, isFalse);
      expect(find.text('无计时'), findsOneWidget);
      expect(find.byKey(const Key('command-pause')), findsNothing);
      expect(find.byKey(const Key('command-resume')), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('无计时'), findsOneWidget);
    });
  });

  testWidgets('compact score controls and court remain in the first viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: ScoringPage(matchId: 'compact-first-viewport')),
    );

    for (final key in <String>[
      'blue-score-1',
      'blue-score-2',
      'blue-score-3',
      'blue-foul',
      'red-score-1',
      'red-score-2',
      'red-score-3',
      'red-foul',
    ]) {
      final rect = tester.getRect(find.byKey(Key(key)));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(411));
      expect(rect.height, greaterThanOrEqualTo(48));
    }
    expect(find.text('蓝方 0'), findsOneWidget);
    expect(find.text('0 红方'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('scoring-court'))).height,
      greaterThanOrEqualTo(100),
    );
  });

  testWidgets(
    'compact detailed draft replaces command dock and preserves court',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(731, 411));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ScoringController(
        setup: const MatchSetup(
          matchId: 'compact-detailed',
          redName: '红方',
          blueName: '蓝方',
          ruleTemplateId: 'free',
          targetScore: null,
          timerEnabled: false,
          timeLimitMinutes: 10,
          winByTwo: false,
          recordingMode: RecordingMode.detailed,
          trackingCoverage: TrackingCoverage.locations,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.pump();

      expect(controller.detailedShotDraft, isNotNull);
      expect(find.byKey(const Key('detailed-draft-dock')), findsOneWidget);
      expect(find.byKey(const Key('scoring-command-dock')), findsNothing);
      expect(find.byKey(const Key('draft-cancel')), findsOneWidget);
      expect(find.byKey(const Key('draft-commit')), findsOneWidget);
      expect(find.text('蓝方 0'), findsOneWidget);
      expect(find.text('0 红方'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('scoring-court'))).height,
        greaterThanOrEqualTo(100),
      );
      for (final key in <String>['draft-cancel', 'draft-commit']) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(411));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
    },
  );

  testWidgets('pending location uses a bottom dock outside the court', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(_startPageCommand('page-pending-dock'));
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
      expect(controller.beginLocateLastUnlocatedShot(), isTrue);
      await tester.pump();

      expect(find.byKey(const Key('pending-location-dock')), findsOneWidget);
      expect(find.byKey(const Key('scoring-command-dock')), findsNothing);
      expect(find.text('取消定位'), findsOneWidget);
      final court = tester.getRect(find.byKey(const Key('scoring-court')));
      final dock = tester.getRect(
        find.byKey(const Key('pending-location-dock')),
      );
      expect(court.overlaps(dock), isFalse);
    });
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
    controller.addScore(side: TeamSide.red, points: 2);
    await tester.pump();
    final sizeWithPending = tester.getSize(find.byType(CourtView));

    expect(sizeWithPending.height, greaterThan(0));
    expect(find.byKey(const Key('pending-location-dock')), findsOneWidget);
    expect(find.text(confirmLocationText), findsOneWidget);
  });

  testWidgets('choosing not to mark a shot records score immediately', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final anchor = DateTime.utc(2026, 8, 23, 9);
      final service = MatchCommandService(database, now: () => anchor);
      final start = await service.start(
        StartMatchCommand(
          commandId: 'page-one-tap-start',
          matchId: 'page-one-tap-match',
          redName: 'Red',
          blueName: 'Blue',
          ruleTemplate: const RuleTemplate(
            id: 'free',
            name: 'Free',
            scoreButtons: [1, 2, 3],
          ),
          recordingMode: RecordingMode.simple,
          trackingCoverage: TrackingCoverage.locations,
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

      await tester.tap(find.byKey(const Key('red-score-2')));
      await tester.pump();

      expect(find.text(scoringMarkShotDialogTitle), findsNothing);
      expect(controller.state.score.redScore, 2);
      expect(controller.state.pendingLocation, isNull);
      expect(await database.select(database.matchEvents).get(), hasLength(1));
    });
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
    expect(find.text('确认落点'), findsOneWidget);
    expect(find.text('取消定位'), findsOneWidget);
    expect(find.byKey(const Key('pending-location-undo')), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('blue-score-3')));
    await tester.pump();

    expect(find.text(scoringResolvePendingText), findsOneWidget);
    expect(controller.state.score.redScore, 2);
    expect(controller.state.score.blueScore, 0);
  });

  testWidgets(
    'rapid command-backed scores commit in tap order without a modal',
    (tester) async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final start = await service.start(_startPageCommand('page-rapid'));
        final controller = ScoringController.fromCommittedProjection(
          start,
          service,
        );
        await tester.pumpWidget(
          MaterialApp(home: ScoringPage(controller: controller)),
        );

        await tester.tap(find.byKey(const Key('blue-score-1')));
        await tester.tap(find.byKey(const Key('red-score-2')));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );

        final events = await database.select(database.matchEvents).get();
        expect(find.text(scoringMarkShotDialogTitle), findsNothing);
        expect(events.map((event) => event.points), [1, 2]);
        expect(controller.state.score.blueScore, 1);
        expect(controller.state.score.redScore, 2);
      });
    },
  );

  testWidgets('explicit locate action confirms or cancels the latest shot', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(_startPageCommand('page-locate'));
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );

      await tester.tap(find.byKey(const Key('red-score-2')));
      await tester.pump();
      expect(find.byKey(const Key('command-locate')), findsOneWidget);
      await tester.tap(find.byKey(const Key('command-locate')));
      await tester.pump();
      expect(find.text(confirmLocationText), findsOneWidget);
      expect(find.byKey(const Key('scoring-court')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm-location')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      expect(controller.state.pendingLocation, isNull);
      expect(await database.select(database.shotLocations).get(), hasLength(1));

      await controller.recordScoreCommitted(side: TeamSide.blue, points: 1);
      await tester.pump();
      await tester.tap(find.byKey(const Key('command-locate')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cancel-location')));
      await tester.pump();
      expect(controller.state.pendingLocation, isNull);
      expect(await database.select(database.shotLocations).get(), hasLength(1));
    });
  });

  testWidgets('detailed mode is court-first and commits corrected draft once', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(
        _startPageCommand(
          'page-detailed',
          recordingMode: RecordingMode.detailed,
        ),
      );
      final withPossession = await service.record(
        RecordMatchEventCommand(
          matchId: start.match.id,
          type: EventKind.possession,
          side: TeamSide.blue,
          points: 0,
          occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        withPossession,
        service,
      );
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );

      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('blue-score-2')))
            .onPressed,
        isNull,
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.pump();
      expect(controller.detailedShotDraft, isNotNull);
      expect(find.byKey(const Key('detailed-draft-dock')), findsOneWidget);
      expect(find.byKey(const Key('draft-shooter-blue')), findsOneWidget);

      await tester.tap(find.byKey(const Key('draft-shooter-red')));
      await tester.tap(find.byKey(const Key('draft-points-2')));
      await tester.tap(find.byKey(const Key('draft-commit')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );

      final events = await database.select(database.matchEvents).get();
      final locations = await database.select(database.shotLocations).get();
      expect(controller.detailedShotDraft, isNull);
      expect(events, hasLength(2));
      expect(events.last.side, TeamSide.red.name);
      expect(events.last.points, 2);
      expect(events.last.outcome, ShotOutcome.made.name);
      expect(locations, hasLength(1));
      expect(locations.single.eventId, events.last.id);
    });
  });

  testWidgets(
    'detailed draft cancel leaves the committed projection untouched',
    (tester) async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final start = await service.start(
          _startPageCommand(
            'page-detailed-cancel',
            recordingMode: RecordingMode.detailed,
          ),
        );
        final controller = ScoringController.fromCommittedProjection(
          start,
          service,
        );
        await tester.pumpWidget(
          MaterialApp(home: ScoringPage(controller: controller)),
        );
        await tester.tapAt(
          tester.getCenter(find.byKey(const Key('scoring-court'))),
        );
        await tester.pump();
        await tester.tap(find.byKey(const Key('draft-cancel')));
        await tester.pump();

        expect(controller.detailedShotDraft, isNull);
        expect(controller.state.events, isEmpty);
        expect(await database.select(database.matchEvents).get(), isEmpty);
        expect(await database.select(database.shotLocations).get(), isEmpty);
      });
    },
  );

  testWidgets('command dock records possession, free throw, and pause', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final anchor = DateTime.utc(2026, 8, 23, 9);
      final service = MatchCommandService(database, now: () => anchor);
      final start = await service.start(
        _startPageCommand(
          'page-command-dock',
          timerEnabled: true,
          clockMode: ClockMode.countUp,
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            clockNowUtc: () => anchor.add(const Duration(seconds: 1)),
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('command-possession-blue')),
        300,
        scrollable: find.descendant(
          of: find.byKey(const Key('scoring-command-dock')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('command-possession-blue')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('command-free-throw-blue-made')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('command-pause')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      await tester.pump();

      final events = await database.select(database.matchEvents).get();
      expect(
        events.map((event) => event.type),
        containsAll(<String>[
          EventKind.possession.name,
          EventKind.freeThrow.name,
          EventKind.pause.name,
        ]),
      );
      expect(controller.currentPossession, TeamSide.blue);
      expect(find.text('计时已暂停'), findsNWidgets(2));
    });
  });

  testWidgets('compact command workspace keeps primary targets at 48dp', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(home: ScoringPage(matchId: 'compact-actions')),
    );

    for (final key in <String>[
      'blue-score-1',
      'blue-score-2',
      'blue-score-3',
      'blue-foul',
      'red-score-1',
      'red-score-2',
      'red-score-3',
      'red-foul',
      'command-undo',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(find.byKey(const Key('command-pause')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'compact scoring keeps primary controls above the command dock with insets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(731, 411));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const insets = EdgeInsets.only(top: 24, bottom: 24);
      final controller = ScoringController(
        setup: const MatchSetup(
          matchId: 'compact-insets',
          redName: '红方',
          blueName: '蓝方',
          ruleTemplateId: 'free',
          targetScore: null,
          timerEnabled: false,
          timeLimitMinutes: 10,
          winByTwo: false,
          recordingMode: RecordingMode.simple,
          trackingCoverage: TrackingCoverage.locations,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(731, 411),
              padding: insets,
              viewPadding: insets,
            ),
            child: ScoringPage(controller: controller),
          ),
        ),
      );

      final dock = tester.getRect(
        find.byKey(const Key('scoring-command-dock')),
      );
      final safeTop = insets.top;
      final safeBottom = 411 - insets.bottom;
      expect(dock.bottom, lessThanOrEqualTo(safeBottom));
      for (final key in <String>[
        'blue-score-1',
        'blue-score-2',
        'blue-score-3',
        'blue-foul',
        'red-score-1',
        'red-score-2',
        'red-score-3',
        'red-foul',
      ]) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.top, greaterThanOrEqualTo(safeTop));
        expect(rect.bottom, lessThanOrEqualTo(safeBottom));
        expect(rect.height, greaterThanOrEqualTo(48));
        expect(rect.overlaps(dock), isFalse, reason: key);
      }
      expect(
        tester.getSize(find.byKey(const Key('scoring-court'))).height,
        greaterThanOrEqualTo(100),
      );
      expect(find.byKey(const Key('blue-miss')), findsOneWidget);
      expect(find.byKey(const Key('red-miss')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('clock display projects elapsed time without database ticks', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final anchor = DateTime.utc(2026, 8, 23, 9);
      final service = MatchCommandService(database, now: () => anchor);
      final start = await service.start(
        _startPageCommand(
          'page-clock',
          timerEnabled: true,
          clockMode: ClockMode.countUp,
          createdAt: anchor,
          startedAt: anchor,
        ),
      );
      var now = anchor.add(const Duration(seconds: 2));
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(controller: controller, clockNowUtc: () => now),
        ),
      );
      expect(find.text('00:02'), findsOneWidget);
      now = anchor.add(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:05'), findsOneWidget);
    });
  });

  testWidgets('clock display announces overtime from committed projection', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final anchor = DateTime.utc(2026, 8, 23, 9);
      final service = MatchCommandService(database, now: () => anchor);
      await service.start(
        _startPageCommand(
          'page-overtime',
          timerEnabled: true,
          clockMode: ClockMode.countdown,
          regulationSeconds: 60,
          createdAt: anchor,
          startedAt: anchor,
        ),
      );
      await MatchCommandService(
        database,
        now: () => anchor.add(const Duration(seconds: 60)),
      ).readClock('page-overtime');
      final continued =
          await MatchCommandService(
            database,
            now: () => anchor.add(const Duration(seconds: 12)),
          ).continueMatch(
            ContinueMatchCommand(
              commandId: 'page-overtime-continue',
              matchId: 'page-overtime',
              occurredAt: anchor.add(const Duration(seconds: 12)),
            ),
          );
      final controller = ScoringController.fromCommittedProjection(
        continued,
        service,
      );
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );

      expect(find.text('OT 00:00'), findsOneWidget);
      expect(find.text('加时赛'), findsNWidgets(2));
    });
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
        recordingMode: RecordingMode.simple,
        trackingCoverage: TrackingCoverage.locations,
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
      expect(controller.beginLocateLastUnlocatedShot(), isTrue);
      await tester.pump();
      expect(find.byKey(const Key('pending-location-undo')), findsOneWidget);

      await tester.tap(find.byKey(const Key('pending-location-undo')));
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
          recordingMode: RecordingMode.simple,
          trackingCoverage: TrackingCoverage.locations,
          createdAt: DateTime.utc(2026, 8, 23, 9),
          startedAt: DateTime.utc(2026, 8, 23, 9),
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      var committedFeedbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            onActionCommitted: () => committedFeedbackCount++,
          ),
        ),
      );
      await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
      expect(controller.beginLocateLastUnlocatedShot(), isTrue);
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
      expect(committedFeedbackCount, 1);
    });
  });

  testWidgets(
    'production foul button remains available after an unlocated score',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await withTestDatabase((database) async {
        final service = MatchCommandService(
          database,
          now: () => DateTime.utc(2026, 8, 23, 9),
        );
        final start = await service.start(
          StartMatchCommand(
            commandId: 'page-foul-start-command',
            matchId: 'page-foul-match',
            redName: 'Red',
            blueName: 'Blue',
            ruleTemplate: const RuleTemplate(
              id: 'free',
              name: 'Free',
              scoreButtons: [1, 2, 3],
            ),
            recordingMode: RecordingMode.simple,
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

        await tester.tap(find.text(foulText).first);
        await tester.pump();

        expect(find.text(scoringResolvePendingText), findsNothing);
        expect(await database.select(database.matchEvents).get(), hasLength(2));
      });
    },
  );

  testWidgets('leave is guarded while a local pending location exists', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'leave-pending-local');
    controller.addScore(side: TeamSide.blue, points: 2);
    var leaveCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ScoringPage(
          controller: controller,
          onRequestLeave: () async => leaveCalls++,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('scoring-leave')));
    await tester.pump();
    expect(find.text('当前有待定位投篮'), findsOneWidget);
    expect(find.byKey(const Key('leave-stay')), findsOneWidget);
    expect(find.byKey(const Key('leave-cancel-pending')), findsOneWidget);
    expect(leaveCalls, 0);
    await tester.tap(find.byKey(const Key('leave-stay')));
    expect(leaveCalls, 0);
  });

  testWidgets('leave stays in scoring when pending cancellation is busy', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var armed = false;
      final anchor = DateTime.utc(2026, 8, 23, 9);
      final service = MatchCommandService(
        database,
        now: () => anchor,
        failureInjector: (point) async {
          if (armed && point == MatchCommandFailurePoint.beforeCommit) {
            if (!entered.isCompleted) entered.complete();
            await release.future;
          }
        },
      );
      final start = await service.start(
        _startPageCommand('leave-busy-pending'),
      );
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await controller.recordScoreCommitted(side: TeamSide.blue, points: 2);
      armed = true;
      expect(controller.beginLocateLastUnlocatedShot(), isTrue);
      final confirmation = controller.confirmPendingLocation();
      await entered.future;

      var leaveCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            onRequestLeave: () async => leaveCalls++,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('scoring-leave')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('leave-cancel-pending')));
      await tester.pump();

      expect(leaveCalls, 0);
      expect(find.text('当前有待定位投篮'), findsOneWidget);

      release.complete();
      await confirmation;
    });
  });

  testWidgets('leave is guarded while a detailed draft is uncommitted', (
    tester,
  ) async {
    final controller = ScoringController(
      setup: const MatchSetup(
        matchId: 'leave-draft-local',
        redName: '红方',
        blueName: '蓝方',
        ruleTemplateId: 'free',
        targetScore: null,
        timerEnabled: false,
        timeLimitMinutes: 10,
        winByTwo: false,
        recordingMode: RecordingMode.detailed,
        trackingCoverage: TrackingCoverage.locations,
      ),
    );
    controller.beginDetailedShot(CourtPoint(x: 0.4, y: 0.6));
    var leaveCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ScoringPage(
          controller: controller,
          onRequestLeave: () async => leaveCalls++,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('scoring-leave')));
    await tester.pump();
    expect(find.text('当前有未提交投篮'), findsOneWidget);
    expect(find.byKey(const Key('leave-stay')), findsOneWidget);
    expect(find.byKey(const Key('leave-cancel-draft')), findsOneWidget);
    expect(find.byKey(const Key('leave-commit-draft')), findsOneWidget);
    expect(leaveCalls, 0);
    await tester.tap(find.byKey(const Key('leave-stay')));
    expect(leaveCalls, 0);
  });
}

StartMatchCommand _startPageCommand(
  String id, {
  RecordingMode recordingMode = RecordingMode.simple,
  TrackingCoverage trackingCoverage = TrackingCoverage.locations,
  bool timerEnabled = false,
  ClockMode clockMode = ClockMode.countUp,
  int? regulationSeconds,
  DateTime? createdAt,
  DateTime? startedAt,
}) {
  final anchor = createdAt ?? DateTime.utc(2026, 8, 23, 9);
  return StartMatchCommand(
    commandId: '$id-command',
    matchId: id,
    redName: 'Red',
    blueName: 'Blue',
    ruleTemplate: const RuleTemplate(
      id: 'free',
      name: 'Free',
      scoreButtons: [1, 2, 3],
    ),
    recordingMode: recordingMode,
    trackingCoverage: trackingCoverage,
    clockMode: clockMode,
    regulationSeconds: clockMode == ClockMode.countdown
        ? regulationSeconds ?? 600
        : null,
    timerEnabled: timerEnabled,
    createdAt: anchor,
    startedAt: startedAt ?? anchor,
  );
}
