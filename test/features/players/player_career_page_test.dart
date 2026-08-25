import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/domain/analytics/player_career_aggregate.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/features/players/player_career_controller.dart';
import 'package:hooptrace/features/players/player_career_page.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';

void main() {
  testWidgets('career avatar foreground meets normal-text contrast', (
    tester,
  ) async {
    final controller = PlayerCareerController(
      playerId: 'career-contrast',
      loader: (_) =>
          Stream.value(const PlayerCareerAggregate.empty('career-contrast')),
    );
    addTearDown(controller.dispose);
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildHoopTraceTheme(brightness: brightness),
          home: PlayerCareerPage(
            controller: controller,
            player: Player(
              id: 'career-contrast',
              nickname: 'Orange',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
            opponents: const [],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final avatar = tester.widget<CircleAvatar>(
        find.byKey(const Key('career-avatar-career-contrast')),
      );
      expect(
        _contrastRatio(avatar.foregroundColor!, avatar.backgroundColor!),
        greaterThanOrEqualTo(4.5),
        reason: '$brightness career avatar contrast',
      );
    }
  });
  testWidgets('career analytics stays usable across visual matrix', (
    tester,
  ) async {
    final controller = PlayerCareerController(
      playerId: 'matrix-player',
      loader: (_) =>
          Stream.value(const PlayerCareerAggregate.empty('matrix-player')),
    );
    addTearDown(controller.dispose);
    const locales = [Locale('zh'), Locale('en')];
    const sizes = [
      Size(390, 844),
      Size(731, 411),
      Size(1095, 616),
      Size(1920, 1080),
    ];
    for (final brightness in Brightness.values) {
      for (final locale in locales) {
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: MaterialApp(
                theme: buildHoopTraceTheme(brightness: brightness),
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: PlayerCareerPage(
                  controller: controller,
                  player: Player(
                    id: 'matrix-player',
                    nickname: 'Matrix',
                    createdAt: DateTime.utc(2026, 1, 1),
                  ),
                  opponents: const [],
                ),
              ),
            ),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(DoodleTitle), findsAtLeastNWidgets(2));
          expect(
            tester
                .getSize(find.byKey(const Key('career-window-sevenDays')))
                .height,
            greaterThanOrEqualTo(48),
          );
        }
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'career page leads with growth and supports time/opponent filters',
    (tester) async {
      final controller = PlayerCareerController(
        playerId: 'p1',
        loader: (_) => Stream.value(
          PlayerCareerAggregate(
            playerId: 'p1',
            matches: 4,
            wins: 3,
            totalPoints: 28,
            averagePoints: 7,
            averageMargin: 2.5,
            fieldGoalMade: 12,
            fieldGoalAttempts: 22,
            freeThrowMade: 4,
            freeThrowAttempts: 5,
            shootingTrend: [
              PlayerCareerShootingTrend(
                matchId: 'm1',
                playedAt: DateTime.utc(2026, 8, 1),
                fieldGoalMade: 3,
                fieldGoalAttempts: 6,
                freeThrowMade: 1,
                freeThrowAttempts: 1,
                recordedAttempts: 7,
                recordedMakes: 4,
                isTrustworthy: true,
              ),
            ],
            zoneHeatmap: const {ShotZone.paint: 4},
            recentChange: const PlayerCareerRecentChange.empty(),
          ),
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerCareerPage(
            controller: controller,
            player: Player(
              id: 'p1',
              nickname: '飞鱼',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
            opponents: [
              Player(
                id: 'p2',
                nickname: '小北',
                createdAt: DateTime.utc(2026, 1, 2),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('成长趋势'), findsOneWidget);
      expect(find.text('近 7 天'), findsOneWidget);
      expect(find.text('场均得分'), findsOneWidget);
      expect(find.text('投篮趋势'), findsOneWidget);
      expect(find.text('对手'), findsOneWidget);
      expect(find.textContaining('油漆区'), findsOneWidget);
      expect(find.text('飞鱼'), findsWidgets);
      expect(find.byType(DoodleTitle), findsAtLeastNWidgets(2));
      expect(find.byType(DoodleSurface), findsAtLeastNWidgets(3));
      expect(find.byType(DoodleDivider), findsAtLeastNWidgets(1));

      await tester.tap(find.text('近 7 天'));
      await tester.pump();
      expect(controller.query.window, PlayerCareerWindow.sevenDays);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'career page uses recorded shots when a percentage is not reliable',
    (tester) async {
      final controller = PlayerCareerController(
        playerId: 'p1',
        loader: (_) => Stream.value(const PlayerCareerAggregate.empty('p1')),
      );
      addTearDown(controller.dispose);
      await tester.binding.setSurfaceSize(const Size(360, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            home: PlayerCareerPage(
              controller: controller,
              player: Player(
                id: 'p1',
                nickname: 'Red',
                createdAt: DateTime.utc(2026, 1, 1),
              ),
              opponents: const [],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('暂无足够的完整出手记录，暂不显示命中率'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('career growth renders each available delta independently', (
    tester,
  ) async {
    final controller = PlayerCareerController(
      playerId: 'p1',
      loader: (_) => Stream.value(
        PlayerCareerAggregate(
          playerId: 'p1',
          matches: 2,
          wins: 1,
          totalPoints: 12,
          averagePoints: 6,
          averageMargin: 1,
          recentChange: const PlayerCareerRecentChange(
            latestMatchId: 'latest',
            previousMatchId: 'previous',
            latestPoints: 7,
            previousPoints: 5,
            latestMargin: null,
            previousMargin: null,
            latestShootingPercentage: null,
            previousShootingPercentage: null,
          ),
        ),
      ),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlayerCareerPage(
          controller: controller,
          player: Player(
            id: 'p1',
            nickname: 'Red',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
          opponents: const [],
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('+2.0'), findsOneWidget);
    expect(find.textContaining('场均分差'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'career uses a precise empty state when no shot locations exist',
    (tester) async {
      final controller = PlayerCareerController(
        playerId: 'p1',
        loader: (_) => Stream.value(
          PlayerCareerAggregate(
            playerId: 'p1',
            matches: 1,
            wins: 1,
            totalPoints: 10,
            averagePoints: 10,
            averageMargin: 3,
          ),
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerCareerPage(
            controller: controller,
            player: Player(
              id: 'p1',
              nickname: 'Red',
              createdAt: DateTime.utc(2026, 1, 1),
            ),
            opponents: const [],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('player-analytics-zone-empty')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('player-analytics-zone-empty')),
          matching: find.text('暂无位置数据'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'career complete data remains usable at 200 percent on narrow screens',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = PlayerCareerController(
        playerId: 'p1',
        loader: (_) => Stream.value(
          PlayerCareerAggregate(
            playerId: 'p1',
            matches: 4,
            wins: 3,
            totalPoints: 28,
            averagePoints: 7,
            averageMargin: 2.5,
            fieldGoalMade: 12,
            fieldGoalAttempts: 22,
            freeThrowMade: 4,
            freeThrowAttempts: 5,
            shootingTrend: [
              PlayerCareerShootingTrend(
                matchId: 'm1',
                playedAt: DateTime.utc(2026, 8, 1),
                fieldGoalMade: 3,
                fieldGoalAttempts: 6,
                freeThrowMade: 1,
                freeThrowAttempts: 1,
                recordedAttempts: 7,
                recordedMakes: 4,
                isTrustworthy: true,
              ),
            ],
            zoneHeatmap: const {
              ShotZone.restrictedArea: 2,
              ShotZone.paint: 4,
              ShotZone.midRange: 3,
              ShotZone.cornerThree: 1,
              ShotZone.wingThree: 2,
              ShotZone.topThree: 1,
            },
            recentChange: const PlayerCareerRecentChange(
              latestMatchId: 'latest',
              previousMatchId: 'previous',
              latestPoints: 8,
              previousPoints: 7,
              latestMargin: 3,
              previousMargin: 1,
              latestShootingPercentage: .6,
              previousShootingPercentage: .5,
            ),
          ),
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MaterialApp(
            home: PlayerCareerPage(
              controller: controller,
              player: Player(
                id: 'p1',
                nickname: 'Red',
                createdAt: DateTime.utc(2026, 1, 1),
              ),
              opponents: const [],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('成长趋势'), findsOneWidget);
      expect(find.text('出手区域'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
