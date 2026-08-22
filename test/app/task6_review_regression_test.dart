import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/provider_router.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

import '../test_helpers/test_database.dart';

void main() {
  test(
    'active and live watches have one initial snapshot and later updates',
    () async {
      final database = createTestDatabase();
      const matchId = 'task6-single-initial';
      final now = DateTime.utc(2026, 8, 23, 12);
      final service = MatchCommandService(database);
      await service.start(
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
          createdAt: now,
          startedAt: now,
        ),
      );
      final repository = MatchRepository(database);
      final activeValues = <dynamic>[];
      final liveValues = <dynamic>[];
      final activeSubscription = repository.watchActiveMatch().listen(
        activeValues.add,
      );
      final liveSubscription = repository
          .watchLiveMatch(matchId)
          .listen(liveValues.add);
      addTearDown(() async {
        await activeSubscription.cancel();
        await liveSubscription.cancel();
        await database.close();
      });

      await _eventually(
        () => activeValues.length == 1 && liveValues.length == 1,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(activeValues, hasLength(1));
      expect(liveValues, hasLength(1));

      await service.record(
        RecordMatchEventCommand(
          commandId: '$matchId-score',
          matchId: matchId,
          side: TeamSide.red,
          points: 2,
          occurredAt: now,
        ),
      );
      await _eventually(
        () =>
            activeValues.any((value) => value?.redScore == 2) &&
            liveValues.any((value) => value?.redScore == 2),
      );
    },
  );

  test(
    'scoring controller keeps identity and pending location across projection refresh',
    () async {
      final database = createTestDatabase();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(() async {
        container.dispose();
        await database.close();
      });

      const matchId = 'task6-controller-stability';
      final now = DateTime.utc(2026, 8, 23, 12);
      final service = container.read(matchCommandServiceProvider);
      await service.start(
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
          createdAt: now,
          startedAt: now,
        ),
      );
      final live = container.listen<AsyncValue<dynamic>>(
        liveMatchProvider(matchId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(live.close);
      await _eventually(
        () => container.read(liveMatchProvider(matchId)).hasValue,
      );

      final scoring = container.listen(
        scoringControllerProvider(matchId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(scoring.close);
      final first = container.read(scoringControllerProvider(matchId));
      expect(first, isNotNull);
      await first!.recordScoreCommitted(side: TeamSide.red, points: 2);
      expect(first.state.pendingLocation, isNotNull);

      await _eventually(
        () =>
            container.read(liveMatchProvider(matchId)).valueOrNull?.redScore ==
            2,
      );
      final afterRefresh = container.read(scoringControllerProvider(matchId));
      expect(identical(afterRefresh, first), isTrue);
      expect(afterRefresh!.state.pendingLocation, isNotNull);

      await afterRefresh.confirmPendingLocation();
      await _eventually(
        () =>
            container
                .read(scoringControllerProvider(matchId))!
                .state
                .pendingLocation ==
            null,
      );
    },
  );

  test(
    'new provider container creates a fresh controller from the same database projection',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      const matchId = 'task6-controller-rebuild';
      final now = DateTime.utc(2026, 8, 23, 12);
      final service = MatchCommandService(database);
      await service.start(
        StartMatchCommand(
          commandId: '$matchId-start',
          matchId: matchId,
          redName: '重建红队',
          blueName: '重建蓝队',
          ruleTemplate: const RuleTemplate(
            id: 'free',
            name: '自由计分',
            scoreButtons: [1, 2, 3],
          ),
          recordingMode: RecordingMode.simple,
          createdAt: now,
          startedAt: now,
        ),
      );
      await service.record(
        RecordMatchEventCommand(
          commandId: '$matchId-score',
          matchId: matchId,
          side: TeamSide.blue,
          points: 3,
          occurredAt: now,
        ),
      );

      final firstContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      final firstLive = firstContainer.listen<AsyncValue<dynamic>>(
        liveMatchProvider(matchId),
        (_, _) {},
        fireImmediately: true,
      );
      await _eventually(
        () => firstContainer.read(liveMatchProvider(matchId)).hasValue,
      );
      final firstScoring = firstContainer.listen(
        scoringControllerProvider(matchId),
        (_, _) {},
        fireImmediately: true,
      );
      final first = firstContainer.read(scoringControllerProvider(matchId));
      expect(first!.state.score.blueScore, 3);
      firstLive.close();
      firstScoring.close();
      firstContainer.dispose();

      final secondContainer = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(secondContainer.dispose);
      final secondLive = secondContainer.listen<AsyncValue<dynamic>>(
        liveMatchProvider(matchId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(secondLive.close);
      await _eventually(
        () => secondContainer.read(liveMatchProvider(matchId)).hasValue,
      );
      final secondScoring = secondContainer.listen(
        scoringControllerProvider(matchId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(secondScoring.close);
      final second = secondContainer.read(scoringControllerProvider(matchId));
      expect(second, isNotNull);
      expect(identical(second, first), isFalse);
      expect(second!.state.score.blueScore, 3);
    },
  );

  testWidgets('scoring route shows a terminal message for an unknown match', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    final router = buildProviderAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(
          theme: buildHoopTraceTheme(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    router.go('/scoring/not-a-match');
    await _pumpUntilFound(tester, find.text('比赛未在进行中'));
    expect(find.text('请从主页继续一场活动比赛。'), findsOneWidget);
  });
}

Future<void> _eventually(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (predicate()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for provider update.');
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for $finder');
}
