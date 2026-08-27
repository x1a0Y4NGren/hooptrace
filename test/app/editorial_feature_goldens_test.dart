import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

import '../support/golden_fonts.dart';

void main() {
  setUpAll(() async {
    await loadHoopTraceGoldenFonts();
  });

  final features = <({String name, Size size, Widget Function() page})>[
    (
      name: 'pregame',
      size: const Size(390, 844),
      page: () => const PregamePage(),
    ),
    (
      name: 'scoring',
      size: const Size(731, 411),
      page: () => const ScoringPage(matchId: 'golden-scoring'),
    ),
    (
      name: 'replay',
      size: const Size(731, 411),
      page: () => ReplayPage(controller: _replayController()),
    ),
  ];

  for (final feature in features) {
    for (final locale in const [Locale('en'), Locale('zh')]) {
      for (final brightness in Brightness.values) {
        final mode = brightness == Brightness.light ? 'light' : 'dark';
        final name = '${feature.name}_${locale.languageCode}_$mode';
        testWidgets('editorial golden $name', (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = feature.size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
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
              theme: buildHoopTraceTheme(brightness: brightness),
              home: RepaintBoundary(
                key: const Key('editorial-feature-golden-root'),
                child: feature.page(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final renderedTheme = Theme.of(
            tester.element(
              find.byKey(const Key('editorial-feature-golden-root')),
            ),
          );
          expect(
            renderedTheme.textTheme.bodyMedium?.fontFamily,
            isNot('Noto Sans SC'),
            reason: 'Golden pages must retain the production body font.',
          );
          expect(
            renderedTheme.textTheme.bodyMedium?.fontFamilyFallback,
            contains('Noto Sans SC'),
            reason: 'Chinese must use the production fallback chain.',
          );
          await expectLater(
            find.byKey(const Key('editorial-feature-golden-root')),
            matchesGoldenFile(hoopTraceGoldenFile(name)),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}

ReplayController _replayController() => ReplayController(
  data: ReplayMatchData(
    matchId: 'golden-replay',
    blueName: 'Blue',
    redName: 'Red',
    blueScore: 2,
    redScore: 3,
    duration: const Duration(minutes: 8, seconds: 24),
    events: [
      ReplayEventData(
        id: 'golden-event-1',
        kind: ReplayEventKind.score,
        rawKind: EventKind.fieldGoal,
        side: TeamSide.blue,
        points: 2,
        outcome: ShotOutcome.made,
        elapsed: const Duration(seconds: 18),
        occurredAt: DateTime.utc(2026, 8, 26, 12),
      ),
      ReplayEventData(
        id: 'golden-event-2',
        kind: ReplayEventKind.score,
        rawKind: EventKind.fieldGoal,
        side: TeamSide.red,
        points: 3,
        outcome: ShotOutcome.made,
        elapsed: const Duration(seconds: 41),
        occurredAt: DateTime.utc(2026, 8, 26, 12, 0, 23),
      ),
    ],
  ),
);
