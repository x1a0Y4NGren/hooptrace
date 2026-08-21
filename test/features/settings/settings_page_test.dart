import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';
import 'package:hooptrace/features/settings/settings_page.dart';

void main() {
  testWidgets('settings exposes usable local export and backup controls',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final gateway = _Gateway();
    final storage = _Storage()..availableDirectories.add('/approved');
    final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
    final automaticBackup = AutomaticBackupService(
      database,
      codec,
      storage: storage,
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

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(controller: controller)),
    );
    await tester.pumpAndSettle();

    for (final title in [
      '导出完整备份',
      '从备份恢复',
      '导出 CSV',
      '自动备份',
      '备份位置',
      '立即备份',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('后续提供'), findsNothing);

    await tester.ensureVisible(find.text('导出 CSV'));
    await tester.tap(find.text('导出 CSV'));
    await tester.pumpAndSettle();
    expect(gateway.shareCalls, 1);

    gateway.pickedDirectory = const BackupDirectorySelection(
      reference: '/approved',
      displayName: 'HoopTrace backups',
    );
    await tester
        .ensureVisible(find.byKey(const Key('automatic-backup-switch')));
    await tester.tap(find.byKey(const Key('automatic-backup-switch')));
    await tester.pumpAndSettle();
    expect(storage.writeCount, 1);
    expect(find.text('已开启'), findsOneWidget);
  });
}

class _Gateway implements ExportGateway {
  BackupDirectorySelection? pickedDirectory;
  int shareCalls = 0;

  @override
  Future<ExportArtifact?> pickBackup() async => null;

  @override
  Future<BackupDirectorySelection?> pickDirectory() async => pickedDirectory;

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
