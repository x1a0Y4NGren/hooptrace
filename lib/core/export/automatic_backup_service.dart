import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:path/path.dart' as path;

sealed class AutomaticBackupException implements Exception {
  const AutomaticBackupException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class BackupDirectoryNotConfiguredException extends AutomaticBackupException {
  const BackupDirectoryNotConfiguredException()
      : super('Choose a backup directory before enabling automatic backup.');
}

class BackupDirectoryUnavailableException extends AutomaticBackupException {
  const BackupDirectoryUnavailableException(String directory)
      : super('The selected backup directory is unavailable: $directory');
}

class AutomaticBackupWriteException extends AutomaticBackupException {
  const AutomaticBackupWriteException()
      : super('The backup could not be written to the selected directory.');
}

class BackupDirectorySelection {
  const BackupDirectorySelection({
    required this.reference,
    required this.displayName,
  });

  final String reference;
  final String displayName;
}

class AutomaticBackupState {
  const AutomaticBackupState({
    required this.enabled,
    this.directory,
    this.directoryLabel,
    this.lastBackupAt,
    this.lastBackupPath,
  });

  final bool enabled;
  final String? directory;
  final String? directoryLabel;
  final DateTime? lastBackupAt;
  final String? lastBackupPath;

  bool get isConfigured => directory != null;
}

abstract interface class AutomaticBackupStorage {
  Future<bool> directoryExists(String path);

  Future<String> write({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  });
}

abstract interface class AutomaticBackupReferencePolicy {
  bool acceptsDirectoryReference(String reference);
}

class IoAutomaticBackupStorage implements AutomaticBackupStorage {
  const IoAutomaticBackupStorage();

  @override
  Future<bool> directoryExists(String path) => Directory(path).exists();

  @override
  Future<String> write({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final extension = path.extension(fileName);
    final baseName = path.basenameWithoutExtension(fileName);
    var destination = path.join(directory, fileName);
    var suffix = 1;
    while (await File(destination).exists()) {
      destination = path.join(directory, '$baseName-$suffix$extension');
      suffix++;
    }
    final temporary = File('$destination.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(destination);
    return destination;
  }
}

class AutomaticBackupService {
  AutomaticBackupService(
    this.database,
    this.codec, {
    AutomaticBackupStorage? storage,
    DateTime Function()? now,
  })  : storage = storage ?? const IoAutomaticBackupStorage(),
        now = now ?? DateTime.now;

  static const _enabledKey = 'backup.automatic.enabled';
  static const _directoryKey = 'backup.automatic.directory';
  static const _directoryLabelKey = 'backup.automatic.directoryLabel';
  static const _lastBackupAtKey = 'backup.automatic.lastBackupAt';
  static const _lastBackupPathKey = 'backup.automatic.lastBackupPath';
  static const _keys = {
    _enabledKey,
    _directoryKey,
    _directoryLabelKey,
    _lastBackupAtKey,
    _lastBackupPathKey,
  };

  final AppDatabase database;
  final JsonBackupCodec codec;
  final AutomaticBackupStorage storage;
  final DateTime Function() now;

  Future<bool> isEnabled() async => (await loadState()).enabled;

  Future<AutomaticBackupState> loadState() async {
    final query = database.select(database.appSettings)
      ..where((setting) => setting.key.isIn(_keys));
    final settings = {
      for (final row in await query.get()) row.key: jsonDecode(row.valueJson),
    };
    final rawDirectory = settings[_directoryKey];
    final rawDirectoryLabel = settings[_directoryLabelKey];
    var directory = rawDirectory is String && rawDirectory.trim().isNotEmpty
        ? rawDirectory
        : null;
    var directoryLabel =
        rawDirectoryLabel is String && rawDirectoryLabel.trim().isNotEmpty
            ? rawDirectoryLabel
            : null;
    var enabled = settings[_enabledKey] == true;
    final referencePolicy = storage is AutomaticBackupReferencePolicy
        ? storage as AutomaticBackupReferencePolicy
        : null;
    if (directory != null &&
        referencePolicy != null &&
        !referencePolicy.acceptsDirectoryReference(directory)) {
      await (database.delete(database.appSettings)
            ..where(
              (setting) => setting.key.isIn({
                _enabledKey,
                _directoryKey,
                _directoryLabelKey,
              }),
            ))
          .go();
      enabled = false;
      directory = null;
      directoryLabel = null;
    }
    final rawLastBackupAt = settings[_lastBackupAtKey];
    final rawLastBackupPath = settings[_lastBackupPathKey];
    return AutomaticBackupState(
      enabled: enabled,
      directory: directory,
      directoryLabel: directoryLabel,
      lastBackupAt: rawLastBackupAt is String
          ? DateTime.tryParse(rawLastBackupAt)?.toUtc()
          : null,
      lastBackupPath: rawLastBackupPath is String ? rawLastBackupPath : null,
    );
  }

  Future<void> configureDirectory(
    String directory, {
    String? displayName,
  }) async {
    final normalized = directory.trim();
    if (normalized.isEmpty) {
      throw const BackupDirectoryNotConfiguredException();
    }
    if (!await storage.directoryExists(normalized)) {
      throw BackupDirectoryUnavailableException(normalized);
    }
    final normalizedLabel = displayName?.trim();
    await database.transaction(() async {
      await _writeSetting(_directoryKey, normalized);
      await _writeSetting(
        _directoryLabelKey,
        normalizedLabel == null || normalizedLabel.isEmpty
            ? normalized
            : normalizedLabel,
      );
    });
  }

  Future<void> enable() async {
    final state = await loadState();
    final directory = state.directory;
    if (directory == null) {
      throw const BackupDirectoryNotConfiguredException();
    }
    if (!await storage.directoryExists(directory)) {
      throw BackupDirectoryUnavailableException(directory);
    }
    await runNow();
    await _writeSetting(_enabledKey, true);
  }

  Future<void> disable() => _writeSetting(_enabledKey, false);

  Future<String> runNow() async {
    final state = await loadState();
    final directory = state.directory;
    if (directory == null) {
      throw const BackupDirectoryNotConfiguredException();
    }
    if (!await storage.directoryExists(directory)) {
      throw BackupDirectoryUnavailableException(directory);
    }
    final timestamp = now().toUtc();
    final payload = await codec.export();
    late final String destination;
    try {
      destination = await storage.write(
        directory: directory,
        fileName: 'hooptrace-backup-${_fileTimestamp(timestamp)}.json',
        bytes: Uint8List.fromList(utf8.encode(payload)),
      );
    } on AutomaticBackupException {
      rethrow;
    } on Object {
      throw const AutomaticBackupWriteException();
    }
    await database.transaction(() async {
      await _writeSetting(
        _lastBackupAtKey,
        timestamp.toIso8601String(),
      );
      await _writeSetting(_lastBackupPathKey, destination);
    });
    return destination;
  }

  Future<String?> runIfEnabled() async {
    if (!await isEnabled()) return null;
    return runNow();
  }

  Future<void> resetAfterRestore() {
    return (database.delete(database.appSettings)
          ..where((setting) => setting.key.isIn(_keys)))
        .go();
  }

  Future<void> _writeSetting(String key, Object value) {
    return database.into(database.appSettings).insertOnConflictUpdate(
          AppSetting(
            key: key,
            valueJson: jsonEncode(value),
            updatedAt: now().toUtc(),
          ),
        );
  }

  static String _fileTimestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}'
        '${two(value.month)}${two(value.day)}-'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }
}
