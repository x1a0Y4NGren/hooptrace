import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/clock_state.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

import '../../test_helpers/test_database.dart';

final _anchor = DateTime.utc(2026, 8, 23, 10);

void main() {
  test(
    'reconstructed command services derive the same persisted running clock',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));

      final later = _anchor.add(const Duration(seconds: 15));
      final first = await MatchCommandService(
        database,
        now: () => later,
      ).readClock('match-clock');
      final rebuilt = await MatchCommandService(
        database,
        now: () => later,
      ).readClock('match-clock');

      expect(first?.displaySeconds, 15);
      expect(rebuilt?.displaySeconds, 15);
      expect(
        (await database.select(database.matchClocks).getSingle())
            .accumulatedSeconds,
        0,
      );
    },
  );

  test(
    'running clock command receipt round-trips persisted and normalized states',
    () async {
      final database = createTestDatabase();
      final startedAt = _anchor;
      final projectedAt = _anchor.add(const Duration(seconds: 5));
      await MatchCommandService(
        database,
        now: () => startedAt,
      ).start(_start(timerEnabled: true));
      final command = RecordMatchEventCommand(
        commandId: 'clock-receipt-round-trip',
        matchId: 'match-clock',
        eventId: 'clock-receipt-event',
        side: TeamSide.red,
        points: 1,
        occurredAt: projectedAt,
      );
      final first = await MatchCommandService(
        database,
        now: () => projectedAt,
      ).record(command);
      final receipt = await (database.select(
        database.auditLogs,
      )..where((row) => row.id.equals(command.commandId))).getSingle();
      final receiptAfter =
          jsonDecode(receipt.afterJson) as Map<String, Object?>;
      final receiptClock =
          (receiptAfter['projection'] as Map<String, Object?>)['clock']
              as Map<String, Object?>;
      expect(receiptClock['state'], isA<Map>());
      expect(receiptClock['normalizedState'], isA<Map>());
      expect(
        (receiptClock['state'] as Map<String, Object?>)['accumulatedSeconds'],
        0,
      );
      expect(
        (receiptClock['normalizedState']
            as Map<String, Object?>)['accumulatedSeconds'],
        5,
      );

      final duplicate = await MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 30)),
      ).record(command);
      _expectClockProjectionEqual(first.clock!, duplicate.clock!);
    },
  );

  test(
    'restored running-clock receipt returns the original first projection',
    () async {
      late final RecordMatchEventCommand command;
      final exported = await withTestDatabase((source) async {
        final startedAt = _anchor;
        final projectedAt = _anchor.add(const Duration(seconds: 5));
        final service = MatchCommandService(source, now: () => startedAt);
        await service.start(_start(timerEnabled: true));
        command = RecordMatchEventCommand(
          commandId: 'clock-backup-receipt',
          matchId: 'match-clock',
          eventId: 'clock-backup-event',
          side: TeamSide.red,
          points: 1,
          occurredAt: projectedAt,
        );
        await MatchCommandService(
          source,
          now: () => projectedAt,
        ).record(command);
        return JsonBackupCodec(
          source,
          appVersion: '0.1.0+1',
          now: () => projectedAt,
        ).export();
      });

      final restored = createTestDatabase();
      await JsonBackupCodec(restored, appVersion: '0.1.0+1').restore(exported);
      final duplicate = await MatchCommandService(
        restored,
        now: () => _anchor.add(const Duration(seconds: 30)),
      ).record(command);
      expect(duplicate.clock, isNotNull);
      expect(duplicate.clock?.displaySeconds, 5);
      expect(duplicate.clock?.state.accumulatedSeconds, 0);
      expect(duplicate.clock?.normalizedState.accumulatedSeconds, 5);
    },
  );

  test('legacy clock receipt shape remains readable', () async {
    final database = createTestDatabase();
    final projectedAt = _anchor.add(const Duration(seconds: 5));
    await MatchCommandService(
      database,
      now: () => _anchor,
    ).start(_start(timerEnabled: true));
    final command = RecordMatchEventCommand(
      commandId: 'legacy-clock-receipt',
      matchId: 'match-clock',
      eventId: 'legacy-clock-event',
      side: TeamSide.red,
      points: 1,
      occurredAt: projectedAt,
    );
    await MatchCommandService(database, now: () => projectedAt).record(command);
    final receipt = await (database.select(
      database.auditLogs,
    )..where((row) => row.id.equals(command.commandId))).getSingle();
    final after = jsonDecode(receipt.afterJson) as Map<String, Object?>;
    final projection = after['projection'] as Map<String, Object?>;
    final clock = projection['clock'] as Map<String, Object?>;
    clock.remove('state');
    clock.remove('normalizedState');
    await database.customUpdate(
      'UPDATE audit_logs SET after_json = ? WHERE id = ?',
      variables: [
        Variable.withString(jsonEncode(after)),
        Variable.withString(command.commandId),
      ],
      updates: {database.auditLogs},
    );

    final duplicate = await MatchCommandService(
      database,
      now: () => _anchor.add(const Duration(seconds: 30)),
    ).record(command);
    expect(duplicate.clock?.displaySeconds, 5);
    expect(duplicate.clock?.phase, ClockPhase.regulation);
  });

  test(
    'nested clock receipt shape does not require duplicated top-level state fields',
    () async {
      final database = createTestDatabase();
      final projectedAt = _anchor.add(const Duration(seconds: 5));
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final command = RecordMatchEventCommand(
        commandId: 'nested-clock-receipt',
        matchId: 'match-clock',
        eventId: 'nested-clock-event',
        side: TeamSide.red,
        points: 1,
        occurredAt: projectedAt,
      );
      await MatchCommandService(
        database,
        now: () => projectedAt,
      ).record(command);
      final receipt = await (database.select(
        database.auditLogs,
      )..where((row) => row.id.equals(command.commandId))).getSingle();
      final after = jsonDecode(receipt.afterJson) as Map<String, Object?>;
      final projection = after['projection'] as Map<String, Object?>;
      final clock = projection['clock'] as Map<String, Object?>;
      for (final key in [
        'id',
        'matchId',
        'mode',
        'phase',
        'accumulatedSeconds',
        'runningSinceUtc',
        'regulationSeconds',
      ]) {
        clock.remove(key);
      }
      await database.customUpdate(
        'UPDATE audit_logs SET after_json = ? WHERE id = ?',
        variables: [
          Variable.withString(jsonEncode(after)),
          Variable.withString(command.commandId),
        ],
        updates: {database.auditLogs},
      );

      final duplicate = await MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 30)),
      ).record(command);
      expect(duplicate.clock?.state.accumulatedSeconds, 0);
      expect(duplicate.clock?.normalizedState.accumulatedSeconds, 5);
      expect(duplicate.clock?.displaySeconds, 5);
    },
  );

  test(
    'pause and resume atomically persist anchors and semantic audit rows',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final pausedAt = _anchor.add(const Duration(seconds: 9));
      final service = MatchCommandService(database, now: () => pausedAt);

      final paused = await service.pause(
        PauseMatchCommand(
          commandId: 'clock-pause',
          matchId: 'match-clock',
          occurredAt: pausedAt,
        ),
      );
      var row = await database.select(database.matchClocks).getSingle();
      expect(row.accumulatedSeconds, 9);
      expect(row.runningSinceUtc, isNull);
      expect(paused.clock?.displaySeconds, 9);

      final resumedAt = pausedAt.add(const Duration(seconds: 20));
      final resumed = await MatchCommandService(database, now: () => resumedAt)
          .resume(
            ResumeMatchCommand(
              commandId: 'clock-resume',
              matchId: 'match-clock',
              occurredAt: resumedAt,
            ),
          );
      row = await database.select(database.matchClocks).getSingle();
      expect(row.accumulatedSeconds, 9);
      expect(row.runningSinceUtc?.toUtc(), resumedAt);
      expect(resumed.clock?.displaySeconds, 9);

      final audits = await database.select(database.auditLogs).get();
      expect(audits.where((row) => row.action == 'command'), hasLength(3));
      expect(audits.where((row) => row.action == 'edit'), hasLength(2));
    },
  );

  test(
    'backward wall-clock read pauses once and returns a recovery reason',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));

      final rollback = await MatchCommandService(
        database,
        now: () => _anchor.subtract(const Duration(seconds: 2)),
      ).readClock('match-clock');
      final secondRead = await MatchCommandService(
        database,
        now: () => _anchor.subtract(const Duration(seconds: 2)),
      ).readClock('match-clock');

      expect(
        rollback?.recoveryReason,
        ClockRecoveryReason.wallClockMovedBackward,
      );
      expect(rollback?.displaySeconds, 0);
      expect(secondRead?.recoveryReason, isNull);
      expect(
        (await database.select(database.matchClocks).getSingle())
            .runningSinceUtc,
        isNull,
      );
    },
  );

  test(
    'countdown expiry pauses input and continue starts overtime without auto-finishing',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database, now: () => _anchor);
      await service.start(
        _start(
          timerEnabled: true,
          clockMode: ClockMode.countdown,
          regulationSeconds: 10,
        ),
      );

      final expired = await MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 10)),
      ).readClock('match-clock');
      expect(expired?.phase, ClockPhase.regulationExpired);
      expect(expired?.displaySeconds, 0);

      final continued =
          await MatchCommandService(
            database,
            now: () => _anchor.add(const Duration(seconds: 12)),
          ).continueMatch(
            ContinueMatchCommand(
              commandId: 'continue-ot',
              matchId: 'match-clock',
              occurredAt: _anchor.add(const Duration(seconds: 12)),
            ),
          );

      expect(continued.clock?.phase, ClockPhase.overtime);
      expect(continued.clock?.displaySeconds, 0);
      expect(continued.match.lifecycle, MatchLifecycle.active);
      expect(
        (await database.select(database.matchClocks).getSingle()).phase,
        'overtime',
      );
    },
  );

  test(
    'wall-clock rollback writes one recoverable system pause and rebuilt resume continues',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final rollbackAt = _anchor.subtract(const Duration(seconds: 2));
      final first = await MatchCommandService(
        database,
        now: () => rollbackAt,
      ).readClock('match-clock');
      final second = await MatchCommandService(
        database,
        now: () => rollbackAt,
      ).readClock('match-clock');

      expect(first?.recoveryReason, ClockRecoveryReason.wallClockMovedBackward);
      expect(second?.recoveryReason, isNull);
      final events = await database.select(database.matchEvents).get();
      expect(events, hasLength(1));
      expect(events.single.type, EventKind.pause.name);
      expect(events.single.customLabel, 'pause');
      final recoveryAudits = (await database.select(database.auditLogs).get())
          .where(
            (row) => row.action == 'edit' && row.reason == 'clock-recovery',
          )
          .toList();
      expect(recoveryAudits, hasLength(1));

      final resumedAt = _anchor.add(const Duration(seconds: 5));
      final resumed = await MatchCommandService(database, now: () => resumedAt)
          .resume(
            ResumeMatchCommand(
              commandId: 'recovery-resume',
              matchId: 'match-clock',
              occurredAt: resumedAt,
            ),
          );
      expect(resumed.clock?.runningSinceUtc, resumedAt);
      final continued = await MatchCommandService(
        database,
        now: () => resumedAt.add(const Duration(seconds: 3)),
      ).readClock('match-clock');
      expect(continued?.displaySeconds, 3);
    },
  );

  test(
    'concurrent rollback reads create one deterministic recovery event and audit',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final rollbackAt = _anchor.subtract(const Duration(seconds: 2));
      await Future.wait([
        MatchCommandService(
          database,
          now: () => rollbackAt,
        ).readClock('match-clock'),
        MatchCommandService(
          database,
          now: () => rollbackAt,
        ).readClock('match-clock'),
      ]);
      expect(
        (await database.select(database.matchEvents).get()).where(
          (event) => event.customLabel == 'pause',
        ),
        hasLength(1),
      );
      expect(
        (await database.select(database.auditLogs).get()).where(
          (row) => row.reason == 'clock-recovery',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'record at the exact countdown boundary commits expiry before rejecting input',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(database, now: () => _anchor).start(
        _start(
          timerEnabled: true,
          clockMode: ClockMode.countdown,
          regulationSeconds: 10,
        ),
      );

      final failure = await _captureFailure(
        () => MatchCommandService(
          database,
          now: () => _anchor.add(const Duration(seconds: 10)),
        ).record(_score()),
      );

      expect(failure, isA<EndConditionFailure>());
      final row = await database.select(database.matchClocks).getSingle();
      expect(row.phase, ClockPhase.regulationExpired.name);
      expect(row.runningSinceUtc, isNull);
      expect(await database.select(database.matchEvents).get(), isEmpty);
    },
  );

  test(
    'target acknowledgement is not repeated until the next score change',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database, now: () => _anchor);
      await service.start(
        _start(
          ruleTemplate: const RuleTemplate(
            id: 'target-11',
            name: 'Target',
            scoreButtons: [1, 2, 3],
            targetScore: 11,
            winByTwo: true,
          ),
        ),
      );

      await service.record(
        RecordMatchEventCommand(
          commandId: 'blue-lead',
          matchId: 'match-clock',
          eventId: 'blue-lead-event',
          side: TeamSide.blue,
          points: 10,
          occurredAt: _anchor,
        ),
      );

      final targetCommand = _score(points: 11);
      final target = await service.record(targetCommand);
      expect(target.decision?.kind, MatchDecisionKind.finishOrContinue);
      expect(target.decision?.reason, MatchDecisionReason.winByTwoRequired);
      final targetAudits = await database.select(database.auditLogs).get();
      expect(
        targetAudits.any(
          (row) => row.action == 'edit' && row.reason == 'decision-clock',
        ),
        isTrue,
      );

      final duplicateTarget = await service.record(targetCommand);
      expect(
        duplicateTarget.decision?.reason,
        MatchDecisionReason.winByTwoRequired,
      );

      await expectLater(
        service.record(
          _score(
            commandId: 'blocked-score',
            eventId: 'blocked-event',
            points: 1,
          ),
        ),
        throwsA(isA<EndConditionFailure>()),
      );

      final continued = await service.continueMatch(
        ContinueMatchCommand(
          commandId: 'continue-target',
          matchId: 'match-clock',
          occurredAt: _anchor,
        ),
      );
      expect(continued.decision, isNull);

      final nextScore = await service.record(
        _score(commandId: 'next-score', eventId: 'next-event', points: 1),
      );
      expect(nextScore.decision, isNotNull);
    },
  );

  test('win-by-two finishes at an exact two-point lead', () async {
    final database = createTestDatabase();
    final service = MatchCommandService(database, now: () => _anchor);
    await service.start(
      _start(
        ruleTemplate: const RuleTemplate(
          id: 'target-11-exact',
          name: 'Target',
          scoreButtons: [1, 2, 3],
          targetScore: 11,
          winByTwo: true,
        ),
      ),
    );
    await service.record(
      RecordMatchEventCommand(
        commandId: 'blue-nine',
        matchId: 'match-clock',
        eventId: 'blue-nine-event',
        side: TeamSide.blue,
        points: 9,
        occurredAt: _anchor,
      ),
    );
    final result = await service.record(_score(points: 11));

    expect(result.decision?.reason, MatchDecisionReason.targetReached);
    expect(result.decision?.canFinish, isTrue);
    expect(result.decision?.canContinue, isTrue);
  });

  test(
    'foul limit is exposed as a warning and never finishes the match',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database, now: () => _anchor);
      await service.start(
        _start(
          ruleTemplate: const RuleTemplate(
            id: 'fouls',
            name: 'Fouls',
            scoreButtons: [1],
            foulLimit: 1,
          ),
        ),
      );

      final result = await service.record(
        RecordMatchEventCommand(
          commandId: 'foul-command',
          matchId: 'match-clock',
          eventId: 'foul-event',
          type: EventKind.foul,
          side: TeamSide.red,
          points: 0,
          occurredAt: _anchor,
        ),
      );

      expect(result.warnings, isNotEmpty);
      expect(result.match.lifecycle, MatchLifecycle.active);
      expect(
        await database.select(database.activeSessions).get(),
        hasLength(1),
      );
    },
  );

  test(
    'pause and resume transaction failures leave clock and semantic events unchanged',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final pauseFailureService = MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 5)),
        failureInjector: (point) {
          if (point == MatchCommandFailurePoint.afterEventWritten) {
            throw StateError('pause failure');
          }
        },
      );
      final pauseFailure = await _captureFailure(
        () => pauseFailureService.pause(
          PauseMatchCommand(
            commandId: 'rollback-pause',
            matchId: 'match-clock',
            occurredAt: _anchor.add(const Duration(seconds: 5)),
          ),
        ),
      );
      expect(pauseFailure, isA<CommandTransactionFailure>());
      var row = await database.select(database.matchClocks).getSingle();
      expect(row.accumulatedSeconds, 0);
      expect(row.runningSinceUtc?.toUtc(), _anchor);
      expect(await database.select(database.matchEvents).get(), isEmpty);

      await MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 5)),
      ).pause(
        PauseMatchCommand(
          commandId: 'rollback-pause-success',
          matchId: 'match-clock',
          occurredAt: _anchor.add(const Duration(seconds: 5)),
        ),
      );
      final resumeFailureService = MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 8)),
        failureInjector: (point) {
          if (point == MatchCommandFailurePoint.afterAuditWritten) {
            throw StateError('resume failure');
          }
        },
      );
      final resumeFailure = await _captureFailure(
        () => resumeFailureService.resume(
          ResumeMatchCommand(
            commandId: 'rollback-resume',
            matchId: 'match-clock',
            occurredAt: _anchor.add(const Duration(seconds: 8)),
          ),
        ),
      );
      expect(resumeFailure, isA<CommandTransactionFailure>());
      row = await database.select(database.matchClocks).getSingle();
      expect(row.accumulatedSeconds, 5);
      expect(row.runningSinceUtc, isNull);
      expect(
        (await database.select(database.matchEvents).get()).where(
          (event) => event.customLabel == 'resume',
        ),
        isEmpty,
      );

      final resumed =
          await MatchCommandService(
            database,
            now: () => _anchor.add(const Duration(seconds: 8)),
          ).resume(
            ResumeMatchCommand(
              commandId: 'rollback-resume-success',
              matchId: 'match-clock',
              occurredAt: _anchor.add(const Duration(seconds: 8)),
            ),
          );
      expect(
        resumed.clock?.runningSinceUtc,
        _anchor.add(const Duration(seconds: 8)),
      );
    },
  );

  test(
    'abandon freezes the clock and later projections cannot advance it',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      await MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 7)),
      ).abandon(
        AbandonMatchCommand(
          commandId: 'abandon-clock',
          matchId: 'match-clock',
          endedAt: _anchor.add(const Duration(seconds: 7)),
        ),
      );
      final row = await database.select(database.matchClocks).getSingle();
      expect(row.accumulatedSeconds, 7);
      expect(row.runningSinceUtc, isNull);
      expect(
        (await database.select(database.matches).getSingle()).lifecycle,
        MatchLifecycle.abandoned.name,
      );
      final later = await MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 100)),
      ).readClock('match-clock');
      expect(later?.displaySeconds, 7);
      expect(later?.isRunning, isFalse);
    },
  );

  test(
    'clock projection at its anchor is exact and does not persist a tick',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final projection = await MatchCommandService(
        database,
        now: () => _anchor,
      ).readClock('match-clock');
      expect(projection?.displaySeconds, 0);
      expect(projection?.elapsedSeconds, 0);
      final row = await database.select(database.matchClocks).getSingle();
      expect(row.accumulatedSeconds, 0);
      expect(row.runningSinceUtc?.toUtc(), _anchor);
    },
  );

  test(
    'countdown with no anchor normalizes an accumulated regulation boundary',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(clockMode: ClockMode.countdown, regulationSeconds: 10));
      await database.customUpdate(
        'UPDATE match_clocks SET accumulated_seconds = ? WHERE match_id = ?',
        variables: [Variable.withInt(10), Variable.withString('match-clock')],
        updates: {database.matchClocks},
      );
      final projection = await MatchCommandService(
        database,
        now: () => _anchor,
      ).readClock('match-clock');
      expect(projection?.phase, ClockPhase.regulationExpired);
      expect(projection?.displaySeconds, 0);
      final row = await database.select(database.matchClocks).getSingle();
      expect(row.phase, ClockPhase.regulationExpired.name);
      expect(row.accumulatedSeconds, 10);
    },
  );

  test('concurrent read and pause preserve elapsed seconds', () async {
    final database = createTestDatabase();
    await MatchCommandService(
      database,
      now: () => _anchor,
    ).start(_start(timerEnabled: true));
    final at = _anchor.add(const Duration(seconds: 6));
    await Future.wait([
      MatchCommandService(database, now: () => at).readClock('match-clock'),
      MatchCommandService(database, now: () => at).pause(
        PauseMatchCommand(
          commandId: 'concurrent-pause',
          matchId: 'match-clock',
          occurredAt: at,
        ),
      ),
    ]);
    final row = await database.select(database.matchClocks).getSingle();
    expect(row.accumulatedSeconds, 6);
    expect(row.runningSinceUtc, isNull);
    expect(
      (await database.select(database.matchEvents).get()).where(
        (event) => event.customLabel == 'pause',
      ),
      hasLength(1),
    );
  });

  test(
    'concurrent read and record preserve the score and running projection',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final at = _anchor.add(const Duration(seconds: 6));
      await Future.wait([
        MatchCommandService(database, now: () => at).readClock('match-clock'),
        MatchCommandService(database, now: () => at).record(
          _score(
            commandId: 'concurrent-score',
            eventId: 'concurrent-score-event',
          ),
        ),
      ]);
      final projection = await MatchCommandService(
        database,
        now: () => at,
      ).readClock('match-clock');
      expect(projection?.displaySeconds, 6);
      expect(
        (await database.select(database.matchEvents).get()).where(
          (event) => event.id == 'concurrent-score-event',
        ),
        hasLength(1),
      );
    },
  );

  test('manual pause and resume reject illegal repeated sequences', () async {
    final database = createTestDatabase();
    await MatchCommandService(
      database,
      now: () => _anchor,
    ).start(_start(timerEnabled: true));
    final service = MatchCommandService(database, now: () => _anchor);
    await service.pause(
      PauseMatchCommand(
        commandId: 'pause-once',
        matchId: 'match-clock',
        occurredAt: _anchor,
      ),
    );
    await expectLater(
      service.pause(
        PauseMatchCommand(
          commandId: 'pause-twice',
          matchId: 'match-clock',
          occurredAt: _anchor,
        ),
      ),
      throwsA(isA<CommandValidationFailure>()),
    );
    await service.resume(
      ResumeMatchCommand(
        commandId: 'resume-once',
        matchId: 'match-clock',
        occurredAt: _anchor,
      ),
    );
    await expectLater(
      service.resume(
        ResumeMatchCommand(
          commandId: 'resume-twice',
          matchId: 'match-clock',
          occurredAt: _anchor,
        ),
      ),
      throwsA(isA<CommandValidationFailure>()),
    );
  });

  test(
    'pause at a countdown boundary keeps the persisted expiry decision',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(database, now: () => _anchor).start(
        _start(
          timerEnabled: true,
          clockMode: ClockMode.countdown,
          regulationSeconds: 10,
        ),
      );
      final failure = await _captureFailure(
        () =>
            MatchCommandService(
              database,
              now: () => _anchor.add(const Duration(seconds: 10)),
            ).pause(
              PauseMatchCommand(
                commandId: 'pause-at-expiry',
                matchId: 'match-clock',
                occurredAt: _anchor.add(const Duration(seconds: 10)),
              ),
            ),
      );

      expect(failure, isA<EndConditionFailure>());
      final row = await database.select(database.matchClocks).getSingle();
      expect(row.phase, ClockPhase.regulationExpired.name);
      expect(row.runningSinceUtc, isNull);
    },
  );

  test(
    'finishing a timed match freezes its persisted clock atomically',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      await MatchCommandService(
        database,
        now: () => _anchor.add(const Duration(seconds: 5)),
      ).finish(
        FinishMatchCommand(
          commandId: 'finish-clock',
          matchId: 'match-clock',
          endedAt: _anchor.add(const Duration(seconds: 5)),
        ),
      );

      final row = await database.select(database.matchClocks).getSingle();
      expect(row.accumulatedSeconds, 5);
      expect(row.runningSinceUtc, isNull);
      expect(row.phase, ClockPhase.regulation.name);
    },
  );

  test(
    'reconstructed pause commands remain idempotent with the same command id',
    () async {
      final database = createTestDatabase();
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).start(_start(timerEnabled: true));
      final firstCommand = PauseMatchCommand(
        commandId: 'pause-retry',
        matchId: 'match-clock',
        occurredAt: _anchor,
      );
      await MatchCommandService(
        database,
        now: () => _anchor,
      ).pause(firstCommand);
      final duplicate = await MatchCommandService(database, now: () => _anchor)
          .pause(
            PauseMatchCommand(
              commandId: 'pause-retry',
              matchId: 'match-clock',
              occurredAt: _anchor,
            ),
          );

      expect(duplicate.clock?.displaySeconds, 0);
      expect(
        (await database.select(database.matchEvents).get()).where(
          (row) => row.customLabel == 'pause',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'win-by-two pending decision rejects finish, while an exact 12-10 lead can finish',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database, now: () => _anchor);
      await service.start(
        _start(
          ruleTemplate: const RuleTemplate(
            id: 'target-finish-gate',
            name: 'Target',
            scoreButtons: [1, 2, 3],
            targetScore: 11,
            winByTwo: true,
          ),
        ),
      );
      await service.record(
        RecordMatchEventCommand(
          commandId: 'finish-gate-blue',
          matchId: 'match-clock',
          eventId: 'finish-gate-blue-event',
          side: TeamSide.blue,
          points: 10,
          occurredAt: _anchor,
        ),
      );
      final pending = await service.record(
        _score(
          commandId: 'finish-gate-red',
          eventId: 'finish-gate-red-event',
          points: 11,
        ),
      );
      expect(pending.decision?.reason, MatchDecisionReason.winByTwoRequired);
      expect(pending.decision?.canFinish, isFalse);

      final failure = await _captureFailure(
        () => service.finish(
          FinishMatchCommand(
            commandId: 'finish-gate-too-early',
            matchId: 'match-clock',
            endedAt: _anchor,
          ),
        ),
      );
      expect(failure, isA<EndConditionFailure>());
      expect((failure as EndConditionFailure).decision.canFinish, isFalse);
      expect(
        (await database.select(database.matches).getSingle()).lifecycle,
        MatchLifecycle.active.name,
      );

      await service.continueMatch(
        ContinueMatchCommand(
          commandId: 'finish-gate-continue',
          matchId: 'match-clock',
          occurredAt: _anchor,
        ),
      );
      final exact = await service.record(
        _score(
          commandId: 'finish-gate-exact',
          eventId: 'finish-gate-exact-event',
        ),
      );
      expect(exact.redScore, 12);
      expect(exact.blueScore, 10);
      expect(exact.decision?.reason, MatchDecisionReason.targetReached);
      expect(exact.decision?.canFinish, isTrue);
      final finished = await service.finish(
        FinishMatchCommand(
          commandId: 'finish-gate-finish',
          matchId: 'match-clock',
          endedAt: _anchor,
        ),
      );
      expect(finished.match.lifecycle, MatchLifecycle.finished);
    },
  );

  test(
    'pending decision remains a mutation barrier after service reconstruction',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database, now: () => _anchor);
      await service.start(
        _start(
          ruleTemplate: const RuleTemplate(
            id: 'target-rebuild-gate',
            name: 'Target',
            scoreButtons: [1, 2, 3],
            targetScore: 11,
            winByTwo: true,
          ),
        ),
      );
      await service.record(
        RecordMatchEventCommand(
          commandId: 'rebuild-blue',
          matchId: 'match-clock',
          eventId: 'rebuild-blue-event',
          side: TeamSide.blue,
          points: 10,
          occurredAt: _anchor,
        ),
      );
      await service.record(
        _score(
          commandId: 'rebuild-red',
          eventId: 'rebuild-red-event',
          points: 11,
        ),
      );

      final rebuilt = MatchCommandService(database, now: () => _anchor);
      final failure = await _captureFailure(
        () => rebuilt.record(
          _score(
            commandId: 'rebuild-blocked',
            eventId: 'rebuild-blocked-event',
          ),
        ),
      );
      expect(failure, isA<EndConditionFailure>());
      expect(
        (failure as EndConditionFailure).decision.reason,
        MatchDecisionReason.winByTwoRequired,
      );
    },
  );

  test(
    'pending decisions block correct and undo but allow committed field-goal location confirmation',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database, now: () => _anchor);
      await service.start(
        _start(
          ruleTemplate: const RuleTemplate(
            id: 'target-mutation-gate',
            name: 'Target',
            scoreButtons: [1, 2, 3],
            targetScore: 11,
            winByTwo: true,
          ),
        ),
      );
      await service.record(
        RecordMatchEventCommand(
          commandId: 'mutation-blue',
          matchId: 'match-clock',
          eventId: 'mutation-blue-event',
          side: TeamSide.blue,
          points: 10,
          occurredAt: _anchor,
        ),
      );
      await service.record(
        _score(
          commandId: 'mutation-red',
          eventId: 'mutation-red-event',
          points: 11,
        ),
      );

      final correctFailure = await _captureFailure(
        () => service.correct(
          CorrectMatchEventCommand(
            commandId: 'mutation-correct',
            matchId: 'match-clock',
            eventId: 'mutation-red-event',
            points: 10,
          ),
        ),
      );
      expect(correctFailure, isA<EndConditionFailure>());
      final undoFailure = await _captureFailure(
        () => service.undo(
          UndoMatchEventCommand(
            commandId: 'mutation-undo',
            matchId: 'match-clock',
            eventId: 'mutation-red-event',
          ),
        ),
      );
      expect(undoFailure, isA<EndConditionFailure>());

      final locationDatabase = createTestDatabase();
      final locationService = MatchCommandService(
        locationDatabase,
        now: () => _anchor,
      );
      await locationService.start(
        _start(
          ruleTemplate: const RuleTemplate(
            id: 'target-location-gate',
            name: 'Target',
            scoreButtons: [1],
            targetScore: 1,
          ),
        ),
      );
      await locationService.record(
        RecordMatchEventCommand(
          commandId: 'location-score',
          matchId: 'match-clock',
          eventId: 'location-score-event',
          type: EventKind.fieldGoal,
          side: TeamSide.red,
          points: 1,
          outcome: ShotOutcome.made,
          occurredAt: _anchor,
        ),
      );
      final located = await locationService.confirmShotLocation(
        ConfirmShotLocationCommand(
          commandId: 'location-confirm',
          matchId: 'match-clock',
          eventId: 'location-score-event',
          point: CourtPoint(x: 0.1, y: 0.2),
        ),
      );
      expect(located.decision?.reason, MatchDecisionReason.targetReached);
      expect(
        await locationDatabase.select(locationDatabase.shotLocations).get(),
        hasLength(1),
      );
    },
  );

  test(
    'score-changing corrections and undo after target continuation re-evaluate the decision',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database, now: () => _anchor);
      await service.start(
        _start(
          ruleTemplate: const RuleTemplate(
            id: 'target-correction-recheck',
            name: 'Target',
            scoreButtons: [1, 2, 3],
            targetScore: 11,
            winByTwo: true,
          ),
        ),
      );
      await service.record(
        RecordMatchEventCommand(
          commandId: 'recheck-blue',
          matchId: 'match-clock',
          eventId: 'recheck-blue-event',
          side: TeamSide.blue,
          points: 10,
          occurredAt: _anchor,
        ),
      );
      await service.record(
        _score(
          commandId: 'recheck-red',
          eventId: 'recheck-red-event',
          points: 11,
        ),
      );
      await service.continueMatch(
        ContinueMatchCommand(
          commandId: 'recheck-continue',
          matchId: 'match-clock',
          occurredAt: _anchor,
        ),
      );

      final lowered = await service.correct(
        CorrectMatchEventCommand(
          commandId: 'recheck-lower',
          matchId: 'match-clock',
          eventId: 'recheck-red-event',
          points: 1,
        ),
      );
      expect(lowered.decision, isNull);

      final retargeted = await service.correct(
        CorrectMatchEventCommand(
          commandId: 'recheck-retarget',
          matchId: 'match-clock',
          eventId: 'recheck-red-event',
          points: 11,
        ),
      );
      expect(retargeted.decision?.reason, MatchDecisionReason.winByTwoRequired);

      await service.continueMatch(
        ContinueMatchCommand(
          commandId: 'recheck-continue-again',
          matchId: 'match-clock',
          occurredAt: _anchor,
        ),
      );
      final undone = await service.undo(
        UndoMatchEventCommand(
          commandId: 'recheck-undo',
          matchId: 'match-clock',
          eventId: 'recheck-red-event',
        ),
      );
      expect(undone.decision, isNull);
    },
  );
}

