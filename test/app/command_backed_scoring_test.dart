import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

import '../test_helpers/test_database.dart';

void main() {
  testWidgets('production scoring route commits through command receipts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(3000, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
      await database.close();
      await tester.pump(const Duration(seconds: 1));
    });
    await tester.pumpWidget(HoopTraceApp(database: database));
    await _pumpUntilFound(tester, find.text('开始计分'));

    await tester.tap(find.text('开始计分'));
    await _pumpUntilFound(tester, find.byType(PregamePage));
    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-recording-simple')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('pregame-recording-simple')));
    await tester.scrollUntilVisible(
      find.text(pregameStartMatchText),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(pregameStartMatchText));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    final scoreButton = tester.widget<FilledButton>(
      find.byKey(const Key('red-score-2')),
    );
    scoreButton.onPressed!();
    await tester.pump();
    expect(find.text(scoringMarkShotDialogTitle), findsNothing);
    expect(find.text('标记投篮位置？'), findsNothing);

    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      final commandReceipts = await (database.select(
        database.auditLogs,
      )..where((row) => row.action.equals('command'))).get();
      if (commandReceipts.length >= 2) break;
    }

    final commandReceipts = await (database.select(
      database.auditLogs,
    )..where((row) => row.action.equals('command'))).get();
    final events = await database.select(database.matchEvents).get();
    expect(commandReceipts.length, greaterThanOrEqualTo(2));
    expect(events, hasLength(1));
    expect(events.single.points, 2);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for $finder');
}
