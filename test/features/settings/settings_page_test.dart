import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/design_system/design_system.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';
import 'package:hooptrace/core/settings/language_preferences.dart';
import 'package:hooptrace/core/settings/theme_preferences.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';
import 'package:hooptrace/features/settings/settings_page.dart';

import '../../test_helpers/test_database.dart';

void main() {
  testWidgets('settings uses exactly five editorial groups in order', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
    final automaticBackup = AutomaticBackupService(
      database,
      codec,
      storage: _Storage(),
    );
    final controller = SettingsController(
      exports: ExportCoordinator(
        database,
        codec,
        gateway: _Gateway(),
        automaticBackup: automaticBackup,
      ),
      automaticBackup: automaticBackup,
      feedback: ScoringFeedbackService(
        ScoringFeedbackPreferencesRepository(database),
      ),
    );
    final language = LanguagePreferencesController(
      LanguagePreferencesRepository(database),
    );
    final theme = ThemePreferencesController(
      ThemePreferencesRepository(database),
    );
    addTearDown(controller.dispose);
    addTearDown(language.dispose);
    addTearDown(theme.dispose);
    await language.load();
    await theme.load();

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
        home: SettingsPage(
          controller: controller,
          languageController: language,
          themeController: theme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EditorialScaffold), findsOneWidget);
    expect(find.byType(EditorialMasthead), findsOneWidget);
    expect(find.byType(DoodleSurface), findsNothing);
    final labels = tester
        .widgetList<EditorialSectionRule>(find.byType(EditorialSectionRule))
        .map((rule) => rule.label)
        .whereType<String>()
        .toList();
    expect(labels, [
      'Appearance',
      'Scoring feedback',
      'Language',
      'Data',
      'About',
    ]);
    expect(find.text('Defaults'), findsNothing);
    expect(find.text('Statistics'), findsNothing);
    expect(find.text('Experimental'), findsNothing);
    expect(find.text('Developer diagnostics'), findsNothing);
  });

  testWidgets(
    'action rows expose disabled state and keep a single enabled tap owner',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = createTestDatabase();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
      });
      final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
      final automaticBackup = AutomaticBackupService(
        database,
        codec,
        storage: _Storage(),
      );
      final controller = SettingsController(
        exports: ExportCoordinator(
          database,
          codec,
          gateway: _Gateway(),
          automaticBackup: automaticBackup,
        ),
        automaticBackup: automaticBackup,
      );
      addTearDown(controller.dispose);
      var aboutCalls = 0;

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
          home: SettingsPage(
            controller: controller,
            onOpenProject: () => aboutCalls += 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backupNow = find.byKey(const Key('settings-backup-now-row'));
      await tester.scrollUntilVisible(backupNow, 300);
      await tester.ensureVisible(backupNow);
      final disabledSemantics = tester.getSemantics(backupNow);
      expect(disabledSemantics.flagsCollection.isButton, isTrue);
      expect(disabledSemantics.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(
        disabledSemantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isFalse,
      );
      expect(
        find.descendant(
          of: backupNow,
          matching: find.byKey(const Key('setting-disabled-cue')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: backupNow,
          matching: find.byIcon(Icons.arrow_forward),
        ),
        findsNothing,
      );
      expect(tester.getSize(backupNow).height, greaterThanOrEqualTo(48));

      final about = find.byKey(const Key('settings-about-row'));
      await tester.scrollUntilVisible(about, 300);
      await tester.ensureVisible(about);
      expect(tester.getSemantics(about).flagsCollection.isButton, isTrue);
      expect(
        tester.getSemantics(about).flagsCollection.isEnabled,
        ui.Tristate.isTrue,
      );
      _expectSingleTapOwner(tester, about);
      await tester.tap(about);
      expect(aboutCalls, 1);
    },
  );

  testWidgets('settings exposes usable local export and backup controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    final gateway = _Gateway();
    final storage = _Storage()..availableDirectories.add('/approved');
    final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
    final automaticBackup = AutomaticBackupService(
      database,
      codec,
      storage: storage,
    );
    final feedback = ScoringFeedbackService(
      ScoringFeedbackPreferencesRepository(database),
    );
    final controller = SettingsController(
      exports: ExportCoordinator(
        database,
        codec,
        gateway: gateway,
        automaticBackup: automaticBackup,
      ),
      automaticBackup: automaticBackup,
      feedback: feedback,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('scoring-feedback-haptic-switch')),
      240,
    );

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('scoring-feedback-haptic-switch')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('scoring-feedback-sound-switch')),
          )
          .value,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('scoring-feedback-haptic-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('scoring-feedback-sound-switch')));
    await tester.pumpAndSettle();
    expect((await feedback.load()).haptic, isFalse);
    expect((await feedback.load()).sound, isTrue);

    for (final title in [
      '导出完整备份',
      '从备份恢复',
      '导出 CSV',
      '自动备份',
      '备份位置',
      '立即备份',
      '自动备份保留数量',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('后续提供'), findsNothing);

    await tester.scrollUntilVisible(find.text('从备份恢复'), 200);
    await tester.tap(find.text('从备份恢复'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backup-mode-merge')), findsOneWidget);
    expect(find.byKey(const Key('backup-mode-replace')), findsOneWidget);
    expect(find.textContaining('合并导入'), findsOneWidget);
    expect(find.text('替换本机数据'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('导出 CSV'));
    await tester.tap(find.text('导出 CSV'));
    await tester.pumpAndSettle();
    expect(gateway.shareCalls, 1);

    gateway.pickedDirectory = const BackupDirectorySelection(
      reference: '/approved',
      displayName: 'HoopTrace backups',
    );
    await tester.ensureVisible(
      find.byKey(const Key('automatic-backup-switch')),
    );
    await tester.tap(find.byKey(const Key('automatic-backup-switch')));
    await tester.pumpAndSettle();
    expect(storage.writeCount, 1);
    expect(find.text('已开启'), findsWidgets);
  });

  testWidgets(
    'settings exposes localized motion preference and settings-only preview',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = createTestDatabase();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
      });
      final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
      final automaticBackup = AutomaticBackupService(
        database,
        codec,
        storage: _Storage(),
      );
      final feedback = ScoringFeedbackService(
        ScoringFeedbackPreferencesRepository(database),
      );
      final controller = SettingsController(
        exports: ExportCoordinator(
          database,
          codec,
          gateway: _Gateway(),
          automaticBackup: automaticBackup,
        ),
        automaticBackup: automaticBackup,
        feedback: feedback,
      );
      addTearDown(controller.dispose);

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
          home: SettingsPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('motion-preference-dropdown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('motion-preview')), findsOneWidget);
      expect(
        tester
            .widget<AnimatedContainer>(find.byKey(const Key('motion-preview')))
            .duration,
        const Duration(milliseconds: 180),
      );
      expect(
        find.text(
          'Reduced motion shortens transitions and removes decorative movement.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('motion-preference-dropdown')));
      await tester.pumpAndSettle();
      expect(find.text('Reduced motion'), findsWidgets);
      await tester.tap(find.text('Reduced motion').last);
      await tester.pumpAndSettle();

      expect((await feedback.load()).motion, MotionPreference.reduced);
      expect(find.text('Preview: reduced motion'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedContainer>(find.byKey(const Key('motion-preview')))
            .duration,
        const Duration(milliseconds: 120),
      );
      expect(
        tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
        Offset.zero,
      );
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      expect(
        tester.getSemantics(find.byKey(const Key('motion-preview'))).label,
        'Motion preview',
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    },
  );

  testWidgets('passes the active app locale to backup pickers', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    final gateway = _Gateway()
      ..pickedDirectory = const BackupDirectorySelection(
        reference: '/approved',
        displayName: 'Approved backups',
      );
    final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
    final automaticBackup = AutomaticBackupService(
      database,
      codec,
      storage: _Storage()..availableDirectories.add('/approved'),
    );
    final controller = SettingsController(
      exports: ExportCoordinator(
        database,
        codec,
        gateway: gateway,
        automaticBackup: automaticBackup,
      ),
      automaticBackup: automaticBackup,
    );
    addTearDown(controller.dispose);

    Widget app(Locale locale) => MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsPage(controller: controller),
    );

    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();
    final restoreTile = find.text('Restore from backup');
    await tester.scrollUntilVisible(restoreTile, -200);
    await tester.ensureVisible(restoreTile);
    await tester.tap(restoreTile);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('backup-mode-merge')));
    await tester.pumpAndSettle();
    expect(gateway.lastBackupDialogTitle, 'Choose a HoopTrace backup');

    final automaticBackupSwitch = find.byKey(
      const Key('automatic-backup-switch'),
    );
    await tester.scrollUntilVisible(automaticBackupSwitch, 200);
    await tester.ensureVisible(automaticBackupSwitch);
    await tester.tap(automaticBackupSwitch);
    await tester.pumpAndSettle();
    expect(gateway.lastDirectoryDialogTitle, 'Choose automatic backup folder');

    await tester.pumpWidget(app(const Locale('zh')));
    await tester.pumpAndSettle();
    final directoryTile = find.text('备份位置');
    await tester.scrollUntilVisible(directoryTile, 200);
    await tester.ensureVisible(directoryTile);
    await tester.tap(directoryTile);
    await tester.pumpAndSettle();
    expect(gateway.lastDirectoryDialogTitle, '选择自动备份文件夹');
  });

  testWidgets(
    'omits the language section when no language controller is supplied',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = createTestDatabase();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
      });
      final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
      final automaticBackup = AutomaticBackupService(
        database,
        codec,
        storage: _Storage(),
      );
      final controller = SettingsController(
        exports: ExportCoordinator(
          database,
          codec,
          gateway: _Gateway(),
          automaticBackup: automaticBackup,
        ),
        automaticBackup: automaticBackup,
      );
      addTearDown(controller.dispose);

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
          home: SettingsPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Language'), findsNothing);
    },
  );

  testWidgets('settings dropdown controls expose 48dp interaction targets', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
    final automaticBackup = AutomaticBackupService(
      database,
      codec,
      storage: _Storage(),
    );
    final controller = SettingsController(
      exports: ExportCoordinator(
        database,
        codec,
        gateway: _Gateway(),
        automaticBackup: automaticBackup,
      ),
      automaticBackup: automaticBackup,
      feedback: ScoringFeedbackService(
        ScoringFeedbackPreferencesRepository(database),
      ),
    );
    final language = LanguagePreferencesController(
      LanguagePreferencesRepository(database),
    );
    final theme = ThemePreferencesController(
      ThemePreferencesRepository(database),
    );
    addTearDown(controller.dispose);
    addTearDown(language.dispose);
    addTearDown(theme.dispose);
    await language.load();
    await theme.load();

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
        home: SettingsPage(
          controller: controller,
          languageController: language,
          themeController: theme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in [
      'motion-preference-dropdown',
      'language-preference-dropdown',
      'theme-preference-dropdown',
    ]) {
      expect(
        tester.getSize(find.byKey(Key(key))).shortestSide,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(find.byKey(Key(key))).rect.size.shortestSide,
        greaterThanOrEqualTo(48),
      );
    }
  });

  testWidgets(
    'settings stays usable across size, locale, theme, and scale matrix',
    (tester) async {
      final database = createTestDatabase();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
      });
      final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
      final automaticBackup = AutomaticBackupService(
        database,
        codec,
        storage: _Storage(),
      );
      final controller = SettingsController(
        exports: ExportCoordinator(
          database,
          codec,
          gateway: _Gateway(),
          automaticBackup: automaticBackup,
        ),
        automaticBackup: automaticBackup,
        feedback: ScoringFeedbackService(
          ScoringFeedbackPreferencesRepository(database),
        ),
      );
      addTearDown(controller.dispose);

      final cases = [
        (const Size(390, 844), const Locale('en'), Brightness.light, 1.0),
        (const Size(390, 844), const Locale('zh'), Brightness.dark, 1.0),
        (const Size(731, 411), const Locale('en'), Brightness.dark, 1.0),
        (const Size(731, 411), const Locale('zh'), Brightness.light, 2.0),
      ];
      for (final (size, locale, brightness, scale) in cases) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SettingsPage(controller: controller),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final about = find.byKey(const Key('settings-about-row'));
        await tester.scrollUntilVisible(
          about,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.getSize(about).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      }

      await tester.binding.setSurfaceSize(const Size(390, 1600));
      await controller.setMotionPreference(MotionPreference.reduced);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          theme: ThemeData(brightness: Brightness.dark),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: SettingsPage(controller: controller),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('减少动效'), findsOneWidget);
      expect(
        tester
            .widget<AnimatedContainer>(find.byKey(const Key('motion-preview')))
            .duration,
        Duration.zero,
      );
    },
  );
}