Future<MatchCommandFailure> _captureFailure(
  Future<Object> Function() operation,
) async {
  try {
    await operation();
    fail('Expected a typed command failure.');
  } on MatchCommandFailure catch (failure) {
    return failure;
  }
}

void _expectClockProjectionEqual(
  ClockProjection expected,
  ClockProjection actual,
) {
  _expectClockStateEqual(expected.state, actual.state);
  _expectClockStateEqual(expected.normalizedState, actual.normalizedState);
  expect(actual.nowUtc, expected.nowUtc);
  expect(actual.elapsedSeconds, expected.elapsedSeconds);
  expect(actual.displaySeconds, expected.displaySeconds);
  expect(actual.phase, expected.phase);
  expect(actual.remainingSeconds, expected.remainingSeconds);
  expect(actual.recoveryReason, expected.recoveryReason);
  expect(actual.recoveryMessage, expected.recoveryMessage);
  expect(actual.requiresPersistence, expected.requiresPersistence);
}

void _expectClockStateEqual(ClockState expected, ClockState actual) {
  expect(actual.id, expected.id);
  expect(actual.matchId, expected.matchId);
  expect(actual.mode, expected.mode);
  expect(actual.phase, expected.phase);
  expect(actual.accumulatedSeconds, expected.accumulatedSeconds);
  expect(actual.runningSinceUtc, expected.runningSinceUtc);
  expect(actual.regulationSeconds, expected.regulationSeconds);
}

StartMatchCommand _start({
  bool timerEnabled = false,
  ClockMode clockMode = ClockMode.countUp,
  int? regulationSeconds,
  RuleTemplate ruleTemplate = const RuleTemplate(
    id: 'free',
    name: 'Free',
    scoreButtons: [1, 2, 3],
  ),
}) => StartMatchCommand(
  commandId: 'start-clock',
  matchId: 'match-clock',
  redName: 'Red',
  blueName: 'Blue',
  ruleTemplate: ruleTemplate,
  clockMode: clockMode,
  regulationSeconds: regulationSeconds,
  timerEnabled: timerEnabled,
  startedAt: _anchor,
);

RecordMatchEventCommand _score({
  String commandId = 'score-command',
  String eventId = 'score-event',
  int points = 1,
}) => RecordMatchEventCommand(
  commandId: commandId,
  matchId: 'match-clock',
  eventId: eventId,
  side: TeamSide.red,
  points: points,
  occurredAt: _anchor,
);
