import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooptrace/app/app_metadata.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/app_database_provider.dart';
import 'package:hooptrace/core/export/automatic_backup_scheduler.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/device_automatic_backup_storage.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

void main() {
  runApp(const HoopTraceApp());
}

/// WorkManager starts this entrypoint in a short-lived headless engine. It
/// opens the same Drift file and uses the registered storage-only SAF channel;
/// no activity or document picker is needed for a due backup.
@pragma('vm:entry-point')
Future<void> automaticBackupBackgroundMain() async {
  final completionChannel = MethodChannel(
    DeviceAutomaticBackupScheduler.backgroundChannelName,
  );
  AppDatabase? database;
  var outcome = 'retry';
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final databasePath =
        await DeviceAutomaticBackupStorage.resolveBackgroundDatabasePath();
    database = await openNativeAppDatabaseAt(File(databasePath));
    final storage = DeviceAutomaticBackupStorage(useAndroidSaf: true);
    final service = AutomaticBackupService(
      database,
      JsonBackupCodec(database, appVersion: hoopTraceAppVersion),
      storage: storage,
      scheduler: DeviceAutomaticBackupScheduler(useAndroid: true),
    );
    await service.runIfDue();
    outcome = 'success';
  } on BackupDirectoryNotConfiguredException {
    outcome = 'missing_authorization';
  } on BackupDirectoryUnavailableException {
    outcome = 'missing_authorization';
  } on Object {
    outcome = 'retry';
  } finally {
    try {
      await database?.close();
    } finally {
      await completionChannel.invokeMethod<void>('completed', {
        'outcome': outcome,
      });
    }
  }
}
