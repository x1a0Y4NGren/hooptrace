import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/audit/audit_log_entry.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/rules/rule_engine.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

import '../../test_helpers/test_database.dart';

void main() {
  test('adding a score creates a pending location and updates totals', () {
    final controller = ScoringController(matchId: 'match-1');

    controller.addScore(side: TeamSide.red, points: 2);

    expect(controller.state.score.redScore, 2);
    expect(controller.state.blueFouls, 0);
    expect(controller.state.pendingLocation?.side, TeamSide.red);
    expect(controller.state.pendingLocation?.points, 2);
  });

  test('adding another score is rejected while a location is pending', () {
    final controller = ScoringController(matchId: 'match-1');

    final firstAccepted = controller.addScore(side: TeamSide.red, points: 2);
    final secondAccepted = controller.addScore(side: TeamSide.blue, points: 3);

    expect(firstAccepted, isTrue);
    expect(secondAccepted, isFalse);
    expect(controller.state.score.redScore, 2);
    expect(controller.state.score.blueScore, 0);
    expect(controller.state.pendingLocation?.side, TeamSide.red);
  });

  test('skipping a location keeps the score without recording a marker', () {
    final controller = ScoringController(matchId: 'match-1');

    controller.addScore(side: TeamSide.red, points: 1);
    controller.skipPendingLocation();

    expect(controller.state.score.redScore, 1);
    expect(controller.state.pendingLocation, isNull);
    expect(controller.state.shotLocations, isEmpty);
  });

  test('confirming a pending location locks and records the court point', () {
    final controller = ScoringController(matchId: 'match-1');
    final point = CourtPoint(x: 0.25, y: 0.75);

    controller.addScore(side: TeamSide.blue, points: 2);
    controller.confirmPendingLocation(point);

    expect(controller.state.pendingLocation, isNull);
    expect(controller.state.shotLocations, hasLength(1));
    expect(controller.state.shotLocations.single.side, TeamSide.blue);
    expect(controller.state.shotLocations.single.point.x, 0.25);
    expect(controller.state.shotLocations.single.isLocked, isTrue);
  });

  test('fouls are accumulated per side', () {
    final controller = ScoringController(matchId: 'match-1');

    controller.addFoul(TeamSide.red);
    controller.addFoul(TeamSide.red);
    controller.addFoul(TeamSide.blue);

    expect(controller.state.redFouls, 2);
    expect(controller.state.blueFouls, 1);
    expect(
      controller.state.events.where(
        (event) => event.type == MatchEventType.foul,
      ),
      hasLength(3),
    );
  });

  test('undo rolls back the latest foul event', () {
    final controller = ScoringController(matchId: 'match-1');

    controller.addFoul(TeamSide.red);
    controller.addFoul(TeamSide.blue);
    controller.undoLastEvent();

    expect(controller.state.redFouls, 1);
    expect(controller.state.blueFouls, 0);
  });

  test('target score setup produces rule hints while scoring', () {
    final controller = ScoringController(
      setup: const MatchSetup(
        matchId: 'match-1',
        redName: 'Red',
        blueName: 'Blue',
        ruleTemplateId: 'eleven',
        targetScore: 2,
        timerEnabled: false,
        timeLimitMinutes: 10,
        winByTwo: false,
      ),
    );

    controller.addScore(side: TeamSide.red, points: 2);

    expect(controller.state.ruleHints.single.type, RuleHintType.targetReached);
  });

  test('preserves the selected rule name in the scoring snapshot', () {
    final controller = ScoringController(
      setup: const MatchSetup(
        matchId: 'match-custom',
        redName: 'Red',
        blueName: 'Blue',
        ruleTemplateId: 'custom-15',
        ruleTemplateName: 'Custom 15',
        targetScore: 15,
        timerEnabled: false,
        timeLimitMinutes: 10,
        winByTwo: false,
      ),
    );

    expect(controller.state.ruleTemplate.name, 'Custom 15');
  });

  test(
    'command-backed made score commits as fieldGoal and creates pending location',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final start = StartMatchCommand(
          commandId: 'ui-score-start-command',
          matchId: 'ui-score-match',
          redName: 'Red',
          blueName: 'Blue',
          ruleTemplate: const RuleTemplate(
            id: 'free',
            name: 'Free',
            scoreButtons: [1, 2, 3],
          ),
          createdAt: DateTime.utc(2026, 8, 23, 9),
          startedAt: DateTime.utc(2026, 8, 23, 9),
        );
        final projection = await service.start(start);
        final controller = ScoringController.fromCommittedProjection(
          projection,
          service,
        );

        expect(
          await controller.recordScoreCommitted(side: TeamSide.red, points: 2),
          isTrue,
        );

        final event = await (database.select(
          database.matchEvents,
        )..where((row) => row.matchId.equals(start.matchId))).getSingle();
        expect(event.type, EventKind.fieldGoal.name);
        expect(event.outcome, ShotOutcome.made.name);
        expect(controller.state.pendingLocation, isNotNull);
        expect(controller.state.pendingLocation!.eventId, event.id);
      });
    },
  );

  test(
    'command-backed confirmation persists fieldGoal location after commit',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final start = await _startCommandBackedMatch(service);
        final controller = ScoringController.fromCommittedProjection(
          start,
          service,
        );
        await controller.recordScoreCommitted(side: TeamSide.red, points: 2);

        await controller.confirmPendingLocation(CourtPoint(x: 0.25, y: 0.75));

        expect(controller.state.pendingLocation, isNull);
        expect(controller.state.shotLocations, hasLength(1));
        expect(controller.state.shotLocations.single.point.x, 0.25);
        expect(
          await database.select(database.shotLocations).get(),
          hasLength(1),
        );
      });
    },
  );

  test('command-backed skip leaves a committed unlocated fieldGoal', () async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final start = await _startCommandBackedMatch(service);
      final controller = ScoringController.fromCommittedProjection(
        start,
        service,
      );
      await controller.recordScoreCommitted(side: TeamSide.blue, points: 3);

      controller.skipPendingLocation();

      expect(controller.state.pendingLocation, isNull);
      expect(controller.state.score.blueScore, 3);
      expect(controller.state.shotLocations, isEmpty);
      expect(await database.select(database.shotLocations).get(), isEmpty);
      expect(await database.select(database.matchEvents).get(), hasLength(1));
    });
  });

  test(
    'failed command-backed confirmation keeps pending state and retries the same command',
    () async {
      await withTestDatabase((database) async {
        var beforeCommitCalls = 0;
        final service = MatchCommandService(
          database,
          failureInjector: (point) {
            if (point == MatchCommandFailurePoint.beforeCommit &&
                beforeCommitCalls++ == 2) {
              throw StateError('confirm failed once');
            }
          },
        );
        final start = await _startCommandBackedMatch(service);
        final controller = ScoringController.fromCommittedProjection(
          start,
          service,
        );
        await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
        final pendingEventId = controller.state.pendingLocation!.eventId;

        MatchCommandFailure? failure;
        try {
          await controller.confirmPendingLocation(CourtPoint(x: 0.25, y: 0.75));
        } on MatchCommandFailure catch (error) {
          failure = error;
        }

        expect(failure, isA<CommandTransactionFailure>());
        expect(failure!.command.commandId, isNotEmpty);
        expect(controller.state.pendingLocation!.eventId, pendingEventId);
        expect(await database.select(database.shotLocations).get(), isEmpty);

        await controller.retryCommand(failure);

        expect(controller.state.pendingLocation, isNull);
        expect(controller.state.shotLocations, hasLength(1));
        final receipts = await (database.select(
          database.auditLogs,
        )..where((row) => row.id.equals(failure!.command.commandId))).get();
        expect(receipts, hasLength(1));
        expect(receipts.single.action, AuditAction.command.name);
      });
    },
  );
}

Future<MatchDetail> _startCommandBackedMatch(MatchCommandService service) {
  return service.start(
    StartMatchCommand(
      commandId: 'ui-command-${DateTime.now().microsecondsSinceEpoch}',
      matchId: 'ui-command-match-${DateTime.now().microsecondsSinceEpoch}',
      redName: 'Red',
      blueName: 'Blue',
      ruleTemplate: const RuleTemplate(
        id: 'free',
        name: 'Free',
        scoreButtons: [1, 2, 3],
      ),
      createdAt: DateTime.utc(2026, 8, 23, 9),
      startedAt: DateTime.utc(2026, 8, 23, 9),
    ),
  );
}
