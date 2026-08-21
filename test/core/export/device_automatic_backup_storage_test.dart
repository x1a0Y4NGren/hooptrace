import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/device_automatic_backup_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(DeviceAutomaticBackupStorage.channelName);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('uses the Android SAF channel for approved tree URIs', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'pickDirectory' => <String, Object?>{
            'reference': 'content://provider/tree/HoopTraceTest',
            'displayName': 'HoopTraceTest',
          },
        'directoryExists' => true,
        'writeBackup' => 'content://provider/document/backup.json',
        _ => throw MissingPluginException(call.method),
      };
    });
    final storage = DeviceAutomaticBackupStorage(useAndroidSaf: true);

    final selection = await storage.pickDirectory();
    expect(selection?.reference, 'content://provider/tree/HoopTraceTest');
    expect(selection?.displayName, 'HoopTraceTest');
    expect(await storage.directoryExists(selection!.reference), isTrue);
    expect(
      await storage.write(
        directory: selection.reference,
        fileName: 'backup.json',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
      'content://provider/document/backup.json',
    );
    expect(calls.map((call) => call.method), [
      'pickDirectory',
      'directoryExists',
      'writeBackup',
    ]);
    expect(
      (calls.last.arguments as Map<Object?, Object?>)['bytes'],
      Uint8List.fromList([1, 2, 3]),
    );
  });

  test('rejects legacy Android filesystem paths', () async {
    final storage = DeviceAutomaticBackupStorage(useAndroidSaf: true);

    expect(
      await storage.directoryExists('/storage/emulated/0/HoopTraceTest'),
      isFalse,
    );
    expect(
      () => storage.write(
        directory: '/storage/emulated/0/HoopTraceTest',
        fileName: 'backup.json',
        bytes: Uint8List(0),
      ),
      throwsA(isA<BackupDirectoryUnavailableException>()),
    );
  });
}
