import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_page.dart';

import '../test_helpers/test_database.dart';

void main() {
  testWidgets('switching replay route loads the requested match', (
    tester,
  ) async {
    final database = createTestDatabase();
    final repository = MatchRepository(database);
    await _createFinishedMatch(repository, 'match-a', 'Alpha', 1);
    await _createFinishedMatch(repository, 'match-b', 'Bravo', 3);
    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final router = app.routerConfig! as GoRouter;

    router.go('/matches/match-a/replay');
    await _pumpUntilFound(tester, find.byType(ReplayPage));
    expect(find.text('Alpha'), findsWidgets);

    router.go('/matches/match-b/replay');
    await _pumpUntilFound(tester, find.text('Bravo'));

    expect(find.text('Bravo'), findsWidgets);
    expect(find.text('Alpha'), findsNothing);
  });
}

Future<void> _createFinishedMatch(
  MatchRepository repository,
  String id,
  String redName,
  int points,
) async {
  final startedAt = DateTime.utc(2026, 7, 18, 10);
  await repository.createMinimalMatch(
    id: id,
    redName: redName,
    blueName: 'Blue',
    createdAt: startedAt,
  );
  await repository.saveEvent(
    MatchEvent.score(
      id: '$id-score',
      matchId: id,
      side: TeamSide.red,
      points: points,
      occurredAt: startedAt,
    ),
  );
  await repository.finishMatch(id, endedAt: startedAt);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for the expected widget.');
}
