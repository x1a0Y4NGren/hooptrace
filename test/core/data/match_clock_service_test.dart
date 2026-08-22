import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

import '../../test_helpers/test_database.dart';

final _anchor = DateTime.utc(2026, 8, 23, 10);

void main() {
  test('reconstructed command services derive the same persisted running clock', () async {
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
      (await database.select(database.matchClocks).getSingle()).accumulatedSeconds,
      0,
    );
  });

  test('pause and resume atomically persist anchors and semantic audit rows', () async {
    final database = createTestDatabase();
    await MatchCommandService(database, now: () => _anchor).start(
      _start(timerEnabled: true),
    );
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
    final resumed = await MatchCommandService(database, now: () => resumedAt).resume(
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
  });

  test('backward wall-clock read pauses once and returns a recovery reason', () async {
    final database = createTestDatabase();
    await MatchCommandService(database, now: () => _anchor).start(
      _start(timerEnabled: true),
    );

    final rollback = await MatchCommandService(
      database,
      now: () => _anchor.subtract(const Duration(seconds: 2)),
    ).readClock('match-clock');
    final secondRead = await MatchCommandService(
      database,
      now: () => _anchor.subtract(const Duration(seconds: 2)),
    ).readClock('match-clock');

    expect(rollback?.recoveryReason, ClockRecoveryReason.wallClockMovedBackward);
    expect(rollback?.displaySeconds, 0);
    expect(secondRead?.recoveryReason, isNull);
    expect((await database.select(database.matchClocks).getSingle()).runningSinceUtc, isNull);
  });

  test('countdown expiry pauses input and continue starts overtime without auto-finishing', () async {
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

    final continued = await MatchCommandService(
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
    expect((await database.select(database.matchClocks).getSingle()).phase, 'overtime');
  });

  test('record at the exact countdown boundary commits expiry before rejecting input', () async {
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
  });

  test('target acknowledgement is not repeated until the next score change', () async {
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
    expect(duplicateTarget.decision?.reason, MatchDecisionReason.winByTwoRequired);

    await expectLater(
      service.record(
        _score(commandId: 'blocked-score', eventId: 'blocked-event', points: 1),
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
  });

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

  test('foul limit is exposed as a warning and never finishes the match', () async {
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
    expect(await database.select(database.activeSessions).get(), hasLength(1));
  });

  test('manual pause and resume reject illegal repeated sequences', () async {
    final database = createTestDatabase();
    await MatchCommandService(database, now: () => _anchor).start(
      _start(timerEnabled: true),
    );
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

  test('pause at a countdown boundary keeps the persisted expiry decision', () async {
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
  });

  test('finishing a timed match freezes its persisted clock atomically', () async {
    final database = createTestDatabase();
    await MatchCommandService(database, now: () => _anchor).start(
      _start(timerEnabled: true),
    );
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
  });

  test('reconstructed pause commands remain idempotent with the same command id', () async {
    final database = createTestDatabase();
    await MatchCommandService(database, now: () => _anchor).start(
      _start(timerEnabled: true),
    );
    final firstCommand = PauseMatchCommand(
      commandId: 'pause-retry',
      matchId: 'match-clock',
      occurredAt: _anchor,
    );
    await MatchCommandService(database, now: () => _anchor).pause(firstCommand);
    final duplicate = await MatchCommandService(
      database,
      now: () => _anchor,
    ).pause(
      PauseMatchCommand(
        commandId: 'pause-retry',
        matchId: 'match-clock',
        occurredAt: _anchor,
      ),
    );

    expect(duplicate.clock?.displaySeconds, 0);
    expect(
      (await database.select(database.matchEvents).get())
          .where((row) => row.customLabel == 'pause'),
      hasLength(1),
    );
  });
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
