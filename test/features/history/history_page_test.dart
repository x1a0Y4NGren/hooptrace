import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/features/history/history_controller.dart';
import 'package:hooptrace/features/history/history_page.dart';

void main() {
  testWidgets('shows recent match details and returns tapped match id', (
    tester,
  ) async {
    String? selectedId;
    final controller = HistoryController(
      matches: [
        HistoryMatchSummary(
          matchId: 'match-7',
          playedAt: DateTime(2026, 7, 9, 19, 30),
          redName: '烈火',
          blueName: '深海',
          redScore: 11,
          blueScore: 7,
          ruleName: '11 分制',
          duration: const Duration(minutes: 12, seconds: 8),
          locatedShots: 7,
          scoringEvents: 10,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          controller: controller,
          onMatchTap: (matchId) => selectedId = matchId,
        ),
      ),
    );

    expect(find.text('最近比赛'), findsOneWidget);
    expect(find.text('烈火'), findsOneWidget);
    expect(find.text('深海'), findsOneWidget);
    expect(find.text('11 : 7'), findsOneWidget);
    expect(find.textContaining('胜者：烈火'), findsOneWidget);
    expect(find.text('11 分制'), findsOneWidget);
    expect(find.text('12:08'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('history-match-match-7')));
    expect(selectedId, 'match-7');
  });

  testWidgets('shows an empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          controller: HistoryController(matches: const []),
          onMatchTap: (_) {},
        ),
      ),
    );

    expect(find.text('暂无比赛记录'), findsOneWidget);
    expect(find.text('完成一场比赛后，记录会显示在这里。'), findsOneWidget);
  });

  testWidgets('optional home action provides an explicit exit', (tester) async {
    var homeCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          controller: HistoryController(matches: const []),
          onMatchTap: (_) {},
          onHome: () => homeCalls++,
        ),
      ),
    );

    await tester.tap(find.byTooltip('返回主页'));
    expect(homeCalls, 1);
  });

  testWidgets('adapts match list to portrait and landscape', (tester) async {
    final controller = HistoryController(
      matches: [
        HistoryMatchSummary(
          matchId: 'responsive',
          playedAt: DateTime(2026, 7, 9),
          redName: '红方',
          blueName: '蓝方',
          redScore: 3,
          blueScore: 2,
          ruleName: '自由计分',
          duration: const Duration(minutes: 2),
          locatedShots: 1,
          scoringEvents: 2,
        ),
      ],
    );

    for (final size in [const Size(390, 844), const Size(1000, 700)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: HistoryPage(controller: controller, onMatchTap: (_) {}),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(find.byKey(const Key('history-match-responsive')))
            .height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.binding.setSurfaceSize(null);
  });
}
