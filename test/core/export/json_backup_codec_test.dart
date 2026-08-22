import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

import '../../test_helpers/test_database.dart';

void main() {
  group('JsonBackupCodec', () {
    test('round-trips all eleven persisted table groups', () async {
      final exported = await withTestDatabase((source) async {
        await _seedCompleteBackup(source);
        return JsonBackupCodec(
          source,
          appVersion: '0.1.0+1',
          now: () => DateTime.utc(2026, 7, 18, 9, 30),
        ).export();
      });
      final restored = createTestDatabase();
      final exportedAt = DateTime.utc(2026, 7, 18, 9, 30);
      await JsonBackupCodec(restored, appVersion: '0.1.0+1').restore(exported);

      final document = jsonDecode(exported) as Map<String, dynamic>;
      final manifest = document['manifest'] as Map<String, dynamic>;
      expect(manifest['appName'], 'HoopTrace');
      expect(manifest['appVersion'], '0.1.0+1');
      expect(manifest['schemaVersion'], restored.schemaVersion);
      expect(manifest['exportedAt'], exportedAt.toIso8601String());
      expect(manifest['recordCounts'], {
        'matches': 1,
        'matchParticipants': 2,
        'matchClocks': 0,
        'activeSessions': 0,
        'matchEvents': 1,
        'shotLocations': 1,
        'players': 1,
        'ruleTemplates': 1,
        'possessionSegments': 1,
        'auditLogs': 1,
        'appSettings': 1,
      });
      expect(manifest['checksum'], matches(RegExp(r'^[a-f0-9]{64}$')));

      expect(
        (await restored.select(restored.matches).get()).single.id,
        'match-1',
      );
      expect(
        (await restored.select(restored.matchEvents).get()).single.id,
        'event-1',
      );
      expect(
        (await restored.select(restored.shotLocations).get()).single.x,
        0.25,
      );
      expect(
        (await restored.select(restored.players).get()).single.nickname,
        'A, "Ace"',
      );
      expect(
        (await restored.select(restored.ruleTemplates).get()).single.name,
        'Race to 11',
      );
      expect(
        (await restored.select(restored.possessionSegments).get())
            .single
            .startedAtEventId,
        'event-1',
      );
      expect(
        (await restored.select(restored.auditLogs).get()).single.targetId,
        'event-1',
      );
      expect(
        (await restored.select(restored.appSettings).get()).single.key,
        'theme',
      );
    });

    test('uses deterministic payload ordering', () async {
      final database = createTestDatabase();
      await _seedCompleteBackup(database);
      final codec = JsonBackupCodec(
        database,
        appVersion: '0.1.0+1',
        now: () => DateTime.utc(2026, 7, 18),
      );

      expect(await codec.export(), await codec.export());
    });

    test('rejects a future schema with a typed exception', () async {
      final database = createTestDatabase();
      final codec = JsonBackupCodec(
        database,
        appVersion: '0.1.0+1',
        now: () => DateTime.utc(2026, 7, 18),
      );
      final document = jsonDecode(await codec.export()) as Map<String, dynamic>;
      final manifest = document['manifest'] as Map<String, dynamic>;
      manifest['schemaVersion'] = database.schemaVersion + 1;

      expect(
        () => codec.restore(jsonEncode(document)),
        throwsA(
          isA<UnsupportedBackupSchemaException>().having(
            (error) => error.schemaVersion,
            'schemaVersion',
            database.schemaVersion + 1,
          ),
        ),
      );
    });

    test(
      'rejects a modified payload with a typed checksum exception',
      () async {
        final database = createTestDatabase();
        await _seedCompleteBackup(database);
        final codec = JsonBackupCodec(database, appVersion: '0.1.0+1');
        final document =
            jsonDecode(await codec.export()) as Map<String, dynamic>;
        final data = document['data'] as Map<String, dynamic>;
        final events = data['matchEvents'] as List<dynamic>;
        (events.single as Map<String, dynamic>)['points'] = 3;

        expect(
          () => codec.restore(jsonEncode(document)),
          throwsA(isA<BackupChecksumException>()),
        );
      },
    );

    test('fully validates before replacing existing local data', () async {
      final exported = await withTestDatabase((source) async {
        await _seedCompleteBackup(source);
        return JsonBackupCodec(source, appVersion: '0.1.0+1').export();
      });
      final destination = createTestDatabase();
      await destination
          .into(destination.matches)
          .insert(
            Matche(
              id: 'keep-me',
              lifecycle: 'active',
              recordingMode: 'simple',
              trackingCoverage: 'scoresOnly',
              ruleTemplateJson: '{}',
              createdAt: DateTime.utc(2026, 7, 17),
              startedAt: null,
              endedAt: null,
              timerEnabled: false,
              note: null,
            ),
          );
      final document = jsonDecode(exported) as Map<String, dynamic>;
      final data = document['data'] as Map<String, dynamic>;
      final events = data['matchEvents'] as List<dynamic>;
      (events.single as Map<String, dynamic>)['matchId'] = 'missing-match';
      _refreshChecksum(document);

      await expectLater(
        JsonBackupCodec(
          destination,
          appVersion: '0.1.0+1',
        ).restore(jsonEncode(document)),
        throwsA(isA<BackupValidationException>()),
      );
      final matches = await destination.select(destination.matches).get();
      expect(matches.map((match) => match.id), ['keep-me']);
      expect(await destination.select(destination.matchEvents).get(), isEmpty);
    });

    test(
      'rejects invalid domain values before replacing existing data',
      () async {
        final exported = await withTestDatabase((source) async {
          await _seedCompleteBackup(source);
          return JsonBackupCodec(source, appVersion: '0.1.0+1').export();
        });
        final destination = createTestDatabase();
        await destination
            .into(destination.players)
            .insert(
              PlayerRow(
                id: 'keep-player',
                nickname: '本机球员',
                createdAt: DateTime.utc(2026, 7, 17),
                preferredSide: null,
                note: null,
              ),
            );
        final document = jsonDecode(exported) as Map<String, dynamic>;
        final data = document['data'] as Map<String, dynamic>;
        final events = data['matchEvents'] as List<dynamic>;
        (events.single as Map<String, dynamic>)['side'] = 'green';
        final locations = data['shotLocations'] as List<dynamic>;
        (locations.single as Map<String, dynamic>)['x'] = 1.5;
        _refreshChecksum(document);

        await expectLater(
          JsonBackupCodec(
            destination,
            appVersion: '0.1.0+1',
          ).restore(jsonEncode(document)),
          throwsA(isA<BackupValidationException>()),
        );
        expect(
          (await destination.select(destination.players).get()).single.id,
          'keep-player',
        );
        expect(await destination.select(destination.matches).get(), isEmpty);
      },
    );

    test('rolls back replacement when a database write fails', () async {
      final exported = await withTestDatabase((source) async {
        await _seedCompleteBackup(source);
        return JsonBackupCodec(source, appVersion: '0.1.0+1').export();
      });
      final destination = createTestDatabase();
      await destination
          .into(destination.matches)
          .insert(
            Matche(
              id: 'keep-me',
              lifecycle: 'active',
              recordingMode: 'simple',
              trackingCoverage: 'scoresOnly',
              ruleTemplateJson: '{}',
              createdAt: DateTime.utc(2026, 7, 17),
              startedAt: null,
              endedAt: null,
              timerEnabled: false,
              note: null,
            ),
          );
      await destination.customStatement('''
        CREATE TRIGGER reject_restored_match
        BEFORE INSERT ON matches
        WHEN NEW.id = 'match-1'
        BEGIN
          SELECT RAISE(ABORT, 'forced restore failure');
        END;
      ''');
      await expectLater(
        JsonBackupCodec(destination, appVersion: '0.1.0+1').restore(exported),
        throwsA(isA<BackupRestoreException>()),
      );
      final matches = await destination.select(destination.matches).get();
      expect(matches.map((match) => match.id), ['keep-me']);
    });
  });
}

