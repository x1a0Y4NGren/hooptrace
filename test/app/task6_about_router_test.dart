import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/provider_router.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/features/home/home_page.dart';
import 'package:hooptrace/features/project/project_details_page.dart';
import 'package:hooptrace/features/settings/settings_page.dart';

import '../test_helpers/test_database.dart';

void main() {
  testWidgets('/about is canonical and /project keeps the same About content', (
    tester,
  ) async {
    final router = buildProviderAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(_routerApp(router));
    await tester.pumpAndSettle();

    router.go('/about');
    await tester.pumpAndSettle();
    expect(find.byType(ProjectDetailsPage), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('HOOPTRACE'), findsOneWidget);

    router.go('/project');
    await tester.pumpAndSettle();
    expect(find.byType(ProjectDetailsPage), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('HOOPTRACE'), findsOneWidget);
  });

  testWidgets('optional latest-result failure never blocks Home', (
    tester,
  ) async {
    final router = buildProviderAppRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatchProvider.overrideWith(
            (ref) => Stream<MatchDetail?>.value(null),
          ),
          latestFinishedMatchProvider.overrideWithValue(
            AsyncError<MatchDetail?>(
              StateError('history failed'),
              StackTrace.current,
            ),
          ),
        ],
        child: _materialRouter(router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byKey(homeStartScoringKey), findsOneWidget);
    expect(find.byKey(const Key('home-latest-result')), findsNothing);
  });

  testWidgets('Settings About row opens canonical /about', (tester) async {
    final database = createTestDatabase();
    final router = buildProviderAppRouter();
    addTearDown(router.dispose);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: _materialRouter(router),
      ),
    );
    await tester.pumpAndSettle();
    router.go('/settings');
    await tester.pumpAndSettle();

    final about = find.byKey(const Key('settings-about-row'));
    await tester.scrollUntilVisible(
      about,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(about);
    await tester.pump();
    final page = tester.widget<SettingsPage>(find.byType(SettingsPage));
    expect(page.onOpenProject, isNotNull);
    page.onOpenProject!();
    await tester.pumpAndSettle();

    expect(find.byType(ProjectDetailsPage), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}

Widget _routerApp(GoRouter router) {
  return ProviderScope(
    overrides: [
      activeMatchProvider.overrideWith(
        (ref) => Stream<MatchDetail?>.value(null),
      ),
      latestFinishedMatchProvider.overrideWithValue(
        const AsyncData<MatchDetail?>(null),
      ),
    ],
    child: _materialRouter(router),
  );
}

Widget _materialRouter(GoRouter router) => MaterialApp.router(
  locale: const Locale('en'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);
