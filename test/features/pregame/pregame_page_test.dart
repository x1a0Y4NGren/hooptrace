import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';

void main() {
  testWidgets('pre-game page exposes fast start and advanced settings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PregamePage()));

    expect(find.text('赛前设置'), findsOneWidget);
    expect(find.text('球员'), findsOneWidget);
    expect(find.text('红方'), findsWidgets);
    expect(find.text('蓝方'), findsWidgets);
    expect(find.text('规则模板'), findsOneWidget);
    expect(find.text('自由计分'), findsOneWidget);
    expect(find.text('高级设置'), findsOneWidget);
    expect(find.text('计时'), findsOneWidget);
    expect(find.text('开始比赛'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('高级设置'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('高级设置'));
    await tester.pumpAndSettle();

    expect(find.text('目标分'), findsOneWidget);
    expect(find.text('时间限制'), findsNothing);
    expect(find.text('11分'), findsOneWidget);
    expect(find.text('10分钟'), findsNothing);
  });

  testWidgets('pre-game page accepts player names and starts match', (
    tester,
  ) async {
    String? startedRedName;
    String? startedBlueName;

    await tester.pumpWidget(
      MaterialApp(
        home: PregamePage(
          onStartMatch: (setup) {
            startedRedName = setup.redName;
            startedBlueName = setup.blueName;
          },
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('pregame-red-name')), 'Red A');
    await tester.enterText(
      find.byKey(const Key('pregame-blue-name')),
      'Blue B',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-recording-simple')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('pregame-recording-simple')));
    await tester.scrollUntilVisible(
      find.text('开始比赛'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始比赛'));

    expect(startedRedName, 'Red A');
    expect(startedBlueName, 'Blue B');
  });

  testWidgets('pre-game page exposes Chinese rule template options', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PregamePage()));

    await tester.tap(find.text('自由计分'));
    await tester.pumpAndSettle();

    expect(find.text('11 分制'), findsOneWidget);
    expect(find.text('21 分制'), findsOneWidget);
  });

  testWidgets('clearing a participant name blocks start with readable error', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (_) => started = true)),
    );

    await tester.enterText(find.byKey(const Key('pregame-red-name')), '');
    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-recording-simple')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('pregame-recording-simple')));
    await tester.scrollUntilVisible(
      find.text('开始比赛'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始比赛'));
    await tester.pump();

    expect(started, isFalse);
    expect(find.text('请输入红方姓名。'), findsOneWidget);
  });

  testWidgets('invalid countdown text never reuses an old value or starts', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (_) => started = true)),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-timer')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('pregame-timer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pregame-clock-countdown')));
    await tester.pump();

    final field = find.byKey(const Key('pregame-countdown-minutes'));
    for (final value in ['', '0', '181', 'abc']) {
      await tester.enterText(field, value);
      await tester.pump();
      expect(
        tester.widget<TextField>(field).controller!.text,
        value == 'abc' ? isEmpty : value,
      );
    }
    await tester.scrollUntilVisible(
      find.byKey(const Key('pregame-recording-simple')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('pregame-recording-simple')));
    await tester.scrollUntilVisible(
      find.text('开始比赛'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('开始比赛'));
    await tester.pump();

    expect(started, isFalse);
    expect(find.text('请输入 1 到 180 之间的整数分钟。'), findsOneWidget);
  });

  testWidgets(
    'recording and clock selection buttons expose selected semantics',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PregamePage()));
      final semantics = tester.getSemantics(
        find.byKey(const Key('pregame-recording-simple')),
      );
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isSelected, ui.Tristate.isFalse);

      await tester.tap(find.byKey(const Key('pregame-recording-simple')));
      await tester.pump();
      final selectedSemantics = tester.getSemantics(
        find.byKey(const Key('pregame-recording-simple')),
      );
      expect(selectedSemantics.flagsCollection.isButton, isTrue);
      expect(selectedSemantics.flagsCollection.isSelected, ui.Tristate.isTrue);
    },
  );
}
