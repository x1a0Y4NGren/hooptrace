import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

void main() {
  testWidgets('paused scoring shows blocking panel and resumes explicitly', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-resume-control';
    await _startMatch(database, matchId, timerEnabled: true);
    final service = MatchCommandService(database);
    await service.pause(
      PauseMatchCommand(matchId: matchId, occurredAt: DateTime.now().toUtc()),
    );

    await _enterScoring(tester, database);
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('scoring-paused-panel')),
    );
    expect(find.byKey(const Key('scoring-paused-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('paused-continue')));
    await tester.pump(const Duration(milliseconds: 100));
    expect((await service.readClock(matchId))?.isRunning, isTrue);
    await _pumpUntilGone(tester, find.byKey(const Key('scoring-more-sheet')));
    expect(find.byType(ScoringPage), findsOneWidget);
  });

  testWidgets('resume command failure keeps the button and scoring page', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-resume-failure';
    await _startMatch(database, matchId, timerEnabled: true);
    final normalService = MatchCommandService(database);
    await normalService.pause(
      PauseMatchCommand(matchId: matchId, occurredAt: DateTime.now().toUtc()),
    );
    final failingService = MatchCommandService(
      database,
      failureInjector: (point) {
        if (point == MatchCommandFailurePoint.beforeCommit) {
          throw StateError('injected resume failure');
        }
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          matchCommandServiceProvider.overrideWithValue(failingService),
        ],
        child: const HoopTraceApp(),
      ),
    );
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    await tester.tap(find.byKey(const Key('home-resume')));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('scoring-paused-panel')),
    );
    expect(find.byKey(const Key('scoring-paused-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('paused-continue')));
    await tester.pump();
    expect(find.byType(ScoringPage), findsOneWidget);
    expect(find.byKey(const Key('scoring-paused-panel')), findsOneWidget);
    expect(find.text('操作失败，请重试。'), findsOneWidget);
  });

  testWidgets(
    'production resume emits feedback only after a successful command',
    (tester) async {
      final database = AppDatabase.inMemory();
      _closeAfterWidgetTest(tester, database);
      const matchId = 'task6-resume-feedback';
      await _startMatch(database, matchId, timerEnabled: true);
      final service = MatchCommandService(database);
      await service.pause(
        PauseMatchCommand(matchId: matchId, occurredAt: DateTime.now().toUtc()),
      );
      final platform = _ResumeFeedbackPlatform(database);
      final feedback = ScoringFeedbackService(
        ScoringFeedbackPreferencesRepository(database),
        platform: platform,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            scoringFeedbackServiceProvider.overrideWithValue(feedback),
          ],
          child: const HoopTraceApp(),
        ),
      );
      await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
      await tester.tap(find.byKey(const Key('home-resume')));
      await _pumpUntilFound(tester, find.byType(ScoringPage));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-paused-panel')),
      );
      expect(find.byKey(const Key('scoring-paused-panel')), findsOneWidget);
      await tester.tap(find.byKey(const Key('paused-continue')));
      await _pumpUntilGone(
        tester,
        find.byKey(const Key('scoring-paused-panel')),
      );

      expect(platform.hapticCalls, 1);
      expect(platform.eventCounts, [greaterThanOrEqualTo(2)]);
    },
  );

  testWidgets('production resume failure does not emit feedback', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-resume-feedback-failure';
    await _startMatch(database, matchId, timerEnabled: true);
    final normalService = MatchCommandService(database);
    await normalService.pause(
      PauseMatchCommand(matchId: matchId, occurredAt: DateTime.now().toUtc()),
    );
    final failingService = MatchCommandService(
      database,
      failureInjector: (point) {
        if (point == MatchCommandFailurePoint.beforeCommit) {
          throw StateError('injected resume failure');
        }
      },
    );
    final platform = _ResumeFeedbackPlatform(database);
    final feedback = ScoringFeedbackService(
      ScoringFeedbackPreferencesRepository(database),
      platform: platform,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          matchCommandServiceProvider.overrideWithValue(failingService),
          scoringFeedbackServiceProvider.overrideWithValue(feedback),
        ],
        child: const HoopTraceApp(),
      ),
    );
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    await tester.tap(find.byKey(const Key('home-resume')));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('scoring-paused-panel')),
    );
    expect(find.byKey(const Key('scoring-paused-panel')), findsOneWidget);
    await tester.tap(find.byKey(const Key('paused-continue')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('scoring-paused-panel')), findsOneWidget);
    expect(platform.hapticCalls, 0);
  });

  testWidgets('running and timer-disabled scoring do not show resume control', (
    tester,
  ) async {
    final runningDatabase = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, runningDatabase);
    await _startMatch(
      runningDatabase,
      'task6-resume-running',
      timerEnabled: true,
    );
    await _enterScoring(tester, runningDatabase);
    await _openMore(tester);
    expect(find.byKey(const Key('more-pause')), findsOneWidget);
    expect(find.byKey(const Key('more-resume')), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await runningDatabase.close();
    final noTimerDatabase = AppDatabase.inMemory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await noTimerDatabase.close();
    });
    await _startMatch(
      noTimerDatabase,
      'task6-resume-no-timer',
      timerEnabled: false,
    );
    await _enterScoring(tester, noTimerDatabase);
    await _openMore(tester);
    expect(find.byKey(const Key('more-pause')), findsNothing);
    expect(find.byKey(const Key('more-resume')), findsNothing);
  });
}

Future<void> _startMatch(
  AppDatabase database,
  String matchId, {
  required bool timerEnabled,
}) async {
  final now = DateTime.now().toUtc();
  await MatchCommandService(database).start(
    StartMatchCommand(
      commandId: '$matchId-start',
      matchId: matchId,
      redName: '红队',
      blueName: '蓝队',
      ruleTemplate: const RuleTemplate(
        id: 'free',
        name: '自由计分',
        scoreButtons: [1, 2, 3],
      ),
      recordingMode: RecordingMode.simple,
      timerEnabled: timerEnabled,
      regulationSeconds: timerEnabled ? 600 : null,
      createdAt: now,
      startedAt: now,
    ),
  );
}

Future<void> _enterScoring(WidgetTester tester, AppDatabase database) async {
  await tester.pumpWidget(HoopTraceApp(database: database));
  await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
  await tester.tap(find.byKey(const Key('home-resume')));
  await _pumpUntilFound(tester, find.byType(ScoringPage));
}

void _closeAfterWidgetTest(WidgetTester tester, AppDatabase database) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await database.close();
  });
}

class _ResumeFeedbackPlatform implements ScoringFeedbackPlatform {
  _ResumeFeedbackPlatform(this.database);

  final AppDatabase database;
  int hapticCalls = 0;
  final eventCounts = <int>[];

  @override
  Future<void> lightImpact() async {
    hapticCalls++;
    eventCounts.add((await database.select(database.matchEvents).get()).length);
  }

  @override
  Future<void> click() async {}
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 300));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for $finder');
}

Future<void> _openMore(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('scoring-more')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('scoring-more-sheet')), findsOneWidget);
}

Future<void> _pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for $finder to disappear');
}
