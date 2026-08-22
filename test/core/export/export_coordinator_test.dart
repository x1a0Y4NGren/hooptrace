import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

import '../../test_helpers/test_database.dart';

void main() {
  group('ExportCoordinator', () {
    late AppDatabase database;
    late _MemoryExportGateway gateway;
    late _MemoryBackupStorage backupStorage;
    late AutomaticBackupService automaticBackup;
    late ExportCoordinator coordinator;
    late String replacementBackup;

    setUp(() async {
      replacementBackup = await withTestDatabase((source) async {
        await source.into(source.players).insert(
              PlayerRow(
                id: 'replacement',
                nickname: '新球员',
                createdAt: DateTime.utc(2026, 8, 20),
                preferredSide: null,
                note: null,
              ),
            );
        return JsonBackupCodec(
          source,
          appVersion: '0.1.0+1',
        ).export();
      });
      database = createTestDatabase();
      gateway = _MemoryExportGateway();
      backupStorage = _MemoryBackupStorage();
      final codec = JsonBackupCodec(
        database,
        appVersion: '0.1.0+1',
        now: () => DateTime.utc(2026, 8, 21, 10, 30),
      );
      automaticBackup = AutomaticBackupService(
        database,
        codec,
        storage: backupStorage,
        now: () => DateTime.utc(2026, 8, 21, 10, 30),
      );
      coordinator = ExportCoordinator(
        database,
        codec,
        gateway: gateway,
        automaticBackup: automaticBackup,
        now: () => DateTime.utc(2026, 8, 21, 10, 30),
      );
      await _seed(database);
    });

    test('shares a complete JSON backup with a stable filename', () async {
      await coordinator.shareJsonBackup();

      expect(gateway.shares, hasLength(1));
      final artifact = gateway.shares.single.single;
      expect(artifact.fileName, 'hooptrace-backup-20260821-103000.json');
      expect(artifact.mimeType, 'application/json');
      final root = jsonDecode(utf8.decode(artifact.bytes)) as Map;
      expect(
        (root['data'] as Map).keys,
        containsAll(<String>[
          'matches',
          'matchEvents',
          'shotLocations',
          'players',
          'ruleTemplates',
          'possessionSegments',
          'auditLogs',
          'appSettings',
        ]),
      );
    });

    test('shares match, event and player statistics CSV files', () async {
      await coordinator.shareCsvExports();

      final files = gateway.shares.single;
      expect(files.map((file) => file.fileName), [
        'hooptrace-matches-20260821-103000.csv',
        'hooptrace-events-20260821-103000.csv',
        'hooptrace-player-stats-20260821-103000.csv',
      ]);
      final stats = _decodeCsv(
        utf8.decode(files.last.bytes),
      );
      expect(stats[1], [
        'player-red',
        '赤焰',
        1,
        1,
        2,
        1,
        2,
        50.0,
      ]);
      expect(stats[2][0], '');
      expect(stats[2][1], '海浪');
    });

    test('restores picked JSON atomically and clears device backup approval',
        () async {
      backupStorage.availableDirectories.add('/approved');
      await automaticBackup.configureDirectory('/approved');
      await automaticBackup.enable();
      gateway.pickedBackup = ExportArtifact.text(
        fileName: 'incoming.json',
        mimeType: 'application/json',
        contents: replacementBackup,
      );

      expect(await coordinator.restorePickedBackup(), isTrue);

      expect(
        (await database.select(database.players).get()).single.id,
        'replacement',
      );
      final state = await automaticBackup.loadState();
      expect(state.enabled, isFalse);
      expect(state.directory, isNull);
    });

    test('returns false when the import picker is cancelled', () async {
      expect(await coordinator.restorePickedBackup(), isFalse);
    });

    test('shares replay PNG bytes without re-encoding', () async {
      final png = Uint8List.fromList([137, 80, 78, 71]);
      await coordinator.shareReplayImage(png, matchId: 'match:/1');

      final artifact = gateway.shares.single.single;
      expect(artifact.fileName, 'hooptrace-replay-match-1.png');
      expect(artifact.mimeType, 'image/png');
      expect(artifact.bytes, png);
    });
  });
}

List<List<dynamic>> _decodeCsv(String encoded) {
  return Csv(
    dynamicTyping: true,
    decoderTransform: (field, _, _) =>
        field is bool ? field.toString() : field,
  ).decode(encoded);
}

class _MemoryExportGateway implements ExportGateway {
  final shares = <List<ExportArtifact>>[];
  ExportArtifact? pickedBackup;
  BackupDirectorySelection? pickedDirectory;

  @override
  Future<ExportArtifact?> pickBackup() async => pickedBackup;

  @override
  Future<BackupDirectorySelection?> pickDirectory() async => pickedDirectory;

  @override
  Future<void> share(
    List<ExportArtifact> artifacts, {
    required String subject,
  }) async {
    shares.add(List.of(artifacts));
  }
}

class _MemoryBackupStorage implements AutomaticBackupStorage {
  final availableDirectories = <String>{};

  @override
  Future<bool> directoryExists(String path) async {
    return availableDirectories.contains(path);
  }

  @override
  Future<String> write({
    required String directory,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return '$directory/$fileName';
  }
}

Future<void> _seed(AppDatabase database) async {
  final startedAt = DateTime.utc(2026, 8, 21, 9);
  await database.into(database.matches).insert(
        Matche(
          id: 'match-1',
          redName: '赤焰',
          blueName: '海浪',
          status: 'finished',
          ruleTemplateJson: '{}',
          createdAt: startedAt,
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 5)),
          timerEnabled: true,
          note: null,
        ),
      );
  await database.batch((batch) {
    batch.insertAll(database.matchEvents, [
      MatchEventRow(
        id: 'event-made',
        matchId: 'match-1',
        type: 'score',
        side: 'red',
        points: 2,
        occurredAt: startedAt.add(const Duration(seconds: 10)),
        note: null,
        customEventType: null,
        isDeleted: false,
      ),
      MatchEventRow(
        id: 'event-miss',
        matchId: 'match-1',
        type: 'miss',
        side: 'red',
        points: 0,
        occurredAt: startedAt.add(const Duration(seconds: 15)),
        note: null,
        customEventType: null,
        isDeleted: false,
      ),
    ]);
    batch.insert(
      database.players,
      PlayerRow(
        id: 'player-red',
        nickname: '赤焰',
        createdAt: startedAt,
        preferredSide: 'red',
        note: null,
      ),
    );
  });
}
