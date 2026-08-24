import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

import '../test_helpers/test_database.dart';

void main() {
  final l10n = AppLocalizationsZh();

  testWidgets('production decision finish commits then opens final replay', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(3000, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
    });
    await _seedDecision(database, 'route-finish');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const HoopTraceApp(),
      ),
    );
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    await tester.tap(find.byKey(const Key('home-resume')));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    expect(find.byKey(const Key('scoring-decision-dock')), findsOneWidget);

    tester
        .widget<FilledButton>(find.byKey(const Key('scoring-decision-finish')))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.textContaining('Red 1 : 0 Blue'), findsWidgets);
    await tester.tap(find.byKey(const Key('scoring-finish-confirm')));
    await _pumpUntilFound(tester, find.byType(ReplayPage));
    await _pumpUntilFound(tester, find.text(l10n.replayFinished));
    expect(find.byKey(const Key('replay-finish-match')), findsNothing);

    final match = await database.select(database.matches).getSingle();
    expect(match.lifecycle, MatchLifecycle.finished.name);
    expect(await database.select(database.activeSessions).get(), isEmpty);
  });

  testWidgets('production decision continue keeps the match active', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(3000, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 200));
    });
    await _seedDecision(database, 'route-continue');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const HoopTraceApp(),
      ),
    );
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    await tester.tap(find.byKey(const Key('home-resume')));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    tester
        .widget<OutlinedButton>(
          find.byKey(const Key('scoring-decision-continue')),
        )
        .onPressed!();
    await _pumpUntilMissing(
      tester,
      find.byKey(const Key('scoring-decision-dock')),
    );

    final match = await database.select(database.matches).getSingle();
    expect(match.lifecycle, MatchLifecycle.active.name);
    expect(await database.select(database.activeSessions).get(), hasLength(1));
    expect(find.byType(ScoringPage), findsOneWidget);
  });

  testWidgets(
    'replay refreshes a stale confirmed score before retrying finish',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(3000, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = createTestDatabase();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 200));
      });
      final service = MatchCommandService(database);
      await _seedOpenMatch(service, 'route-stale-score');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(database)],
          child: const HoopTraceApp(),
        ),
      );
      await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
      await tester.tap(find.byKey(const Key('home-resume')));
      await _pumpUntilFound(tester, find.byType(ScoringPage));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scoring-more')));
      await tester.pumpAndSettle();
      tester.widget<ListTile>(find.byKey(const Key('more-replay'))).onTap!();
      await _pumpUntilFound(tester, find.byType(ReplayPage));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('replay-finish-match')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Red 1 : 0 Blue'), findsOneWidget);

      await service.record(
        RecordMatchEventCommand(
          commandId: 'route-stale-score-concurrent-command',
          matchId: 'route-stale-score',
          eventId: 'route-stale-score-concurrent-event',
          type: EventKind.fieldGoal,
          side: TeamSide.red,
          points: 1,
          outcome: ShotOutcome.made,
          occurredAt: DateTime.utc(2026, 8, 23, 9, 2),
        ),
      );
      await tester.tap(find.byKey(const Key('replay-finish-confirm')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.actionFailedRetry), findsOneWidget);
      expect(find.byKey(const Key('replay-finish-match')), findsOneWidget);

      await tester.tap(find.byKey(const Key('replay-finish-match')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Red 2 : 0 Blue'), findsOneWidget);
      await tester.tap(find.byKey(const Key('replay-finish-confirm')));
      await _pumpUntilFound(tester, find.text(l10n.replayFinished));

      final match = await database.select(database.matches).getSingle();
      expect(match.lifecycle, MatchLifecycle.finished.name);
    },
  );
}

Future<void> _seedDecision(AppDatabase database, String matchId) async {
  final service = MatchCommandService(database);
  await service.start(
    StartMatchCommand(
      commandId: '$matchId-start',
      matchId: matchId,
      redName: 'Red',
      blueName: 'Blue',
      ruleTemplate: const RuleTemplate(
        id: 'target-one',
        name: 'Target one',
        scoreButtons: [1, 2, 3],
        targetScore: 1,
      ),
      recordingMode: RecordingMode.simple,
      trackingCoverage: TrackingCoverage.scoresOnly,
      createdAt: DateTime.utc(2026, 8, 23, 9),
      startedAt: DateTime.utc(2026, 8, 23, 9),
    ),
  );
  await service.record(
    RecordMatchEventCommand(
      commandId: '$matchId-score',
      matchId: matchId,
      eventId: '$matchId-score-event',
      type: EventKind.fieldGoal,
      side: TeamSide.red,
      points: 1,
      outcome: ShotOutcome.made,
      occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
    ),
  );
}

Future<void> _seedOpenMatch(MatchCommandService service, String matchId) async {
  await service.start(
    StartMatchCommand(
      commandId: '$matchId-start',
      matchId: matchId,
      redName: 'Red',
      blueName: 'Blue',
      ruleTemplate: const RuleTemplate(
        id: 'open-score',
        name: 'Open score',
        scoreButtons: [1, 2, 3],
      ),
      recordingMode: RecordingMode.simple,
      trackingCoverage: TrackingCoverage.scoresOnly,
      createdAt: DateTime.utc(2026, 8, 23, 9),
      startedAt: DateTime.utc(2026, 8, 23, 9),
    ),
  );
  await service.record(
    RecordMatchEventCommand(
      commandId: '$matchId-score-command',
      matchId: matchId,
      eventId: '$matchId-score-event',
      type: EventKind.fieldGoal,
      side: TeamSide.red,
      points: 1,
      outcome: ShotOutcome.made,
      occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
    ),
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for $finder');
}

Future<void> _pumpUntilMissing(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 150; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for $finder to disappear');
}
