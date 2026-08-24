import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required this.exports,
    required this.automaticBackup,
    this.canRestoreBackup = true,
    this.feedback,
  });

  final ExportCoordinator exports;
  final AutomaticBackupService automaticBackup;
  final bool canRestoreBackup;
  final ScoringFeedbackService? feedback;

  AutomaticBackupState _backupState = const AutomaticBackupState(
    enabled: false,
  );
  ScoringFeedbackPreferences _feedbackState =
      const ScoringFeedbackPreferences.defaults();
  bool _initialized = false;
  bool _busy = false;

  AutomaticBackupState get backupState => _backupState;
  ScoringFeedbackPreferences get feedbackState => _feedbackState;
  bool get initialized => _initialized;
  bool get busy => _busy;

  Future<void> load() async {
    await _perform(() async {
      _backupState = await automaticBackup.loadState();
      if (feedback != null) _feedbackState = await feedback!.load();
      _initialized = true;
    });
  }

  Future<void> shareJsonBackup({required String subject}) =>
      _perform(() => exports.shareJsonBackup(subject: subject));

  Future<void> shareCsvExports({required String subject}) =>
      _perform(() => exports.shareCsvExports(subject: subject));

  Future<bool> restoreBackup({
    RestoreMode mode = RestoreMode.replace,
    required String safetySubject,
    String? pickerDialogTitle,
  }) {
    if (mode == RestoreMode.replace && !canRestoreBackup) {
      throw const BackupRestoreBlockedException();
    }
    return _perform(() async {
      final restored = await exports.restorePickedBackup(
        mode: mode,
        safetySubject: safetySubject,
        pickerDialogTitle: pickerDialogTitle,
      );
      if (restored) {
        _backupState = await automaticBackup.loadState();
        if (feedback != null) _feedbackState = await feedback!.reload();
      }
      return restored;
    });
  }

  Future<bool> configureBackupDirectory({String? dialogTitle}) {
    return _perform(() async {
      final directory = await exports.pickBackupDirectory(
        dialogTitle: dialogTitle,
      );
      if (directory == null) return false;
      await automaticBackup.configureDirectory(
        directory.reference,
        displayName: directory.displayName,
      );
      _backupState = await automaticBackup.loadState();
      return true;
    });
  }

  Future<bool> setAutomaticBackupEnabled(bool enabled, {String? dialogTitle}) {
    return _perform(() async {
      if (enabled) {
        if (_backupState.directory == null) {
          final directory = await exports.pickBackupDirectory(
            dialogTitle: dialogTitle,
          );
          if (directory == null) return false;
          await automaticBackup.configureDirectory(
            directory.reference,
            displayName: directory.displayName,
          );
        }
        await automaticBackup.enable();
      } else {
        await automaticBackup.disable();
      }
      _backupState = await automaticBackup.loadState();
      return true;
    });
  }

  Future<bool> setHapticFeedbackEnabled(bool enabled) {
    return _perform(() async {
      final service = feedback;
      _feedbackState = service == null
          ? _feedbackState.copyWith(haptic: enabled)
          : await service.setHapticEnabled(enabled);
      return true;
    });
  }

  Future<bool> setSoundFeedbackEnabled(bool enabled) {
    return _perform(() async {
      final service = feedback;
      _feedbackState = service == null
          ? _feedbackState.copyWith(sound: enabled)
          : await service.setSoundEnabled(enabled);
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

  Future<void> setBackupRetentionLimit(int value) {
    return _perform(() async {
      await automaticBackup.setRetentionLimit(value);
      _backupState = await automaticBackup.loadState();
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
