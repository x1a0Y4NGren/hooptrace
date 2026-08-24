import 'dart:io';

import 'package:flutter/services.dart';

/// Durable scheduling is optional so the export service remains testable and
/// usable on platforms without an Android WorkManager implementation.
abstract interface class AutomaticBackupScheduler {
  Future<void> ensureScheduled();

  Future<void> cancel();
}

class NoopAutomaticBackupScheduler implements AutomaticBackupScheduler {
  const NoopAutomaticBackupScheduler();

  @override
  Future<void> ensureScheduled() async {}

  @override
  Future<void> cancel() async {}
}

class DeviceAutomaticBackupScheduler implements AutomaticBackupScheduler {
  DeviceAutomaticBackupScheduler({bool? useAndroid})
    : _useAndroid = useAndroid ?? Platform.isAndroid;

  static const channelName = 'io.github.x1a0y4ngren.hooptrace/automatic_backup';
  static const backgroundChannelName =
      'io.github.x1a0y4ngren.hooptrace/automatic_backup_background';
  static const _channel = MethodChannel(channelName);

  final bool _useAndroid;

  @override
  Future<void> ensureScheduled() async {
    if (!_useAndroid) return;
    await _channel.invokeMethod<void>('scheduleAutomaticBackup');
  }

  @override
  Future<void> cancel() async {
    if (!_useAndroid) return;
    await _channel.invokeMethod<void>('cancelAutomaticBackup');
  }
}
