import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

void main() {
  group('AutomaticBackupService', () {
    late AppDatabase database;
    late _MemoryBackupStorage storage;
    late AutomaticBackupService service;

    setUp(() {
      database = AppDatabase.inMemory();
      storage = _MemoryBackupStorage();
      service = AutomaticBackupService(
        database,
        JsonBackupCodec(
          database,
          appVersion: '0.1.0+1',
          now: () => DateTime.utc(2026, 8, 21, 9, 5, 7),
        ),
        storage: storage,
        now: () => DateTime.utc(2026, 8, 21, 9, 5, 7),
      );
    });

    tearDown(() => database.close());

    test('is disabled by default and cannot enable without a directory',
        () async {
      expect(await service.isEnabled(), isFalse);
      expect(
        service.enable,
        throwsA(isA<BackupDirectoryNotConfiguredException>()),
      );
    });

    test('configures a user-approved directory before enabling', () async {
      storage.availableDirectories.add('/approved');

      await service.configureDirectory('/approved');
      await service.enable();

      final state = await service.loadState();
      expect(state.enabled, isTrue);
      expect(state.directory, '/approved');
      expect(storage.files, hasLength(1));
      expect(
        storage.files.single.fileName,
        'hooptrace-backup-20260821-090507.json',
      );
      expect(
        jsonDecode(utf8.decode(storage.files.single.bytes)),
        isA<Map<String, dynamic>>(),
      );
    });

    test('runNow writes a complete backup and records last success', () async {
      storage.availableDirectories.add('/approved');
      await service.configureDirectory('/approved');

      final path = await service.runNow();

      expect(path, '/approved/hooptrace-backup-20260821-090507.json');
      final state = await service.loadState();
      expect(state.enabled, isFalse);
      expect(state.lastBackupAt, DateTime.utc(2026, 8, 21, 9, 5, 7));
      expect(state.lastBackupPath, path);
    });

    test('disable prevents runIfEnabled and reset clears imported metadata',
        () async {
      storage.availableDirectories.add('/approved');
      await service.configureDirectory('/approved');
      await service.enable();
      await service.disable();
      storage.files.clear();

      expect(await service.runIfEnabled(), isNull);
      await service.resetAfterRestore();
      final state = await service.loadState();
      expect(state.enabled, isFalse);
      expect(state.directory, isNull);
    });

    test('IO storage never overwrites a backup with the same filename',
        () async {
      final directory = await Directory.systemTemp.createTemp(
        'hooptrace-backup-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      const ioStorage = IoAutomaticBackupStorage();

      final first = await ioStorage.write(
        directory: directory.path,
        fileName: 'backup.json',
        bytes: Uint8List.fromList([1]),
      );
      final second = await ioStorage.write(
        directory: directory.path,
        fileName: 'backup.json',
        bytes: Uint8List.fromList([2]),
      );

      expect(second, isNot(first));
      expect(await File(first).readAsBytes(), [1]);
      expect(await File(second).readAsBytes(), [2]);
    });
  });
}

class _MemoryBackupStorage implements AutomaticBackupStorage {
  final availableDirectories = <String>{};
  final files = <_WrittenBackup>[];

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
    files.add(_WrittenBackup(fileName, bytes));
    return '$directory/$fileName';
  }
}

class _WrittenBackup {
  const _WrittenBackup(this.fileName, this.bytes);

  final String fileName;
  final Uint8List bytes;
}
