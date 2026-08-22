import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/device_automatic_backup_storage.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DeviceExportGateway implements ExportGateway {
  DeviceExportGateway({DeviceAutomaticBackupStorage? backupStorage})
    : backupStorage = backupStorage ?? DeviceAutomaticBackupStorage();

  final DeviceAutomaticBackupStorage backupStorage;

  @override
  Future<ExportArtifact?> pickBackup() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: '选择 HoopTrace 备份',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    return ExportArtifact(
      fileName: picked.name,
      mimeType: 'application/json',
      bytes: bytes,
    );
  }

  @override
  Future<BackupDirectorySelection?> pickDirectory() async {
    if (Platform.isAndroid) return backupStorage.pickDirectory();
    final directory = await FilePicker.getDirectoryPath(
      dialogTitle: '选择自动备份文件夹',
    );
    if (directory == null) return null;
    return BackupDirectorySelection(
      reference: directory,
      displayName: directory,
    );
  }

  @override
  Future<void> share(
    List<ExportArtifact> artifacts, {
    required String subject,
  }) async {
    final temporaryDirectory = await getTemporaryDirectory();
    final exportDirectory = Directory(
      path.join(temporaryDirectory.path, 'hooptrace-exports'),
    );
    await exportDirectory.create(recursive: true);
    final files = <XFile>[];
    for (final artifact in artifacts) {
      final file = File(path.join(exportDirectory.path, artifact.fileName));
      await file.writeAsBytes(artifact.bytes, flush: true);
      files.add(XFile(file.path, mimeType: artifact.mimeType));
    }
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: subject,
        text: subject,
        fileNameOverrides: artifacts
            .map((artifact) => artifact.fileName)
            .toList(),
      ),
    );
  }
}
