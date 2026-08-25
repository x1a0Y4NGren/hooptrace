import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:ui' as ui;
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/features/rules/rule_template_editor_page.dart';
import 'package:hooptrace/features/rules/rule_template_list_page.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';

import '../../test_helpers/test_database.dart';

void main() {
  testWidgets('rules list and editor stay usable across visual matrix', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = RuleTemplateRepository(database);
    await repository.ensureBuiltIns();
    const locales = [Locale('zh'), Locale('en')];
    const sizes = [Size(390, 844), Size(731, 411)];
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
                home: RuleTemplateListPage(repository: repository),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(DoodleTitle), findsOneWidget);
          expect(
            tester.getSize(find.byType(ListTile).first).height,
            greaterThanOrEqualTo(48),
          );

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
                home: RuleTemplateEditorPage(repository: repository),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byKey(const Key('rule-name'))).height,
            greaterThanOrEqualTo(48),
          );
        }
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('rule list row has one semantic action owner', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = RuleTemplateRepository(database);
    await repository.ensureBuiltIns();
    await repository.save(
      const RuleTemplate(
        id: 'custom-semantic',
        name: '自定义规则',
        scoreButtons: [1, 2, 3],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: RuleTemplateListPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('rule-template-custom-semantic'));
    expect(row, findsOneWidget);
    expect(
      tester
          .getSemantics(row)
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.byType(RuleTemplateEditorPage), findsOneWidget);
    semanticsHandle.dispose();
  });

  testWidgets('rule editor save has one semantic action owner', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final database = createTestDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: RuleTemplateEditorPage(
          repository: RuleTemplateRepository(database),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('rule-save')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final save = find.byKey(const Key('rule-save'));
    expect(save, findsOneWidget);
    expect(
      tester
          .getSemantics(save)
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('rule-name')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byKey(const Key('rule-name')), '自定义规则');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('rule-save')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('rule-save')));
    await tester.pumpAndSettle();
    final saveButton = find.byKey(const Key('rule-save'));
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.byType(RuleTemplateEditorPage), findsNothing);
    semanticsHandle.dispose();
  });

  testWidgets('built-in rule names follow the active locale', (tester) async {
    final database = createTestDatabase();
    final repository = RuleTemplateRepository(database);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: RuleTemplateListPage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Free scoring'), findsOneWidget);
    expect(find.byType(DoodleTitle), findsOneWidget);
    expect(find.byType(DoodleSurface), findsAtLeastNWidgets(4));
    expect(find.text('11 points (win by 2)'), findsOneWidget);
    expect(find.text('21 points'), findsOneWidget);
    expect(find.text('10-minute timed'), findsOneWidget);
    expect(find.text('自由计分'), findsNothing);
  });

  testWidgets('lists built-ins and persists a custom template from editor', (
    tester,
  ) async {
    final database = createTestDatabase();
    final repository = RuleTemplateRepository(database);
    await repository.ensureBuiltIns();

    await tester.pumpWidget(
      MaterialApp(home: RuleTemplateListPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('自由计分'), findsOneWidget);
    expect(find.text('11 分制（领先 2 分）'), findsOneWidget);
    expect(find.text('21 分制'), findsOneWidget);
    expect(find.text('10 分钟计时'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rule-add-custom')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('rule-name')), '训练规则');
    await tester.enterText(find.byKey(const Key('rule-target-score')), '15');
    await tester.enterText(find.byKey(const Key('rule-time-limit')), '7');
    await tester.enterText(find.byKey(const Key('rule-foul-limit')), '4');
    await tester.enterText(
      find.byKey(const Key('rule-score-buttons')),
      '1,3,5',
    );
    await tester.enterText(find.byKey(const Key('rule-event-types')), '抢断,盖帽');
    await tester.tap(find.byKey(const Key('rule-win-by-two')));
    await tester.tap(find.byKey(const Key('rule-possession-hint')));
    await tester.fling(find.byType(ListView), const Offset(0, -800), 1000);
    await tester.pumpAndSettle();
    expect(find.byType(DoodleDivider), findsOneWidget);
    expect(find.byType(DoodlePress), findsOneWidget);
    await tester.tap(find.byKey(const Key('rule-save')));
    await tester.pumpAndSettle();

    final custom = (await repository.listAll()).singleWhere(
      (template) => template.name == '训练规则',
    );
    expect(custom.targetScore, 15);
    expect(custom.timeLimitSeconds, 420);
    expect(custom.foulLimit, 4);
    expect(custom.scoreButtons, [1, 3, 5]);
    expect(custom.winByTwo, isTrue);
    expect(custom.possessionHintEnabled, isTrue);
    expect(custom.customEventTypes, ['抢断', '盖帽']);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    'policy selection is disabled without hints and persists when enabled',
    (tester) async {
      final database = createTestDatabase();
      final repository = RuleTemplateRepository(database);

      await tester.pumpWidget(
        MaterialApp(home: RuleTemplateEditorPage(repository: repository)),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('rule-possession-policy')),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        tester
            .widget<DropdownButtonFormField<PossessionPolicy>>(
              find.byKey(const Key('rule-possession-policy')),
            )
            .onChanged,
        isNull,
      );

      await tester.ensureVisible(find.byKey(const Key('rule-possession-hint')));
      await tester.tap(find.byKey(const Key('rule-possession-hint')));
      await tester.pump();

      expect(
        tester
            .widget<DropdownButtonFormField<PossessionPolicy>>(
              find.byKey(const Key('rule-possession-policy')),
            )
            .onChanged,
        isNotNull,
      );

      await tester.ensureVisible(
        find.byKey(const Key('rule-possession-policy')),
      );
      await tester.tap(find.byKey(const Key('rule-possession-policy')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('命中后交换'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('rule-possession-hint')));
      await tester.tap(find.byKey(const Key('rule-possession-hint')));
      await tester.pump();
      expect(
        tester
            .widget<DropdownButtonFormField<PossessionPolicy>>(
              find.byKey(const Key('rule-possession-policy')),
            )
            .onChanged,
        isNull,
      );
      expect(find.text('手动纠正'), findsOneWidget);
      expect(find.text('命中后交换'), findsNothing);

      await tester.tap(find.byKey(const Key('rule-possession-hint')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('rule-possession-policy')),
      );
      await tester.tap(find.byKey(const Key('rule-possession-policy')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('命中后交换'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('rule-name')),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byKey(const Key('rule-name')), '命中后交换规则');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('rule-save')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('rule-save')));
      await tester.pumpAndSettle();

      final saved = (await repository.listAll()).single;
      expect(saved.possessionHintEnabled, isTrue);
      expect(saved.possessionPolicy, PossessionPolicy.switchAfterMade);
    },
  );
}
