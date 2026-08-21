import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';

class DeviceAutomaticBackupStorage
    implements AutomaticBackupStorage, AutomaticBackupReferencePolicy {
  DeviceAutomaticBackupStorage({
    AutomaticBackupStorage? fallback,
    bool? useAndroidSaf,
  })  : _fallback = fallback ?? const IoAutomaticBackupStorage(),
        _useAndroidSaf = useAndroidSaf ?? Platform.isAndroid;

  static const channelName = 'io.github.x1a0y4ngren.hooptrace/automatic_backup';
  static const _channel = MethodChannel(channelName);

  final AutomaticBackupStorage _fallback;
  final bool _useAndroidSaf;

  @override
  bool acceptsDirectoryReference(String reference) {
    return !_useAndroidSaf || _isContentUri(reference);
  }

  Future<BackupDirectorySelection?> pickDirectory() async {
    if (!_useAndroidSaf) return null;
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickDirectory',
    );
    final reference = result?['reference'];
    final displayName = result?['displayName'];
    if (reference is! String || reference.trim().isEmpty) return null;
    return BackupDirectorySelection(
      reference: reference,
      displayName: displayName is String && displayName.trim().isNotEmpty
          ? displayName
          : reference,
    );
  }

  @override
  Future<bool> directoryExists(String directory) async {
    if (!_useAndroidSaf) return _fallback.directoryExists(directory);
    if (!_isContentUri(directory)) return false;
    return await _channel.invokeMethod<bool>(
          'directoryExists',
          {'directory': directory},
        ) ??
        false;
  }

  @override
  Future<String> write({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (!_useAndroidSaf) {
      return _fallback.write(
        directory: directory,
        fileName: fileName,
        bytes: bytes,
      );
    }
    if (!_isContentUri(directory)) {
      throw BackupDirectoryUnavailableException(directory);
    }
    final destination = await _channel.invokeMethod<String>(
      'writeBackup',
      {
        'directory': directory,
        'fileName': fileName,
        'bytes': bytes,
      },
    );
    if (destination == null || destination.isEmpty) {
      throw const AutomaticBackupWriteException();
    }
    return destination;
  }

  static bool _isContentUri(String value) => value.startsWith('content://');
}
