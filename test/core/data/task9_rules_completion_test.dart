import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/rules/rule_engine.dart';
import 'package:hooptrace/core/domain/scoring/score_state.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

import '../../test_helpers/test_database.dart';

void main() {
  test('rule template persistence retains the possession policy', () async {
    final database = createTestDatabase();
    final repository = RuleTemplateRepository(database);
    const template = RuleTemplate(
      id: 'policy-round-trip',
      name: 'Policy',
      scoreButtons: [1, 2, 3],
      possessionHintEnabled: true,
      possessionPolicy: PossessionPolicy.switchAfterMade,
    );
    await repository.save(template);
    final restored = await repository.getById(template.id);
    expect(restored?.possessionPolicy, PossessionPolicy.switchAfterMade);
    expect(restored?.possessionHintEnabled, isTrue);
  });

  test('rule hints expose stable keys and localized text', () {
    final hints = RuleEngine(locale: 'en').evaluate(
      template: const RuleTemplate(
        id: 'localized',
        name: 'Localized',
        scoreButtons: [1, 2, 3],
        targetScore: 1,
      ),
      score: const ScoreState(redScore: 0, blueScore: 0),
      scoringSide: TeamSide.red,
      scoringPoints: 1,
    );
    expect(hints.single.messageKey, 'targetReached');
    expect(hints.single.localizedMessage('zh'), contains('目标分数'));
    expect(hints.single.localizedMessage('en'), contains('Target score'));
  });

  test(
    'switch-after-made suggests the other side and never infers a miss',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database);
      final start = _start('switch', PossessionPolicy.switchAfterMade);
      await service.start(start);

      final made = await service.record(
        _fieldGoal(
          'switch-made',
          start.matchId,
          'switch-made-event',
          TeamSide.red,
        ),
      );
      expect(made.currentPossession, TeamSide.blue);
      expect(made.possessionSegments, hasLength(1));
      expect(made.possessionSegments.single.source, PossessionSource.suggested);

      final missed = await service.record(
        RecordMatchEventCommand(
          commandId: 'switch-miss',
          matchId: start.matchId,
          eventId: 'switch-miss-event',
          type: EventKind.fieldGoal,
          side: TeamSide.blue,
          points: 0,
          outcome: ShotOutcome.missed,
          occurredAt: DateTime.utc(2026, 8, 23, 10, 1),
        ),
      );
      expect(missed.currentPossession, TeamSide.blue);
      expect(missed.possessionSegments, hasLength(1));
      expect(missed.possessionSegments.single.endedAtEventId, isNull);
    },
  );

  test(
    'keep-after-made retains the scorer and manual policy does not suggest',
    () async {
      final keepDatabase = createTestDatabase();
      final keepService = MatchCommandService(keepDatabase);
      final keep = _start('keep', PossessionPolicy.keepAfterMade);
      await keepService.start(keep);
      final keepProjection = await keepService.record(
        _fieldGoal('keep-made', keep.matchId, 'keep-made-event', TeamSide.red),
      );
      final repeated = await keepService.record(
        _fieldGoal(
          'keep-made-again',
          keep.matchId,
          'keep-made-again-event',
          TeamSide.red,
        ),
      );
      expect(keepProjection.currentPossession, TeamSide.red);
      expect(
        keepProjection.possessionSegments.single.source,
        PossessionSource.suggested,
      );
      expect(repeated.possessionSegments, hasLength(1));

      final manualDatabase = createTestDatabase();
      final manualService = MatchCommandService(manualDatabase);
      final manual = _start('manual', PossessionPolicy.manual);
      await manualService.start(manual);
      final manualProjection = await manualService.record(
        _fieldGoal(
          'manual-made',
          manual.matchId,
          'manual-made-event',
          TeamSide.red,
        ),
      );
      expect(manualProjection.possessionSegments, isEmpty);
      final manualPossession = await manualService.record(
        RecordMatchEventCommand(
          commandId: 'manual-possession-command',
          matchId: manual.matchId,
          eventId: 'manual-possession-event',
          type: EventKind.possession,
          side: TeamSide.blue,
          points: 0,
          note: '裁判指定',
          occurredAt: DateTime.utc(2026, 8, 23, 10, 1),
        ),
      );
      expect(manualPossession.currentPossession, TeamSide.blue);
      expect(
        manualPossession.possessionSegments.single.source,
        PossessionSource.manual,
      );
    },
  );

  test(
    'manual possession correction closes the suggestion and audits its reason',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database);
      final start = _start('correction', PossessionPolicy.switchAfterMade);
      await service.start(start);
      await service.record(
        _fieldGoal(
          'correction-made',
          start.matchId,
          'correction-made-event',
          TeamSide.red,
        ),
      );

      final corrected = await service.setPossession(
        SetPossessionCommand(
          commandId: 'correction-set',
          matchId: start.matchId,
          side: TeamSide.red,
          reason: '裁判纠正',
          occurredAt: DateTime.utc(2026, 8, 23, 10, 2),
        ),
      );
      expect(corrected.currentPossession, TeamSide.red);
      expect(corrected.possessionSegments, hasLength(2));
      expect(
        corrected.possessionSegments.first.source,
        PossessionSource.suggested,
      );
      expect(
        corrected.possessionSegments.first.endedAtEventId,
        'correction-set:event',
      );
      expect(corrected.possessionSegments.last.source, PossessionSource.manual);
      expect(corrected.possessionSegments.last.reason, '裁判纠正');

      final audit = await (database.select(
        database.auditLogs,
      )..where((row) => row.action.equals('possession'))).getSingle();
      expect(audit.reason, '裁判纠正');
      expect(audit.beforeJson, contains('suggested'));
      expect(audit.afterJson, contains('manual'));
    },
  );

  test('finish closes open possession and clock transactionally', () async {
    final database = createTestDatabase();
    final service = MatchCommandService(database);
    final start = _start(
      'finish',
      PossessionPolicy.keepAfterMade,
      timerEnabled: true,
    );
    await service.start(start);
    await service.record(
      _fieldGoal(
        'finish-made',
        start.matchId,
        'finish-made-event',
        TeamSide.red,
      ),
    );

    final finished = await service.finish(
      FinishMatchCommand(
        commandId: 'finish-set',
        matchId: start.matchId,
        endedAt: DateTime.utc(2026, 8, 23, 10, 3),
      ),
    );
    expect(finished.match.lifecycle, MatchLifecycle.finished);
    expect(
      finished.possessionSegments.single.endedAtEventId,
      'finish-set:event',
    );
    expect(finished.clock?.isRunning, isFalse);
    expect(await database.select(database.activeSessions).get(), isEmpty);
  });

  test('finish requires explicit final-score confirmation', () async {
    final database = createTestDatabase();
    final service = MatchCommandService(database);
    final start = _start('finish-confirm', PossessionPolicy.manual);
    await service.start(start);
    await expectLater(
      service.finish(
        FinishMatchCommand(
          commandId: 'finish-confirm-finish',
          matchId: start.matchId,
          endedAt: DateTime.utc(2026, 8, 23, 10, 3),
          confirmFinalScore: false,
        ),
      ),
      throwsA(isA<CommandValidationFailure>()),
    );
    expect(
      (await database.select(database.matches).getSingle()).lifecycle,
      MatchLifecycle.active.name,
    );
  });

  test(
    'target end condition pauses and continue remains an explicit decision',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(database);
      final start = _start(
        'decision',
        PossessionPolicy.manual,
        targetScore: 1,
        timerEnabled: true,
      );
      await service.start(start);

      final decisionProjection = await service.record(
        _fieldGoal(
          'decision-made',
          start.matchId,
          'decision-made-event',
          TeamSide.red,
        ),
      );
      expect(decisionProjection.decision, isNotNull);
      // The committed score and the durable decision marker are both replay
      // events; the marker keeps continue/finalize idempotent.
      expect(await database.select(database.matchEvents).get(), hasLength(2));
      expect(
        await database.select(database.activeSessions).get(),
        hasLength(1),
      );

      final continued = await service.continueMatch(
        ContinueMatchCommand(
          commandId: 'decision-continue',
          matchId: start.matchId,
          occurredAt: DateTime.utc(2026, 8, 23, 10, 4),
        ),
      );
      expect(continued.match.lifecycle, MatchLifecycle.active);
      expect(
        await database.select(database.activeSessions).get(),
        hasLength(1),
      );
    },
  );

  test(
    'finish rollback preserves active session, open possession, and clock',
    () async {
      final database = createTestDatabase();
      final service = MatchCommandService(
        database,
        failureInjector: (point) {
          if (point == MatchCommandFailurePoint.afterLifecycleWritten) {
            throw StateError('finish failed');
          }
        },
      );
      final start = _start(
        'finish-rollback',
        PossessionPolicy.keepAfterMade,
        timerEnabled: true,
      );
      await service.start(start);
      await service.record(
        _fieldGoal(
          'finish-rollback-made',
          start.matchId,
          'finish-rollback-event',
          TeamSide.red,
        ),
      );

      await expectLater(
        service.finish(
          FinishMatchCommand(
            commandId: 'finish-rollback-finish',
            matchId: start.matchId,
            endedAt: DateTime.utc(2026, 8, 23, 10, 5),
          ),
        ),
        throwsA(isA<CommandTransactionFailure>()),
      );
      final match = await database.select(database.matches).getSingle();
      final segment = await database
          .select(database.possessionSegments)
          .getSingle();
      expect(match.lifecycle, MatchLifecycle.active.name);
      expect(segment.endedAtEventId, isNull);
      expect(
        await database.select(database.activeSessions).get(),
        hasLength(1),
      );
      expect(await database.select(database.matchEvents).get(), hasLength(1));
    },
  );
}

StartMatchCommand _start(
  String key,
  PossessionPolicy policy, {
  bool timerEnabled = false,
  int? targetScore,
}) {
  return StartMatchCommand(
    commandId: '$key-command',
    matchId: '$key-match',
    redName: 'Red',
    blueName: 'Blue',
    ruleTemplate: RuleTemplate(
      id: key,
      name: key,
      scoreButtons: const [1, 2, 3],
      targetScore: targetScore,
      possessionHintEnabled: policy != PossessionPolicy.manual,
      possessionPolicy: policy,
    ),
    recordingMode: RecordingMode.simple,
    timerEnabled: timerEnabled,
    createdAt: DateTime.utc(2026, 8, 23),
    startedAt: DateTime.utc(2026, 8, 23),
  );
}

RecordMatchEventCommand _fieldGoal(
  String key,
  String matchId,
  String eventId,
  TeamSide side,
) {
  return RecordMatchEventCommand(
    commandId: key,
    matchId: matchId,
    eventId: eventId,
    type: EventKind.fieldGoal,
    side: side,
    points: 2,
    outcome: ShotOutcome.made,
    occurredAt: DateTime.utc(2026, 8, 23, 10),
  );
}
