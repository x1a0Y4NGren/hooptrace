import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

void main() {
  testWidgets('running clock pause-and-leave persists paused state', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    await _startMatch(
      database,
      'task6-running-pause-leave',
      timerEnabled: true,
    );
    final service = MatchCommandService(database);

    await _enterScoring(tester, database);
    await tester.tap(find.byKey(const Key('scoring-leave')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('leave-pause-and-leave')));
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));

    expect(
      (await service.readClock('task6-running-pause-leave'))?.isRunning,
      isFalse,
    );
  });

  testWidgets('paused keep-running resumes before leaving', (tester) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-paused-keep';
    await _startMatch(database, matchId, timerEnabled: true);
    final service = MatchCommandService(database);
    await service.pause(
      PauseMatchCommand(matchId: matchId, occurredAt: DateTime.now().toUtc()),
    );

    await _enterScoring(tester, database);
    await tester.tap(find.byKey(const Key('scoring-leave')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('leave-keep-running')));
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    expect((await service.readClock(matchId))?.isRunning, isTrue);
  });

  testWidgets('paused pause-and-leave leaves without retrying pause', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-paused-leave';
    await _startMatch(database, matchId, timerEnabled: true);
    final service = MatchCommandService(database);
    await service.pause(
      PauseMatchCommand(matchId: matchId, occurredAt: DateTime.now().toUtc()),
    );

    await _enterScoring(tester, database);
    await tester.tap(find.byKey(const Key('scoring-leave')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('leave-pause-and-leave')));
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    expect((await service.readClock(matchId))?.isRunning, isFalse);
  });

  testWidgets('pause-and-leave with timer disabled leaves directly', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-no-timer-leave';
    await _startMatch(database, matchId, timerEnabled: false);
    final service = MatchCommandService(database);

    await _enterScoring(tester, database);
    await tester.tap(find.byKey(const Key('scoring-leave')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('leave-pause-and-leave')));
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    expect((await service.readClock(matchId))?.isRunning, isFalse);
  });

  testWidgets('leave command failure keeps scoring page and shows a snackbar', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-leave-failure';
    await _startMatch(database, matchId, timerEnabled: true);
    final failingService = MatchCommandService(
      database,
      failureInjector: (point) {
        if (point == MatchCommandFailurePoint.beforeCommit) {
          throw StateError('injected pause failure');
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
    await tester.tap(find.byKey(const Key('scoring-leave')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('leave-pause-and-leave')));
    await tester.pump();

    expect(find.byType(ScoringPage), findsOneWidget);
    expect(find.byType(SnackBar), findsAtLeastNWidgets(1));
  });

  testWidgets('system back opens the same three-choice leave dialog', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    _closeAfterWidgetTest(tester, database);
    const matchId = 'task6-system-back';
    await _startMatch(database, matchId, timerEnabled: true);
    await _enterScoring(tester, database);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('离开比赛'), findsOneWidget);
    expect(find.byKey(const Key('leave-stay')), findsOneWidget);
    expect(find.byKey(const Key('leave-keep-running')), findsOneWidget);
    expect(find.byKey(const Key('leave-pause-and-leave')), findsOneWidget);
    await tester.tap(find.byKey(const Key('leave-stay')));
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
