import 'package:flutter/material.dart';
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
    expect(find.text('时间限制'), findsOneWidget);
    expect(find.text('11分'), findsOneWidget);
    expect(find.text('10分钟'), findsOneWidget);
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
}