void _refreshChecksum(Map<String, dynamic> document) {
  final manifest = document['manifest'] as Map<String, dynamic>;
  final checksumSource = Map<String, dynamic>.from(manifest)
    ..remove('checksum');
  final encoded = jsonEncode({
    'manifest': checksumSource,
    'data': document['data'],
  });
  manifest['checksum'] = sha256.convert(utf8.encode(encoded)).toString();
}

Future<void> _seedCompleteBackup(AppDatabase database) async {
  final createdAt = DateTime.utc(2026, 7, 18, 8);
  await database
      .into(database.matches)
      .insert(
        Matche(
          id: 'match-1',
          lifecycle: 'finished',
          recordingMode: 'simple',
          trackingCoverage: 'scoresOnly',
          ruleTemplateJson: jsonEncode({
            'id': 'rule-1',
            'name': 'Race to 11',
            'scoreButtons': [1, 2, 3],
            'targetScore': 11,
            'timeLimitSeconds': null,
            'winByTwo': true,
            'foulLimit': null,
            'possessionHintEnabled': false,
            'customEventTypes': <String>[],
          }),
          createdAt: createdAt,
          startedAt: createdAt,
          endedAt: createdAt.add(const Duration(minutes: 8)),
          timerEnabled: false,
          note: 'final',
        ),
      );
  await database
      .into(database.matchEvents)
      .insert(
        MatchEventRow(
          id: 'event-1',
          matchId: 'match-1',
          type: 'score',
          side: 'red',
          points: 2,
          occurredAt: createdAt.add(const Duration(seconds: 15)),
          note: 'corner',
          outcome: 'made',
          matchClockPositionSeconds: null,
          customLabel: null,
          isDeleted: false,
        ),
      );
  await database
      .into(database.shotLocations)
      .insert(
        const ShotLocation(
          id: 'shot-1',
          matchId: 'match-1',
          eventId: 'event-1',
          x: 0.25,
          y: 0.75,
          isConfirmed: true,
        ),
      );
  await database
      .into(database.players)
      .insert(
        PlayerRow(
          id: 'player-1',
          nickname: 'A, "Ace"',
          createdAt: createdAt,
          preferredSide: 'red',
          note: null,
        ),
      );
  await database.batch((batch) {
    batch.insertAll(database.matchParticipants, [
      const MatchParticipant(
        id: 'participant-red',
        matchId: 'match-1',
        side: 'red',
        nameSnapshot: 'Red',
        playerProfileId: 'player-1',
      ),
      const MatchParticipant(
        id: 'participant-blue',
        matchId: 'match-1',
        side: 'blue',
        nameSnapshot: 'Blue',
      ),
    ]);
  });
  await database
      .into(database.ruleTemplates)
      .insert(
        const RuleTemplateRow(
          id: 'rule-1',
          name: 'Race to 11',
          scoreButtonsJson: '[1,2,3]',
          targetScore: 11,
          timeLimitSeconds: null,
          winByTwo: true,
          foulLimit: null,
          customEventTypesJson:
              '{"eventTypes":[],"possessionHintEnabled":false}',
          isBuiltIn: false,
        ),
      );
  await database
      .into(database.possessionSegments)
      .insert(
        const PossessionSegment(
          id: 'possession-1',
          matchId: 'match-1',
          side: 'red',
          startedAtEventId: 'event-1',
          endedAtEventId: 'event-1',
          reason: 'score',
          source: 'manual',
        ),
      );
  await database
      .into(database.auditLogs)
      .insert(
        AuditLog(
          id: 'audit-1',
          matchId: 'match-1',
          targetId: 'event-1',
          action: 'edit',
          beforeJson: '{}',
          afterJson: '{"note":"corner"}',
          reason: 'correction',
          createdAt: createdAt.add(const Duration(minutes: 1)),
        ),
      );
  await database
      .into(database.appSettings)
      .insert(
        AppSetting(key: 'theme', valueJson: '"light"', updatedAt: createdAt),
      );
}
