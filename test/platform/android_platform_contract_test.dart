import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();
  final mainActivity = File(
    'android/app/src/main/kotlin/io/github/x1a0y4ngren/hooptrace/MainActivity.kt',
  ).readAsStringSync();
  final storageDelegate = File(
    'android/app/src/main/kotlin/io/github/x1a0y4ngren/hooptrace/AutomaticBackupStorageDelegate.kt',
  ).readAsStringSync();
  final filePolicy = File(
    'android/app/src/main/kotlin/io/github/x1a0y4ngren/hooptrace/AutomaticBackupFilePolicy.kt',
  ).readAsStringSync();
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();
  final workManager = File(
    'android/app/src/main/kotlin/io/github/x1a0y4ngren/hooptrace/AutomaticBackupWorkManager.kt',
  ).readAsStringSync();
  final workPolicy = File(
    'android/app/src/main/kotlin/io/github/x1a0y4ngren/hooptrace/AutomaticBackupWorkPolicy.kt',
  ).readAsStringSync();
  final worker = File(
    'android/app/src/main/kotlin/io/github/x1a0y4ngren/hooptrace/AutomaticBackupWorker.kt',
  ).readAsStringSync();
  final dartEntrypoint = File('lib/main.dart').readAsStringSync();
  final dartStorage = File(
    'lib/core/export/device_automatic_backup_storage.dart',
  ).readAsStringSync();
  final dartScheduler = File(
    'lib/core/export/automatic_backup_scheduler.dart',
  ).readAsStringSync();

  test('Android enables the platform predictive-back callback', () {
    expect(manifest, contains('android:enableOnBackInvokedCallback="true"'));
  });

  test('Android activity applies an explicit edge-to-edge window policy', () {
    expect(mainActivity, contains('AndroidWindowPolicy.apply(window)'));
  });

  test('automatic retention only deletes ordinary JSON backup documents', () {
    expect(storageDelegate, contains('COLUMN_MIME_TYPE'));
    expect(filePolicy, contains('DocumentsContract.Document.MIME_TYPE_DIR'));
    expect(filePolicy, contains('application/json'));
    expect(storageDelegate, contains('isOwnedDocument'));
  });

  test(
    'automatic backup uses reboot-safe unique WorkManager and headless SAF bridge',
    () {
      expect(gradle, contains('androidx.work:work-runtime-ktx'));
      expect(workManager, contains('enqueueUniquePeriodicWork'));
      expect(workManager, contains('ExistingPeriodicWorkPolicy.KEEP'));
      // The worker deliberately uses a storage-only channel delegate. It must
      // not register activity plugins in a headless engine.
      expect(worker, isNot(contains('GeneratedPluginRegistrant')));
      expect(worker, contains('AutomaticBackupChannelDelegate'));
      expect(worker, contains('AutomaticBackupWorkPolicy.storageChannelName'));
      expect(
        worker,
        contains('AutomaticBackupWorkPolicy.completionChannelName'),
      );
      expect(worker, contains('getDir("flutter", Context.MODE_PRIVATE)'));
      expect(worker, contains('"hooptrace.sqlite"'));
      expect(worker, contains('Result.retry()'));
      expect(
        workPolicy,
        contains('io.github.x1a0y4ngren.hooptrace/automatic_backup_background'),
      );
      expect(dartEntrypoint, contains('automaticBackupBackgroundMain'));
      expect(dartEntrypoint, isNot(contains('DartPluginRegistrant')));
      expect(dartEntrypoint, contains('resolveBackgroundDatabasePath'));
      expect(
        dartEntrypoint,
        contains('openNativeAppDatabaseAt(File(databasePath))'),
      );
      expect(
        dartStorage,
        contains("invokeMethod<String>('backgroundDatabasePath')"),
      );
      expect(
        dartScheduler,
        contains(
          "'io.github.x1a0y4ngren.hooptrace/automatic_backup_background'",
        ),
      );
    },
  );
}
