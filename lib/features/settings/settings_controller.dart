import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';

class BackupRestoreBlockedException implements Exception {
  const BackupRestoreBlockedException();

  @override
  String toString() =>
      'Finish the active match before replacing local data from a backup.';
}

class SettingsController extends ChangeNotifier {
  SettingsController({
    required this.exports,
    required this.automaticBackup,
    this.canRestoreBackup = true,
  });

  final ExportCoordinator exports;
  final AutomaticBackupService automaticBackup;
  final bool canRestoreBackup;

  AutomaticBackupState _backupState =
      const AutomaticBackupState(enabled: false);
  bool _initialized = false;
  bool _busy = false;

  AutomaticBackupState get backupState => _backupState;
  bool get initialized => _initialized;
  bool get busy => _busy;

  Future<void> load() async {
    await _perform(() async {
      _backupState = await automaticBackup.loadState();
      _initialized = true;
    });
  }

  Future<void> shareJsonBackup() => _perform(exports.shareJsonBackup);

  Future<void> shareCsvExports() => _perform(exports.shareCsvExports);

  Future<bool> restoreBackup() {
    if (!canRestoreBackup) {
      throw const BackupRestoreBlockedException();
    }
    return _perform(() async {
      final restored = await exports.restorePickedBackup();
      if (restored) {
        _backupState = await automaticBackup.loadState();
      }
      return restored;
    });
  }

  Future<bool> configureBackupDirectory() {
    return _perform(() async {
      final directory = await exports.pickBackupDirectory();
      if (directory == null) return false;
      await automaticBackup.configureDirectory(directory);
      _backupState = await automaticBackup.loadState();
      return true;
    });
  }

  Future<bool> setAutomaticBackupEnabled(bool enabled) {
    return _perform(() async {
      if (enabled) {
        var directory = _backupState.directory;
        if (directory == null) {
          directory = await exports.pickBackupDirectory();
          if (directory == null) return false;
          await automaticBackup.configureDirectory(directory);
        }
        await automaticBackup.enable();
      } else {
        await automaticBackup.disable();
      }
      _backupState = await automaticBackup.loadState();
      return true;
    });
  }

  Future<String> runBackupNow() {
    return _perform(() async {
      final destination = await automaticBackup.runNow();
      _backupState = await automaticBackup.loadState();
      return destination;
    });
  }

  Future<T> _perform<T>(Future<T> Function() operation) async {
    if (_busy) {
      throw StateError('Another settings operation is still running.');
    }
    _busy = true;
    notifyListeners();
    try {
      return await operation();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
