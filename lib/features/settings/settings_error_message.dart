import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/backup_merge_service.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

String settingsFriendlyError(Object error, AppLocalizations l10n) {
  if (error is BackupChecksumException) return l10n.settingsErrorChecksum;
  if (error is UnsupportedBackupSchemaException) {
    return l10n.settingsErrorFutureVersion;
  }
  if (error is BackupFormatException ||
      error is BackupValidationException ||
      error is BackupRestoreException) {
    return l10n.settingsErrorInvalidBackup;
  }
  if (error is BackupMergeException) return l10n.settingsErrorMerge;
  if (error is BackupDirectoryNotConfiguredException) {
    return l10n.settingsErrorDirectoryRequired;
  }
  if (error is BackupDirectoryUnavailableException) {
    return l10n.settingsErrorDirectoryUnavailable;
  }
  if (error is AutomaticBackupWriteException) {
    return l10n.settingsErrorBackupWrite;
  }
  if (error is BackupRestoreBlockedException) {
    return l10n.settingsErrorRestoreBlocked;
  }
  return l10n.settingsErrorGeneric;
}
