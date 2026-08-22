import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/app/orientation_shell.dart';
import 'package:hooptrace/features/history/history_page.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

import '../test_helpers/test_database.dart';

void main() {
  testWidgets('HoopTrace app starts on home route', (tester) async {
    final database = createTestDatabase();
    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();

    expect(find.text('\u5f00\u59cb\u8ba1\u5206'), findsOneWidget);
    expect(find.text('\u590d\u76d8\u5386\u53f2'), findsOneWidget);
    expect(find.byTooltip('球员'), findsOneWidget);
    expect(find.byTooltip('设置'), findsOneWidget);
    expect(find.byTooltip('项目详情'), findsOneWidget);
  });

  testWidgets('start scoring route enters landscape scoring shell', (
    tester,
  ) async {
    final database = createTestDatabase();
    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();

    await tester.tap(find.text('\u5f00\u59cb\u8ba1\u5206'));
    await tester.pumpAndSettle();
    expect(find.byType(PregamePage), findsOneWidget);

    await tester.tap(find.text(pregameStartMatchText));
    await tester.pumpAndSettle();

    expect(find.byType(OrientationShell), findsOneWidget);
  });

  testWidgets('score, replay, finish and history form a local data loop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1095, 616));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    await tester.pumpWidget(HoopTraceApp(database: database));
    await _pumpUntilFound(tester, find.text('\u5f00\u59cb\u8ba1\u5206'));

    await tester.tap(find.text('\u5f00\u59cb\u8ba1\u5206'));
    await _pumpUntilFound(tester, find.byType(PregamePage));
    await tester.tap(find.text(pregameStartMatchText));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    await tester.tap(find.byKey(const Key('red-score-2')));
    await tester.pump();
    await tester.tap(find.text(scoringDoNotMarkText));
    await tester.pump();
    await tester.tap(find.text(scoringReplayText));
    await _pumpUntilFound(tester, find.byType(ReplayPage));

    expect(find.byType(ReplayPage), findsOneWidget);
    expect(find.text('\u8fdb\u884c\u4e2d'), findsOneWidget);

    await tester.tap(find.text('\u7ed3\u675f\u6bd4\u8d5b'));
    await _pumpUntilFound(tester, find.byType(HistoryPage));
    expect(find.byType(HistoryPage), findsOneWidget);
    expect(find.text('2 : 0'), findsOneWidget);

    await tester.tap(
      find.ancestor(of: find.text('2 : 0'), matching: find.byType(InkWell)),
    );
    await _pumpUntilFound(tester, find.byType(ReplayPage));
    expect(find.byType(ReplayPage), findsOneWidget);
    expect(find.text('\u7ec8\u573a'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 500));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for the expected widget.');
}
