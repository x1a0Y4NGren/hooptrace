import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/match.dart' as domain_match;
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/home/home_page.dart';

void main() {
  testWidgets('home exposes every shortcut and routes it in English', (
    tester,
  ) async {
    final calls = <String>[];
    await _pumpHome(
      tester,
      locale: const Locale('en'),
      onOpenHistory: () => calls.add('history'),
      onOpenPlayers: () => calls.add('players'),
      onOpenRules: () => calls.add('rules'),
      onOpenSettings: () => calls.add('settings'),
      onOpenProject: () => calls.add('project'),
    );

    for (final key in const [
      Key('home-history-shortcut'),
      Key('home-players-shortcut'),
      Key('home-rules-shortcut'),
      Key('home-settings-shortcut'),
      Key('home-project-shortcut'),
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('home-history-shortcut')));
    await tester.tap(find.byKey(const Key('home-players-shortcut')));
    await tester.tap(find.byKey(const Key('home-rules-shortcut')));
    await tester.tap(find.byKey(const Key('home-settings-shortcut')));
    await tester.tap(find.byKey(const Key('home-project-shortcut')));
    expect(calls, ['history', 'players', 'rules', 'settings', 'project']);
  });

  testWidgets('home shortcut labels use the active locale', (tester) async {
    await _pumpHome(tester, locale: const Locale('zh'));
    final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;

    expect(find.text(l10n.replayHistory), findsOneWidget);
    expect(find.text(l10n.playersTitle), findsOneWidget);
    expect(find.text(l10n.rulesTitle), findsOneWidget);
    expect(find.text(l10n.settings), findsOneWidget);
    expect(find.text(l10n.projectDetails), findsOneWidget);
  });

  testWidgets('home shortcuts form one column narrow and two columns wide', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    await _pumpHome(tester);
    final narrowXs = _shortcutXs(tester);
    expect(narrowXs.toSet(), hasLength(1));

    await _setSurface(tester, const Size(731, 411));
    await _pumpHome(tester);
    final wideXs = _shortcutXs(tester);
    expect(wideXs.toSet(), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'active match keeps resume, abandon, and start callbacks intact',
    (tester) async {
      var starts = 0;
      var resumes = 0;
      var abandons = 0;
      await _pumpHome(
        tester,
        activeMatch: _activeMatch,
        onStartScoring: () => starts++,
        onContinue: () => resumes++,
        onAbandon: () async => abandons++,
      );

      await tester.tap(find.byKey(homeResumeKey));
      await tester.tap(find.byKey(homeStartScoringKey));
      expect(resumes, 1);
      expect(starts, 1);

      await tester.ensureVisible(find.byKey(homeAbandonKey));
      await tester.tap(find.byKey(homeAbandonKey));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
      expect(find.text(l10n.homeAbandonTitle), findsOneWidget);
      await tester.tap(find.text(l10n.homeConfirmAbandon));
      expect(abandons, 1);
    },
  );

  testWidgets('home remains reachable with large text and an active match', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    await _pumpHome(
      tester,
      textScaler: const TextScaler.linear(2),
      activeMatch: _activeMatch,
    );
    expect(find.byKey(homeStartScoringKey), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('home-history-shortcut')));
    expect(find.byKey(const Key('home-history-shortcut')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  MatchDetail? activeMatch,
  VoidCallback? onOpenHistory,
  VoidCallback? onOpenPlayers,
  VoidCallback? onOpenRules,
  VoidCallback? onOpenSettings,
  VoidCallback? onOpenProject,
  VoidCallback? onStartScoring,
  VoidCallback? onContinue,
  Future<void> Function()? onAbandon,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildHoopTraceTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: HomePage(
        activeMatch: activeMatch,
        onStartScoring: onStartScoring ?? () {},
        onContinue: onContinue ?? () {},
        onAbandon: onAbandon ?? () async {},
        onOpenHistory: onOpenHistory ?? () {},
        onOpenPlayers: onOpenPlayers ?? () {},
        onOpenRules: onOpenRules ?? () {},
        onOpenSettings: onOpenSettings ?? () {},
        onOpenProject: onOpenProject ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _activeMatch = MatchDetail(
  match: domain_match.Match(
    id: 'home-test-active',
    lifecycle: MatchLifecycle.active,
    createdAt: DateTime.utc(2026, 8, 24, 12),
    startedAt: DateTime.utc(2026, 8, 24, 12),
    ruleTemplateSnapshot: const RuleTemplate(
      id: 'free',
      name: 'Free scoring',
      scoreButtons: [1, 2, 3],
    ),
    participants: const [
      domain_match.MatchParticipant(
        id: 'home-test-red',
        matchId: 'home-test-active',
        side: TeamSide.red,
        nameSnapshot: 'River',
      ),
      domain_match.MatchParticipant(
        id: 'home-test-blue',
        matchId: 'home-test-active',
        side: TeamSide.blue,
        nameSnapshot: 'Jordan',
      ),
    ],
  ),
  events: const [],
  shotLocations: const [],
  redScore: 11,
  blueScore: 9,
  redFouls: 1,
  blueFouls: 2,
  shotAttemptCount: 0,
  locatedShotCount: 0,
);

List<double> _shortcutXs(WidgetTester tester) {
  return [
    'home-history-shortcut',
    'home-players-shortcut',
    'home-rules-shortcut',
    'home-settings-shortcut',
  ].map((name) => tester.getCenter(find.byKey(Key(name))).dx).toList();
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}
