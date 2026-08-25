import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';
import 'package:hooptrace/features/settings/settings_page.dart';

import '../../test_helpers/test_database.dart';

void main() {
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
    final restoreListTile = find.ancestor(
      of: restoreTile,
      matching: find.byType(ListTile),
    );
    await tester.ensureVisible(restoreListTile);
    await tester.tap(restoreListTile);
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
