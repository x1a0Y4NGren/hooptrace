import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';

void main() {
  final redProfile = Player(
    id: 'player-red',
    nickname: '林红',
    createdAt: DateTime.utc(2026, 8, 23),
  );
  final blueProfile = Player(
    id: 'player-blue',
    nickname: '蓝波',
    createdAt: DateTime.utc(2026, 8, 23),
  );

  testWidgets('profile selectors keep profile identity and prevent reuse', (
    tester,
  ) async {
    MatchSetup? setup;
    await tester.pumpWidget(
      MaterialApp(
        home: PregamePage(
          players: [redProfile, blueProfile],
          onStartMatch: (value) => setup = value,
        ),
      ),
    );

    await _selectProfile(tester, 'pregame-red-profile', redProfile.nickname);
    expect(find.text('林红'), findsWidgets);

    await _selectProfile(tester, 'pregame-blue-profile', redProfile.nickname);
    expect(find.text('该球员档案已用于另一方，请选择其他档案。'), findsOneWidget);

    await _scrollTo(tester, find.byKey(const Key('pregame-recording-simple')));
    await tester.tap(find.byKey(const Key('pregame-recording-simple')));
    await _scrollTo(tester, find.text('开始比赛'));
    await tester.tap(find.text('开始比赛'));

    expect(setup?.redPlayerProfileId, redProfile.id);
    expect(setup?.bluePlayerProfileId, isNull);
    expect(setup?.redName, redProfile.nickname);
  });

  testWidgets('temporary names may be identical while profile ids stay empty', (
    tester,
  ) async {
    MatchSetup? setup;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (value) => setup = value)),
    );

    await tester.enterText(find.byKey(const Key('pregame-red-name')), 'Alex');
    await tester.enterText(find.byKey(const Key('pregame-blue-name')), 'Alex');
    await _scrollTo(tester, find.byKey(const Key('pregame-recording-simple')));
    await tester.tap(find.byKey(const Key('pregame-recording-simple')));
    await _scrollTo(tester, find.text('开始比赛'));
    await tester.tap(find.text('开始比赛'));

    expect(setup?.redName, 'Alex');
    expect(setup?.blueName, 'Alex');
    expect(setup?.redPlayerProfileId, isNull);
    expect(setup?.bluePlayerProfileId, isNull);
  });

  testWidgets('start is blocked with a readable error until mode is selected', (
    tester,
  ) async {
    var startCount = 0;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (_) => startCount++)),
    );

    await _scrollTo(tester, find.text('开始比赛'));
    await tester.tap(find.text('开始比赛'));

    expect(startCount, 0);
    await _scrollTo(tester, find.byKey(const Key('pregame-validation')));
    expect(find.text('请选择记录模式后再开始比赛。'), findsOneWidget);
    expect(find.text('recordingModeRequired'), findsNothing);
  });

  testWidgets('timer controls expose count-up and valid countdown settings', (
    tester,
  ) async {
    MatchSetup? setup;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (value) => setup = value)),
    );

    await _scrollTo(tester, find.byKey(const Key('pregame-timer')));
    await tester.tap(find.byKey(const Key('pregame-timer')));
    await _scrollTo(tester, find.byKey(const Key('pregame-clock-count-up')));
    expect(find.byKey(const Key('pregame-clock-count-up')), findsOneWidget);
    expect(find.byKey(const Key('pregame-clock-countdown')), findsOneWidget);

    await _scrollTo(tester, find.byKey(const Key('pregame-clock-countdown')));
    await tester.tap(find.byKey(const Key('pregame-clock-countdown')));
    await _scrollTo(tester, find.byKey(const Key('pregame-countdown-minutes')));
    await tester.enterText(
      find.byKey(const Key('pregame-countdown-minutes')),
      '15',
    );
    await _scrollTo(tester, find.byKey(const Key('pregame-recording-simple')));
    await tester.tap(find.byKey(const Key('pregame-recording-simple')));
    await _scrollTo(tester, find.text('开始比赛'));
    await tester.tap(find.text('开始比赛'));

    expect(setup?.timerEnabled, isTrue);
    expect(setup?.clockMode, ClockMode.countdown);
    expect(setup?.timeLimitMinutes, 15);
  });

  testWidgets('tracking coverage is carried into the final setup', (
    tester,
  ) async {
    MatchSetup? setup;
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(onStartMatch: (value) => setup = value)),
    );

    await _scrollTo(tester, find.byKey(const Key('pregame-tracking-coverage')));
    await tester.tap(find.byKey(const Key('pregame-tracking-coverage')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('投篮出手').last);
    await _scrollTo(
      tester,
      find.byKey(const Key('pregame-recording-detailed')),
    );
    await tester.tap(find.byKey(const Key('pregame-recording-detailed')));
    await _scrollTo(tester, find.text('开始比赛'));
    await tester.tap(find.text('开始比赛'));

    expect(setup?.recordingMode, RecordingMode.detailed);
    expect(setup?.trackingCoverage, TrackingCoverage.shotAttempts);
  });

  testWidgets('profile stream updates do not reset an in-progress name edit', (
    tester,
  ) async {
    final updatedProfile = Player(
      id: redProfile.id,
      nickname: '林红（已改名）',
      createdAt: redProfile.createdAt,
    );
    await tester.pumpWidget(
      MaterialApp(home: PregamePage(players: [redProfile])),
    );
    await tester.enterText(
      find.byKey(const Key('pregame-red-name')),
      '正在编辑的临时名',
    );

    await tester.pumpWidget(
      MaterialApp(home: PregamePage(players: [updatedProfile])),
    );
    expect(find.text('正在编辑的临时名'), findsOneWidget);
  });
}

Future<void> _selectProfile(
  WidgetTester tester,
  String key,
  String nickname,
) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nickname).last);
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}
