import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/features/history/history_page.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hooptrace/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completes the local scoring and replay loop', (tester) async {
    final runId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final redName = '集成红-$runId';
    final blueName = '集成蓝-$runId';

    app.main();
    await _pumpUntilFound(tester, find.text('开始计分'));

    await tester.tap(find.text('开始计分'));
    await _pumpUntilFound(tester, find.byType(PregamePage));

    await tester.enterText(
      find.byKey(const Key('pregame-red-name')),
      redName,
    );
    await tester.enterText(
      find.byKey(const Key('pregame-blue-name')),
      blueName,
    );
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text(pregameStartMatchText));
    await tester.tap(find.text(pregameStartMatchText));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    await _pumpUntilLandscape(tester);

    await tester.tap(find.byKey(const Key('red-score-2')));
    await _pumpUntilFound(tester, find.text(scoringMarkShotDialogTitle));
    final markButton = find.widgetWithText(FilledButton, scoringMarkText);
    await tester.ensureVisible(markButton);
    await tester.tap(markButton);
    await _pumpUntilFound(tester, find.byKey(const Key('confirm-location')));
    await tester.tap(find.byKey(const Key('confirm-location')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2 $redName'), findsOneWidget);
    expect(find.text('$blueName 0'), findsOneWidget);

    await tester.tap(find.text(scoringReplayText));
    await _pumpUntilFound(tester, find.byType(ReplayPage));
    expect(find.text(redName), findsOneWidget);
    expect(find.text(blueName), findsOneWidget);
    expect(find.text('进行中'), findsOneWidget);

    await tester.tap(find.byKey(const Key('replay-finish-match')));
    await _pumpUntilFound(tester, find.byType(HistoryPage));
    expect(find.text(redName), findsWidgets);
    expect(find.text(blueName), findsWidgets);

    final matchCard = find.ancestor(
      of: find.text(redName),
      matching: find.byType(InkWell),
    );
    expect(matchCard, findsWidgets);
    expect(
      find.descendant(of: matchCard.first, matching: find.text('2 : 0')),
      findsOneWidget,
    );
    await tester.tap(matchCard.first);
    await _pumpUntilFound(tester, find.byType(ReplayPage));
    expect(find.text('终场'), findsOneWidget);
    expect(find.byKey(const Key('replay-finish-match')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilLandscape(
  WidgetTester tester, {
  int attempts = 150,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    final physicalSize = tester.view.physicalSize;
    if (physicalSize.width > physicalSize.height) {
      await tester.pump(const Duration(milliseconds: 250));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Timed out waiting for the scoring view to enter landscape.');
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 150,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Timed out waiting for the expected widget.');
}