class _Gateway implements ExportGateway {
  BackupDirectorySelection? pickedDirectory;
  int shareCalls = 0;
  String? lastBackupDialogTitle;

  String? lastDirectoryDialogTitle;

  @override
  Future<ExportArtifact?> pickBackup({String? dialogTitle}) async {
    lastBackupDialogTitle = dialogTitle;
    return null;
  }

  @override
  Future<BackupDirectorySelection?> pickDirectory({String? dialogTitle}) async {
    lastDirectoryDialogTitle = dialogTitle;
    return pickedDirectory;
  }

  @override
  Future<void> share(
    List<ExportArtifact> artifacts, {
    required String subject,
  }) async {
    shareCalls++;
  }
}

void _expectSingleTapOwner(WidgetTester tester, Finder target) {
  final targetNode = tester.getSemantics(target);
  final tapNodes = <SemanticsNode>[];

  void visit(SemanticsNode node) {
    if (node.getSemanticsData().hasAction(ui.SemanticsAction.tap)) {
      tapNodes.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(targetNode);
  expect(tapNodes, hasLength(1));
  expect(tapNodes.single, same(targetNode));
}

class _Storage implements AutomaticBackupStorage {
  final availableDirectories = <String>{};
  int writeCount = 0;

  @override
  Future<bool> directoryExists(String path) async {
    return availableDirectories.contains(path);
  }

  @override
  Future<String> write({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async {
    writeCount++;
    return '$directory/$fileName';
  }
}
