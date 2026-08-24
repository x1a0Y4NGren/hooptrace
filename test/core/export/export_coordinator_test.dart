import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
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
        await source
            .into(source.players)
            .insert(
              PlayerRow(
                id: 'replacement',
                nickname: '新球员',
                createdAt: DateTime.utc(2026, 8, 20),
                preferredSide: null,
                note: null,
              ),
            );
        return JsonBackupCodec(source, appVersion: '0.1.0+1').export();
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
      await coordinator.shareJsonBackup(subject: 'HoopTrace full local backup');

      expect(gateway.shares, hasLength(1));
      final artifact = gateway.shares.single.single;
      expect(artifact.fileName, 'hooptrace-backup-20260821-103000.json');
      expect(artifact.mimeType, 'application/json');
      expect(gateway.subjects.single, 'HoopTrace full local backup');
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
      await coordinator.shareCsvExports(subject: 'HoopTrace CSV export');

      final files = gateway.shares.single;
      expect(files.map((file) => file.fileName), [
        'hooptrace-matches-20260821-103000.csv',
        'hooptrace-events-20260821-103000.csv',
        'hooptrace-player-stats-20260821-103000.csv',
      ]);
      final stats = _decodeCsv(utf8.decode(files.last.bytes));
      expect(stats[1], ['player-red', '赤焰', 1, 1, 2, 1, 2, 50.0]);
      expect(stats[2][0], '');
      expect(stats[2][1], '海浪');
      expect(gateway.subjects.single, 'HoopTrace CSV export');
    });

    test(
      'creates a safety backup before replace and clears backup approval',
      () async {
        backupStorage.availableDirectories.add('/approved');
        await automaticBackup.configureDirectory('/approved');
        await automaticBackup.enable();
        gateway.pickedBackup = ExportArtifact.text(
          fileName: 'incoming.json',
          mimeType: 'application/json',
          contents: replacementBackup,
        );

        expect(
          await coordinator.restorePickedBackup(
            safetySubject: 'HoopTrace safety backup before restore',
          ),
          isTrue,
        );

        expect(gateway.shares, hasLength(1));
        final safety = gateway.shares.single.single;
        expect(safety.fileName, 'hooptrace-safety-backup-20260821-103000.json');
        expect(
          (jsonDecode(utf8.decode(safety.bytes)) as Map<String, dynamic>),
          containsPair('manifest', isA<Map<String, dynamic>>()),
        );
        expect(
          (await database.select(database.players).get()).single.id,
          'replacement',
        );
        final state = await automaticBackup.loadState();
        expect(state.enabled, isFalse);
        expect(state.directory, isNull);
      },
    );

    test('rejects replacement while local active session exists', () async {
      await _seedActiveSession(database);
      gateway.pickedBackup = ExportArtifact.text(
        fileName: 'incoming.json',
        mimeType: 'application/json',
        contents: replacementBackup,
      );

      await expectLater(
        () => coordinator.restorePickedBackup(
          safetySubject: 'HoopTrace safety backup before restore',
        ),
        throwsA(isA<BackupRestoreBlockedException>()),
      );

      expect(gateway.pickBackupCalls, 0);
      expect(gateway.shares, isEmpty);
      expect(
        await database.select(database.activeSessions).get(),
        hasLength(1),
      );
    });

    test(
      'rejects replacement when an active session starts while picker is open',
      () async {
        gateway.pickedBackup = ExportArtifact.text(
          fileName: 'incoming.json',
          mimeType: 'application/json',
          contents: replacementBackup,
        );
        gateway.onPickBackup = () => _seedActiveSession(database);

        await expectLater(
          () => coordinator.restorePickedBackup(
            safetySubject: 'HoopTrace safety backup before restore',
          ),
          throwsA(isA<BackupRestoreBlockedException>()),
        );

        expect(gateway.pickBackupCalls, 1);
        expect(gateway.shares, isEmpty);
        expect(
          (await database.select(database.activeSessions).get()).single.matchId,
          'active-match',
        );
        expect(
          (await database.select(database.matches).get()).map((row) => row.id),
          containsAll(['match-1', 'active-match']),
        );
      },
    );

    test(
      'invalid replacement is rejected before creating safety backup',
      () async {
        gateway.pickedBackup = ExportArtifact.text(
          fileName: 'incoming.json',
          mimeType: 'application/json',
          contents: '{"manifest":{}}',
        );

        await expectLater(
          () => coordinator.restorePickedBackup(
            safetySubject: 'HoopTrace safety backup before restore',
          ),
          throwsA(isA<BackupException>()),
        );

        expect(gateway.shares, isEmpty);
        expect(
          (await database.select(database.matches).get()).single.id,
          'match-1',
        );
      },
    );

    test(
      'merge preserves a local active session and does not share safety',
      () async {
        await _seedActiveSession(database);
        gateway.pickedBackup = ExportArtifact.text(
          fileName: 'incoming.json',
          mimeType: 'application/json',
          contents: replacementBackup,
        );

        expect(
          await coordinator.restorePickedBackup(
            mode: RestoreMode.merge,
            safetySubject: 'HoopTrace safety backup before restore',
          ),
          isTrue,
        );

        expect(gateway.shares, isEmpty);
        expect(
          (await database.select(database.activeSessions).get()).single.matchId,
          'active-match',
        );
        expect(
          (await database.select(database.players).get()).map((row) => row.id),
          contains('replacement'),
        );
        expect((await automaticBackup.loadState()).dirty, isTrue);
      },
    );

    test('returns false when the import picker is cancelled', () async {
      expect(
        await coordinator.restorePickedBackup(
          safetySubject: 'HoopTrace safety backup before restore',
          pickerDialogTitle: '选择 HoopTrace 备份',
        ),
        isFalse,
      );
      expect(gateway.lastBackupDialogTitle, '选择 HoopTrace 备份');
    });

    test('forwards a localized directory picker title', () async {
      await coordinator.pickBackupDirectory(dialogTitle: '选择自动备份文件夹');

      expect(gateway.lastDirectoryDialogTitle, '选择自动备份文件夹');
    });

    test('shares replay PNG bytes without re-encoding', () async {
      final png = Uint8List.fromList([137, 80, 78, 71]);
      await coordinator.shareReplayImage(
        png,
        matchId: 'match:/1',
        subject: 'HoopTrace match replay',
      );

      final artifact = gateway.shares.single.single;
      expect(artifact.fileName, 'hooptrace-replay-match-1.png');
      expect(artifact.mimeType, 'image/png');
      expect(artifact.bytes, png);
      expect(gateway.subjects.single, 'HoopTrace match replay');
    });

    test('uses a caller-provided localized share subject', () async {
      await coordinator.shareJsonBackup(subject: '完整本地备份');

      expect(gateway.subjects.single, '完整本地备份');
    });
  });
}

