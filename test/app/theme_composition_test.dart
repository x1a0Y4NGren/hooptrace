import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/core/settings/language_preferences.dart';
import 'package:hooptrace/core/settings/theme_preferences.dart';

import '../test_helpers/test_database.dart';

void main() {
  testWidgets('app theme mode is driven by the persisted preference', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });

    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    final container = ProviderScope.containerOf(context);
    final controller = container.read(themePreferencesControllerProvider);
    expect(controller.preference, AppThemePreference.system);

    await controller.setPreference(AppThemePreference.dark);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );

    await controller.setPreference(AppThemePreference.light);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
  });

  testWidgets('app defaults to Chinese when the system locale is English', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(() async {
      tester.platformDispatcher.clearLocaleTestValue();
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    tester.platformDispatcher.localeTestValue = const Locale('en');

    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('zh'));
    expect(find.text('\u5f00\u59cb\u8ba1\u5206'), findsOneWidget);
    expect(materialApp.supportedLocales, contains(const Locale('en')));
    expect(materialApp.supportedLocales, contains(const Locale('zh')));
  });

  testWidgets('an explicit English choice persists across app restarts', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(() async {
      tester.platformDispatcher.clearLocaleTestValue();
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    tester.platformDispatcher.localeTestValue = const Locale('en');

    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    final languageDropdown = find.byKey(
      const Key('language-preference-dropdown'),
    );
    expect(languageDropdown, findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(languageDropdown),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(languageDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    expect(find.text('Appearance'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, const Locale('en'));
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('a saved English choice gates localized startup content', (
    tester,
  ) async {
    final database = createTestDatabase();
    final repository = LanguagePreferencesRepository(database);
    await repository.save(AppLanguagePreference.english);
    final language = LanguagePreferencesController(repository);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          languagePreferencesControllerProvider.overrideWith((ref) => language),
        ],
        child: const HoopTraceApp(),
      ),
    );
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.byKey(const Key('home-start-scoring')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await language.load();
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
  });

  testWidgets('unsupported system locale falls back before title generation', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(() async {
      tester.platformDispatcher.clearLocaleTestValue();
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    tester.platformDispatcher.localeTestValue = const Locale('fr');

    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
