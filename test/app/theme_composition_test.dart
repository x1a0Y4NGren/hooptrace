import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
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

  testWidgets('app does not force Chinese locale', (tester) async {
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });

    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.locale, isNull);
    expect(materialApp.supportedLocales, contains(const Locale('en')));
    expect(materialApp.supportedLocales, contains(const Locale('zh')));
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
