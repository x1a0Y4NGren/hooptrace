import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';

import '../../test_helpers/test_database.dart';

void main() {
  late AppDatabase database;
  late _Gateway gateway;
  late _Storage storage;
  late AutomaticBackupService automaticBackup;
  late SettingsController controller;

  setUp(() {
    database = createTestDatabase();
    gateway = _Gateway();
    storage = _Storage();
    final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
    automaticBackup = AutomaticBackupService(database, codec, storage: storage);
    controller = SettingsController(
      exports: ExportCoordinator(
        database,
        codec,
        gateway: gateway,
        automaticBackup: automaticBackup,
      ),
      automaticBackup: automaticBackup,
    );
  });

  tearDown(() async {
    controller.dispose();
  });

  test('loads disabled automatic backup state by default', () async {
    await controller.load();

    expect(controller.initialized, isTrue);
    expect(controller.backupState.enabled, isFalse);
    expect(controller.backupState.directory, isNull);
  });

  test(
    'enabling prompts for and stores a directory before first backup',
    () async {
      gateway.pickedDirectory = const BackupDirectorySelection(
        reference: '/approved',
        displayName: 'Approved backups',
      );
      storage.availableDirectories.add('/approved');
      await controller.load();

      expect(await controller.setAutomaticBackupEnabled(true), isTrue);

      expect(controller.backupState.enabled, isTrue);
      expect(controller.backupState.directory, '/approved');
      expect(controller.backupState.directoryLabel, 'Approved backups');
      expect(storage.writeCount, 1);
    },
  );

  test('cancelled directory picker leaves automatic backup disabled', () async {
    await controller.load();

    expect(await controller.setAutomaticBackupEnabled(true), isFalse);
    expect(controller.backupState.enabled, isFalse);
  });

  test('blocks restore while a match is active', () async {
    final blocked = SettingsController(
      exports: controller.exports,
      automaticBackup: automaticBackup,
      canRestoreBackup: false,
    );
    addTearDown(blocked.dispose);
    await blocked.load();

    expect(
      blocked.restoreBackup,
      throwsA(isA<BackupRestoreBlockedException>()),
    );
  });
}

class _Gateway implements ExportGateway {
  BackupDirectorySelection? pickedDirectory;

  @override
  Future<ExportArtifact?> pickBackup() async => null;

  @override
  Future<BackupDirectorySelection?> pickDirectory() async => pickedDirectory;

  @override
  Future<void> share(
    List<ExportArtifact> artifacts, {
    required String subject,
  }) async {}
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
