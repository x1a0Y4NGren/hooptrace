import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

import '../../test_helpers/test_database.dart';

void main() {
  testWidgets('unified scoring keeps secondary actions behind More', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ScoringPage(matchId: 'unified-layout')),
    );

    expect(find.byKey(const Key('scoring-undo')), findsOneWidget);
    expect(find.byKey(const Key('scoring-more')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('scoring-undo'))).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('scoring-more'))).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byKey(const Key('scoring-more')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('scoring-more-sheet')), findsOneWidget);
    expect(find.byKey(const Key('more-blue-miss')), findsOneWidget);
    expect(find.byKey(const Key('more-red-miss')), findsOneWidget);
    expect(find.text('投篮'), findsOneWidget);
    expect(find.text('罚球'), findsOneWidget);
    expect(find.text('比赛状态'), findsOneWidget);
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('比赛'), findsOneWidget);
  });

  testWidgets('court-first draft starts as a gray point with side prompt', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'unified-court-first');
    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('scoring-court'))),
    );
    await tester.pump();

    expect(controller.courtFirstShotDraft, isNotNull);
    expect(find.text('请选择蓝方或红方得分'), findsOneWidget);

    await tester.tap(find.byKey(const Key('blue-score-2')));
    await tester.pumpAndSettle();
    expect(controller.courtFirstShotDraft, isNull);
    expect(controller.state.score.blueScore, 2);
    expect(controller.state.shotLocations, hasLength(1));
  });

  testWidgets(
    'court-first draft keeps score buttons enabled for side selection',
    (tester) async {
      final controller = ScoringController(matchId: 'draft-score-selection');
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );

      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.pump();

      final score = tester.widget<FilledButton>(
        find.byKey(const Key('blue-score-1')),
      );
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const Key('blue-score-1')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(score.onPressed, isNotNull);
      expect(semantics.properties.enabled, isTrue);
    },
  );

  testWidgets('legacy pending location disables score buttons and semantics', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'legacy-pending-score');
    controller.addScore(side: TeamSide.blue, points: 2);
    expect(controller.beginLocateLastUnlocatedShot(), isTrue);
    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    final score = tester.widget<FilledButton>(
      find.byKey(const Key('blue-score-1')),
    );
    final semantics = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const Key('blue-score-1')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(controller.state.pendingLocation, isNotNull);
    expect(controller.courtFirstShotDraft, isNull);
    expect(score.onPressed, isNull);
    expect(semantics.properties.enabled, isFalse);
  });

  testWidgets('score-first exposes a ten-second location supplement on court', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'unified-score-first');
    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('red-score-3')));
    await tester.pump();

    expect(controller.locationSupplementWindow, isNotNull);
    expect(find.byKey(const Key('red-score-3-location')), findsOneWidget);
    expect(find.textContaining('补充红方 +3 落点'), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('scoring-court'))),
    );
    await tester.pumpAndSettle();
    expect(controller.locationSupplementWindow, isNull);
    expect(controller.state.shotLocations, hasLength(1));
  });

  testWidgets(
    'score-first location window allows a foul and keeps its window',
    (tester) async {
      await withTestDatabase((database) async {
        final anchor = DateTime.utc(2026, 8, 23, 9);
        final service = MatchCommandService(database, now: () => anchor);
        final start = await service.start(
          _startPageCommand('score-first-foul-window'),
        );
        final controller = ScoringController.fromCommittedProjection(
          start,
          service,
          nowUtc: () => anchor,
        );
        await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
        final windowEventId = controller.locationSupplementWindow!.eventId;

        await tester.pumpWidget(
          MaterialApp(home: ScoringPage(controller: controller)),
        );
        expect(
          tester
              .widget<OutlinedButton>(find.byKey(const Key('red-foul')))
              .onPressed,
          isNotNull,
        );

        await tester.tap(find.byKey(const Key('red-foul')));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();

        expect(controller.state.redFouls, 1);
        expect(controller.locationSupplementWindow?.eventId, windowEventId);
        expect(await database.select(database.matchEvents).get(), hasLength(2));
      });
    },
  );

  testWidgets('score-first location window allows More actions', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(
        _startPageCommand('score-first-more-window'),
      );
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await controller.recordScoreCommitted(side: TeamSide.blue, points: 1);

      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();

      final possession = tester.widget<ListTile>(
        find.byKey(const Key('more-possession-blue')),
      );
      expect(possession.onTap, isNotNull);
      await tester.tap(find.byKey(const Key('more-possession-blue')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(controller.state.currentPossession, TeamSide.blue);
      expect(controller.locationSupplementWindow, isNotNull);
      expect(await database.select(database.matchEvents).get(), hasLength(2));
    });
  });

  testWidgets(
    'next score closes the old supplement window and binds the latest score',
    (tester) async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final start = await service.start(
          _startPageCommand('score-first-next-score-window'),
        );
        final controller = ScoringController.fromCommittedProjection(
          start,
          service,
        );
        await tester.pumpWidget(
          MaterialApp(home: ScoringPage(controller: controller)),
        );
        await tester.tap(find.byKey(const Key('blue-score-1')));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
        final firstWindowEventId = controller.locationSupplementWindow!.eventId;

        await tester.tap(find.byKey(const Key('red-score-2')));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();

        final latestEventId = controller.state.events.last.id;
        expect(controller.state.score.redScore, 2);
        expect(controller.locationSupplementWindow, isNotNull);
        expect(controller.locationSupplementWindow!.eventId, latestEventId);
        expect(
          controller.locationSupplementWindow!.eventId,
          isNot(firstWindowEventId),
        );
        expect(await database.select(database.matchEvents).get(), hasLength(2));
      });
    },
  );

  testWidgets('More text entries survive repeated open and cancel', (
    tester,
  ) async {
    final controller = ScoringController(matchId: 'unified-dialog-life');
    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('more-note')));
      await tester.tap(find.byKey(const Key('more-note')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.byKey(const Key('text-entry-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.drag(
        find.descendant(
          of: find.byKey(const Key('scoring-more-sheet')),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, 500),
      );
      await tester.tap(find.byKey(const Key('more-close')));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unified scoring remains operable across landscape and portrait sizes',
    (tester) async {
      for (final size in const [
        Size(731, 411),
        Size(1095, 616),
        Size(1920, 1080),
        Size(411, 731),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(home: ScoringPage(matchId: 'unified-responsive')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          tester.getRect(find.byKey(const Key('scoring-scoreboard'))).right,
          lessThanOrEqualTo(size.width),
        );
        for (final key in const [
          'blue-score-1',
          'blue-score-2',
          'blue-score-3',
          'red-score-1',
          'red-score-2',
          'red-score-3',
          'blue-foul',
          'red-foul',
        ]) {
          expect(
            tester.getSize(find.byKey(Key(key))).height,
            greaterThanOrEqualTo(48),
          );
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('reduced motion uses a static location outline', (tester) async {
    final controller = ScoringController(matchId: 'unified-reduced-motion')
      ..addScore(side: TeamSide.blue, points: 2);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ScoringPage(controller: controller),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('blue-score-2-location')), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
    expect(find.textContaining('2 秒'), findsNothing);
  });

  testWidgets('court-first score failure retains draft and retries in place', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      var failNext = false;
      final service = MatchCommandService(
        database,
        failureInjector: (point) {
          if (failNext && point == MatchCommandFailurePoint.beforeCommit) {
            failNext = false;
            throw StateError('court-first score failed');
          }
        },
      );
      final projection = await service.start(
        _startPageCommand('page-court-first-score-failure'),
      );
      final controller = ScoringController.fromCommittedProjection(
        projection,
        service,
      );
      failNext = true;
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.tap(find.byKey(const Key('blue-score-2')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(controller.courtFirstShotDraft, isNotNull);
      expect(find.byType(SnackBarAction), findsOneWidget);
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      expect(controller.courtFirstShotDraft, isNull);
      expect(await database.select(database.matchEvents).get(), hasLength(1));
    });
  });

  testWidgets('score-first attach failure keeps the window and retries', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      var failNext = false;
      final service = MatchCommandService(
        database,
        failureInjector: (point) {
          if (failNext && point == MatchCommandFailurePoint.beforeCommit) {
            failNext = false;
            throw StateError('attach failed');
          }
        },
      );
      final projection = await service.start(
        _startPageCommand('page-attach-failure'),
      );
      final controller = ScoringController.fromCommittedProjection(
        projection,
        service,
      );
      await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
      failNext = true;
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(controller.locationSupplementWindow, isNotNull);
      expect(find.byType(SnackBarAction), findsOneWidget);
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      expect(controller.locationSupplementWindow, isNull);
      expect(await database.select(database.shotLocations).get(), hasLength(1));
    });
  });

  testWidgets(
    'court-first miss failure keeps the draft and retries from More',
    (tester) async {
      await withTestDatabase((database) async {
        var failNext = false;
        final service = MatchCommandService(
          database,
          failureInjector: (point) {
            if (failNext && point == MatchCommandFailurePoint.beforeCommit) {
              failNext = false;
              throw StateError('miss failed');
            }
          },
        );
        final projection = await service.start(
          _startPageCommand('page-court-first-miss-failure'),
        );
        final controller = ScoringController.fromCommittedProjection(
          projection,
          service,
        );
        failNext = true;
        await tester.pumpWidget(
          MaterialApp(home: ScoringPage(controller: controller)),
        );
        await tester.tapAt(
          tester.getCenter(find.byKey(const Key('scoring-court'))),
        );
        await tester.tap(find.byKey(const Key('scoring-more')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('more-red-miss')));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();

        expect(controller.courtFirstShotDraft, isNotNull);
        expect(find.byKey(const Key('more-inline-retry')), findsOneWidget);
        await tester.tap(find.byKey(const Key('more-inline-retry')));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
        expect(controller.courtFirstShotDraft, isNull);
        final events = await database.select(database.matchEvents).get();
        expect(events.single.outcome, ShotOutcome.missed.name);
      });
    },
  );

  testWidgets('More note failure shows inline retry and closes on success', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      var failNext = false;
      final service = MatchCommandService(
        database,
        failureInjector: (point) {
          if (failNext && point == MatchCommandFailurePoint.beforeCommit) {
            failNext = false;
            throw StateError('note failed');
          }
        },
      );
      final projection = await service.start(
        _startPageCommand('page-more-note-failure'),
      );
      final controller = ScoringController.fromCommittedProjection(
        projection,
        service,
      );
      failNext = true;
      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('more-note')));
      await tester.tap(find.byKey(const Key('more-note')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('text-entry-field')),
        'timeout',
      );
      await tester.tap(find.byKey(const Key('text-entry-confirm')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(find.byKey(const Key('scoring-more-sheet')), findsOneWidget);
      expect(find.byKey(const Key('more-inline-retry')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('more-inline-retry')));
      await tester.tap(find.byKey(const Key('more-inline-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('scoring-more-sheet')), findsNothing);
      expect(
        (await database.select(database.matchEvents).get()).single.note,
        'timeout',
      );
    });
  });

  testWidgets('More finish failure keeps confirmation flow retryable', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(
        _startPageCommand('page-more-finish-failure', targetScore: 2),
      );
      final projection = await service.record(
        RecordMatchEventCommand(
          matchId: start.match.id,
          type: EventKind.fieldGoal,
          side: TeamSide.red,
          points: 2,
          outcome: ShotOutcome.made,
          occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        projection,
        service,
      );
      var failNext = true;
      var finishCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            onFinishDecision: (_, _) async {
              finishCalls++;
              if (failNext) {
                failNext = false;
                throw StateError('finish failed');
              }
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('more-finish')));
      await tester.tap(find.byKey(const Key('more-finish')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scoring-finish-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('more-inline-retry')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('more-inline-retry')));
      await tester.tap(find.byKey(const Key('more-inline-retry')));
      await tester.pumpAndSettle();
      expect(finishCalls, 2);
      expect(find.byKey(const Key('scoring-more-sheet')), findsNothing);
    });
  });

  testWidgets('team score buttons meet contrast in light and dark themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildHoopTraceTheme(brightness: brightness),
          home: SizedBox(
            width: 400,
            height: 500,
            child: Row(
              children: [
                for (final side in TeamSide.values)
                  Expanded(
                    child: ScoreSidePanel(
                      side: side,
                      name: side.name,
                      score: 0,
                      fouls: 0,
                      onScore: (_) {},
                      onFoul: () {},
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      for (final side in TeamSide.values) {
        final score = tester.widget<FilledButton>(
          find.byKey(Key('${side.name}-score-1')),
        );
        final background = score.style?.backgroundColor?.resolve(const {});
        final foreground = score.style?.foregroundColor?.resolve(const {});
        final disabledForeground = score.style?.foregroundColor?.resolve(const {
          WidgetState.disabled,
        });
        expect(background, isNotNull);
        expect(foreground, isNotNull);
        expect(disabledForeground, isNotNull);
        expect(
          _contrastRatio(foreground!, background!),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrastRatio(disabledForeground!, background),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

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
    expect(find.byKey(const Key('red-foul')), findsOneWidget);
    expect(find.byKey(const Key('blue-foul')), findsOneWidget);
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
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('more-pause')), findsNothing);
      expect(find.byKey(const Key('more-resume')), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('无计时'), findsOneWidget);
    });
  });

  testWidgets(
    'pending decision exposes explicit continue and confirmed finish actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(731, 411));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        await service.start(
          _startPageCommand('decision-actions', targetScore: 2),
        );
        final projection = await service.record(
          RecordMatchEventCommand(
            commandId: 'decision-actions-score',
            matchId: 'decision-actions',
            eventId: 'decision-actions-score-event',
            type: EventKind.fieldGoal,
            side: TeamSide.red,
            points: 2,
            outcome: ShotOutcome.made,
            occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
          ),
        );
        final controller = ScoringController.fromCommittedProjection(
          projection,
          service,
        );
        var continueCalls = 0;
        var finishCalls = 0;
        var confirmedRedScore = -1;
        var confirmedBlueScore = -1;

        await tester.pumpWidget(
          MaterialApp(
            home: ScoringPage(
              controller: controller,
              onContinueDecision: () async => continueCalls++,
              onFinishDecision: (redScore, blueScore) async {
                finishCalls++;
                confirmedRedScore = redScore;
                confirmedBlueScore = blueScore;
              },
            ),
          ),
        );

        expect(find.byKey(const Key('scoring-decision-dock')), findsOneWidget);
        expect(find.textContaining('Red 2 : 0 Blue'), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final key in const <String>[
          'scoring-decision-continue',
          'scoring-decision-finish',
        ]) {
          final rect = tester.getRect(find.byKey(Key(key)));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(411));
          expect(rect.height, greaterThanOrEqualTo(48));
        }

        await tester.tap(find.byKey(const Key('scoring-decision-continue')));
        await tester.pumpAndSettle();
        expect(continueCalls, 1);
        expect(finishCalls, 0);

        await tester.tap(find.byKey(const Key('scoring-decision-finish')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scoring-finish-confirm')), findsOneWidget);
        expect(find.textContaining('Red 2 : 0 Blue'), findsWidgets);
        await tester.tap(find.byKey(const Key('scoring-finish-cancel')));
        await tester.pumpAndSettle();
        expect(finishCalls, 0);

        await tester.tap(find.byKey(const Key('scoring-decision-finish')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('scoring-finish-confirm')));
        await tester.pumpAndSettle();
        expect(confirmedRedScore, 2);
        expect(confirmedBlueScore, 0);
        expect(finishCalls, 1);
      });
    },
  );

  testWidgets('command-backed scoring page renders the projection rule hints', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(
        StartMatchCommand(
          commandId: 'page-command-hints-start',
          matchId: 'page-command-hints',
          redName: 'Red',
          blueName: 'Blue',
          ruleTemplate: const RuleTemplate(
            id: 'page-command-hints-rule',
            name: 'Page command hints',
            scoreButtons: [1, 2, 3],
            targetScore: 3,
            possessionHintEnabled: true,
            possessionPolicy: PossessionPolicy.switchAfterMade,
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
      await controller.recordScoreCommitted(side: TeamSide.red, points: 2);

      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );

      expect(find.byKey(const Key('scoring-rule-hints')), findsOneWidget);
      expect(find.textContaining('蓝方球权建议'), findsOneWidget);
      expect(find.textContaining('赛点'), findsOneWidget);
      expect(find.textContaining('补充红方 +2'), findsOneWidget);
    });
  });

  testWidgets('failed decision finish stays available and reports failure', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      await service.start(
        _startPageCommand('decision-failure', targetScore: 2),
      );
      final projection = await service.record(
        RecordMatchEventCommand(
          commandId: 'decision-failure-score',
          matchId: 'decision-failure',
          eventId: 'decision-failure-score-event',
          type: EventKind.fieldGoal,
          side: TeamSide.red,
          points: 2,
          outcome: ShotOutcome.made,
          occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        projection,
        service,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            onFinishDecision: (_, _) =>
                Future<void>.error(StateError('offline')),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('scoring-decision-finish')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scoring-finish-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('操作失败，请重试。'), findsOneWidget);
      expect(find.byKey(const Key('scoring-decision-finish')), findsOneWidget);
    });
  });

  testWidgets('failed decision continue shows retry and keeps the decision', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      await service.start(
        _startPageCommand('decision-continue-retry', targetScore: 2),
      );
      final projection = await service.record(
        RecordMatchEventCommand(
          commandId: 'decision-continue-retry-score',
          matchId: 'decision-continue-retry',
          eventId: 'decision-continue-retry-score-event',
          type: EventKind.fieldGoal,
          side: TeamSide.red,
          points: 2,
          outcome: ShotOutcome.made,
          occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        projection,
        service,
      );
      final command = ContinueMatchCommand(
        commandId: 'decision-continue-retry-command',
        matchId: 'decision-continue-retry',
        occurredAt: DateTime.utc(2026, 8, 23, 9, 2),
      );
      var attempts = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            onContinueDecision: () async {
              attempts++;
              if (attempts == 1) throw StateError('offline');
              await service.continueMatch(command);
            },
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('scoring-decision-continue')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('scoring-decision-dock')), findsOneWidget);
      expect(find.byType(SnackBarAction), findsOneWidget);
      tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();

      expect(attempts, 2);
      expect(find.byKey(const Key('scoring-decision-dock')), findsOneWidget);
    });
  });

  testWidgets('committed scoring feedback runs after the event is persisted', (
    tester,
  ) async {
    await withTestDatabase((database) async {
      final commandService = MatchCommandService(database);
      final projection = await commandService.start(
        _startPageCommand('feedback-order'),
      );
      final controller = ScoringController.fromCommittedProjection(
        projection,
        commandService,
      );
      final observedEventCounts = <int>[];
      final platform = _RecordingFeedbackPlatform(
        onHaptic: () async {
          observedEventCounts.add(
            (await database.select(database.matchEvents).get()).length,
          );
        },
      );
      final feedback = ScoringFeedbackService(
        ScoringFeedbackPreferencesRepository(database),
        platform: platform,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ScoringPage(
            controller: controller,
            onActionCommitted: feedback.emitCommitted,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('red-score-2')));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );

      expect(observedEventCounts, [1]);
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
    'compact court-first draft preserves court and commits through side panel',
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

      expect(controller.courtFirstShotDraft, isNotNull);
      expect(find.text('请选择蓝方或红方得分'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('scoring-court'))).height,
        greaterThanOrEqualTo(100),
      );
      await tester.tap(find.byKey(const Key('blue-score-2')));
      await tester.pumpAndSettle();
      expect(controller.courtFirstShotDraft, isNull);
      expect(controller.state.shotLocations, hasLength(1));
    },
  );

  testWidgets('score-first location stays on court without a secondary dock', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await service.start(
        _startPageCommand('page-pending-court'),
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

      expect(controller.locationSupplementWindow, isNotNull);
      expect(find.byKey(const Key('red-score-2-location')), findsOneWidget);
      expect(find.byKey(const Key('scoring-court')), findsOneWidget);
      final court = tester.getRect(find.byKey(const Key('scoring-court')));
      expect(court.height, greaterThan(0));
      await tester.tapAt(court.center);
      await tester.pumpAndSettle();
      expect(controller.locationSupplementWindow, isNull);
      expect(controller.state.shotLocations, hasLength(1));
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
    expect(find.byKey(const Key('scoring-court')), findsOneWidget);
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
    expect(find.byKey(const Key('red-score-2-location')), findsOneWidget);
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

      expect(controller.state.score.redScore, 2);
      expect(controller.state.pendingLocation, isNull);
      expect(await database.select(database.matchEvents).get(), hasLength(1));
    });
  });

  testWidgets('direct court tap locks a score-first marker', (tester) async {
    final controller = ScoringController(matchId: 'match-1');

    await tester.pumpWidget(
      MaterialApp(home: ScoringPage(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('blue-score-3')));
    await tester.pump();
    expect(find.byKey(const Key('blue-score-3-location')), findsOneWidget);
    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('scoring-court'))),
    );
    await tester.pumpAndSettle();

    expect(controller.state.score.blueScore, 3);
    expect(controller.state.pendingLocation, isNull);
    expect(controller.state.shotLocations.single.side, TeamSide.blue);
    expect(controller.state.shotLocations.single.isLocked, isTrue);
  });

  testWidgets(
    'tapping score while a supplement window is open continues scoring',
    (tester) async {
      final controller = ScoringController(matchId: 'match-1');

      await tester.pumpWidget(
        MaterialApp(home: ScoringPage(controller: controller)),
      );

      await tester.tap(find.byKey(const Key('red-score-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('blue-score-3')));
      await tester.pump();

      expect(find.byKey(const Key('scoring-action-rejected')), findsNothing);
      expect(controller.state.score.redScore, 2);
      expect(controller.state.score.blueScore, 3);
    },
  );

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
        expect(events.map((event) => event.points), [1, 2]);
        expect(controller.state.score.blueScore, 1);
        expect(controller.state.score.redScore, 2);
      });
    },
  );

  testWidgets('score-first direct court tap confirms or leaves the next shot', (
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
      expect(find.byKey(const Key('red-score-2-location')), findsOneWidget);
      expect(find.byKey(const Key('scoring-court')), findsOneWidget);

      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.pumpAndSettle();
      expect(controller.state.pendingLocation, isNull);
      expect(await database.select(database.shotLocations).get(), hasLength(1));

      await controller.recordScoreCommitted(side: TeamSide.blue, points: 1);
      await tester.pump();
      await tester.tap(find.byKey(const Key('scoring-undo')));
      await tester.pumpAndSettle();
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
        isNotNull,
      );
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.pump();
      expect(controller.detailedShotDraft, isNotNull);
      expect(find.text('请选择蓝方或红方得分'), findsOneWidget);
      await tester.tap(find.byKey(const Key('red-score-2')));
      await tester.pumpAndSettle();

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
        await tester.tap(find.byKey(const Key('scoring-undo')));
        await tester.pump();

        expect(controller.detailedShotDraft, isNull);
        expect(controller.state.events, isEmpty);
        expect(await database.select(database.matchEvents).get(), isEmpty);
        expect(await database.select(database.shotLocations).get(), isEmpty);
      });
    },
  );

  testWidgets('More records possession, free throw, and pause', (tester) async {
    await withTestDatabase((database) async {
      final anchor = DateTime.utc(2026, 8, 23, 9);
      final service = MatchCommandService(database, now: () => anchor);
      final start = await service.start(
        _startPageCommand(
          'page-more-actions',
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

      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('more-possession-blue')),
        300,
        scrollable: find.descendant(
          of: find.byKey(const Key('scoring-more-sheet')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('more-possession-blue')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('more-blue-free-throw-made')),
      );
      await tester.tap(find.byKey(const Key('more-blue-free-throw-made')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('more-pause')));
      await tester.tap(find.byKey(const Key('more-pause')));
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
      expect(find.text('计时已暂停'), findsOneWidget);
    });
  });

  testWidgets('compact unified workspace keeps primary targets at 48dp', (
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
      'scoring-undo',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(find.byKey(const Key('more-pause')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact scoring remains usable at 200 percent text size', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(731, 411));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const ScoringPage(matchId: 'compact-large-text'),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ScoreSidePanel).first).width,
      greaterThan(132),
    );
    expect(
      tester.getSize(find.byKey(const Key('scoring-court'))).height,
      greaterThanOrEqualTo(100),
    );
    expect(
      tester.getSize(find.byKey(const Key('scoring-court'))).width,
      greaterThanOrEqualTo(320),
    );
  });

  testWidgets('scoreboard reflows controls at narrow width and large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: ScoringPage(
          matchId: 'narrow-large-text-scoreboard',
          onRequestLeave: () async {},
          onOpenReplay: () {},
          onResumeClock: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scoreboard = find.byKey(const Key('scoring-scoreboard'));
    expect(scoreboard, findsOneWidget);
    expect(tester.getRect(scoreboard).right, lessThanOrEqualTo(390));
    expect(tester.getSize(scoreboard).height, greaterThanOrEqualTo(48));
  });

  testWidgets('compact scoring keeps primary controls within safe insets', (
    tester,
  ) async {
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

    final safeTop = insets.top;
    final safeBottom = 411 - insets.bottom;
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
    }
    expect(
      tester.getSize(find.byKey(const Key('scoring-court'))).height,
      greaterThanOrEqualTo(100),
    );
    expect(tester.takeException(), isNull);
  });

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
      for (final locale in const [Locale('zh'), Locale('en')]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ScoringPage(
              controller: controller,
              clockNowUtc: () => anchor.add(const Duration(seconds: 12)),
            ),
          ),
        );
        await tester.pump();
        final expected = locale.languageCode == 'zh'
            ? '加时赛 00:00'
            : 'Overtime 00:00';
        expect(find.text(expected), findsOneWidget);
      }
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

  testWidgets('More replay opens only after score-first location is resolved', (
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

    await tester.tap(find.byKey(const Key('scoring-more')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('more-replay')));
    await tester.tap(find.byKey(const Key('more-replay')));
    await tester.pumpAndSettle();
    expect(openCount, 1);

    await tester.tap(find.byKey(const Key('red-score-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('scoring-more')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('more-replay')));
    await tester.tap(find.byKey(const Key('more-replay')));
    await tester.pump();

    expect(openCount, 1);
    expect(
      tester.widget<ListTile>(find.byKey(const Key('more-replay'))).onTap,
      isNull,
    );
  });

  testWidgets('top Undo awaits soft-delete for a command-backed score', (
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
      await tester.pump();

      await tester.tap(find.byKey(const Key('scoring-undo')));
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
      var failNext = false;
      final service = MatchCommandService(
        database,
        failureInjector: (point) {
          if (failNext && point == MatchCommandFailurePoint.beforeCommit) {
            failNext = false;
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
      failNext = true;
      await tester.pump();
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();

      expect(find.text('重试'), findsOneWidget);
      expect(controller.locationSupplementWindow, isNotNull);
      final retryAction = tester.widget<SnackBarAction>(
        find.byType(SnackBarAction),
      );
      retryAction.onPressed();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();

      expect(controller.locationSupplementWindow, isNull);
      expect(await database.select(database.shotLocations).get(), hasLength(1));
      expect(committedFeedbackCount, 1);
    });
  });

  testWidgets(
    'leave remains available while a local supplement window exists',
    (tester) async {
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
      expect(find.byType(AlertDialog), findsNothing);
      expect(leaveCalls, 1);
    },
  );

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
        nowUtc: () => anchor,
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
      expect(find.byType(AlertDialog), findsOneWidget);

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
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const Key('leave-stay')), findsOneWidget);
    expect(find.byKey(const Key('leave-cancel-pending')), findsOneWidget);
    expect(leaveCalls, 0);
    await tester.tap(find.byKey(const Key('leave-stay')));
    expect(leaveCalls, 0);
  });
}

class _RecordingFeedbackPlatform implements ScoringFeedbackPlatform {
  _RecordingFeedbackPlatform({required this.onHaptic});

  final Future<void> Function() onHaptic;

  @override
  Future<void> lightImpact() => onHaptic();

  @override
  Future<void> click() async {}
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground.computeLuminance()
      : background.computeLuminance();
  final darker = foreground.computeLuminance() > background.computeLuminance()
      ? background.computeLuminance()
      : foreground.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
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
  int? targetScore,
}) {
  final anchor = createdAt ?? DateTime.utc(2026, 8, 23, 9);
  return StartMatchCommand(
    commandId: '$id-command',
    matchId: id,
    redName: 'Red',
    blueName: 'Blue',
    ruleTemplate: RuleTemplate(
      id: 'free',
      name: 'Free',
      scoreButtons: const [1, 2, 3],
      targetScore: targetScore,
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