List<List<dynamic>> _decodeCsv(String encoded) {
  return Csv(
    dynamicTyping: true,
    decoderTransform: (field, _, _) => field is bool ? field.toString() : field,
  ).decode(encoded);
}

class _MemoryExportGateway implements ExportGateway {
  final shares = <List<ExportArtifact>>[];
  final subjects = <String>[];
  ExportArtifact? pickedBackup;
  BackupDirectorySelection? pickedDirectory;
  String? lastBackupDialogTitle;
  String? lastDirectoryDialogTitle;
  int pickBackupCalls = 0;
  Future<void> Function()? onPickBackup;

  @override
  Future<ExportArtifact?> pickBackup({String? dialogTitle}) async {
    pickBackupCalls++;
    lastBackupDialogTitle = dialogTitle;
    await onPickBackup?.call();
    return pickedBackup;
  }

  @override
  Future<BackupDirectorySelection?> pickDirectory({String? dialogTitle}) async {
    lastDirectoryDialogTitle = dialogTitle;
    return pickedDirectory;
  }

  @override
  Future<void> share(
    List<ExportArtifact> artifacts, {
    required String subject,
  }) async {
    shares.add(List.of(artifacts));
    subjects.add(subject);
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
  await database
      .into(database.matches)
      .insert(
        Matche(
          id: 'match-1',
          lifecycle: 'finished',
          recordingMode: 'simple',
          trackingCoverage: 'scoresOnly',
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
        outcome: 'made',
        matchClockPositionSeconds: null,
        customLabel: null,
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
        outcome: 'missed',
        matchClockPositionSeconds: null,
        customLabel: null,
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
    batch.insertAll(database.matchParticipants, [
      const MatchParticipant(
        id: 'participant-red',
        matchId: 'match-1',
        side: 'red',
        nameSnapshot: '赤焰',
        playerProfileId: 'player-red',
      ),
      const MatchParticipant(
        id: 'participant-blue',
        matchId: 'match-1',
        side: 'blue',
        nameSnapshot: '海浪',
      ),
    ]);
  });
}

Future<void> _seedActiveSession(AppDatabase database) async {
  final startedAt = DateTime.utc(2026, 8, 21, 10);
  await database
      .into(database.matches)
      .insert(
        Matche(
          id: 'active-match',
          lifecycle: 'active',
          recordingMode: 'simple',
          trackingCoverage: 'scoresOnly',
          ruleTemplateJson: '{}',
          createdAt: startedAt,
          startedAt: startedAt,
          endedAt: null,
          timerEnabled: false,
          note: null,
        ),
      );
  await database.batch((batch) {
    batch.insertAll(database.matchParticipants, const [
      MatchParticipant(
        id: 'active-red',
        matchId: 'active-match',
        side: 'red',
        nameSnapshot: 'Red',
      ),
      MatchParticipant(
        id: 'active-blue',
        matchId: 'active-match',
        side: 'blue',
        nameSnapshot: 'Blue',
      ),
    ]);
    batch.insert(
      database.activeSessions,
      ActiveSession(
        id: 'active',
        matchId: 'active-match',
        claimedAtUtc: startedAt,
      ),
    );
  });
}
