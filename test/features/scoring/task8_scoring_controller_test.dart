import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

import '../../test_helpers/test_database.dart';

void main() {
  test(
    'projection exposes mode coverage clock and latest possession',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final started = await service.start(
          _startCommand(
            matchId: 'task8-projection',
            recordingMode: RecordingMode.detailed,
            trackingCoverage: TrackingCoverage.locations,
            timerEnabled: false,
          ),
        );
        final withPossession = await service.record(
          RecordMatchEventCommand(
            matchId: started.match.id,
            type: EventKind.possession,
            side: TeamSide.blue,
            points: 0,
            occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
          ),
        );

        final controller = ScoringController.fromCommittedProjection(
          withPossession,
          service,
        );

        expect(controller.recordingMode, RecordingMode.detailed);
        expect(controller.trackingCoverage, TrackingCoverage.locations);
        expect(controller.clock, isNotNull);
        expect(controller.currentPossession, TeamSide.blue);
      });
    },
  );

  test(
    'simple made score is committed without blocking the next score',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final started = await service.start(
          _startCommand(matchId: 'task8-queue'),
        );
        final controller = ScoringController.fromCommittedProjection(
          started,
          service,
        );

        final first = controller.recordScoreCommitted(
          side: TeamSide.red,
          points: 2,
        );
        final second = controller.recordScoreCommitted(
          side: TeamSide.blue,
          points: 3,
        );

        expect(await first, isTrue);
        expect(await second, isTrue);
        expect(controller.state.score.redScore, 2);
        expect(controller.state.score.blueScore, 3);
        expect(controller.state.pendingLocation, isNull);
        expect(
          await (database.select(
            database.matchEvents,
          )..where((row) => row.matchId.equals(started.match.id))).get(),
          hasLength(2),
        );
      });
    },
  );

  test(
    'ordinary rapid input is serialized in command creation order',
    () async {
      await withTestDatabase((database) async {
        final firstEntered = Completer<void>();
        final releaseFirst = Completer<void>();
        var recordCalls = 0;
        final service = MatchCommandService(
          database,
          failureInjector: (point) async {
            if (point == MatchCommandFailurePoint.beforeCommit &&
                ++recordCalls == 2) {
              firstEntered.complete();
              await releaseFirst.future;
            }
          },
        );
        final started = await service.start(
          _startCommand(matchId: 'task8-order'),
        );
        final controller = ScoringController.fromCommittedProjection(
          started,
          service,
        );

        final first = controller.recordScoreCommitted(
          side: TeamSide.red,
          points: 1,
        );
        await firstEntered.future;
        final second = controller.recordScoreCommitted(
          side: TeamSide.blue,
          points: 2,
        );
        releaseFirst.complete();

        expect(await first, isTrue);
        expect(await second, isTrue);
        final events = await (database.select(
          database.matchEvents,
        )..where((row) => row.matchId.equals(started.match.id))).get();
        expect(events.map((event) => event.points), [1, 2]);
      });
    },
  );

  test(
    'free throws, miss, foul, possession, note, and custom are command-backed',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final started = await service.start(
          _startCommand(
            matchId: 'task8-actions',
            trackingCoverage: TrackingCoverage.shotAttempts,
          ),
        );
        final controller = ScoringController.fromCommittedProjection(
          started,
          service,
        );

        expect(
          await controller.recordFreeThrowCommitted(
            side: TeamSide.red,
            made: true,
          ),
          isTrue,
        );
        expect(
          await controller.recordFreeThrowCommitted(
            side: TeamSide.red,
            made: false,
          ),
          isTrue,
        );
        expect(
          await controller.recordMissCommitted(side: TeamSide.blue),
          isTrue,
        );
        expect(await controller.recordFoulCommitted(TeamSide.blue), isTrue);
        expect(
          await controller.recordPossessionCommitted(TeamSide.red),
          isTrue,
        );
        expect(await controller.recordNoteCommitted('timeout'), isTrue);
        expect(
          await controller.recordCustomCommitted(
            label: '救球',
            side: TeamSide.red,
          ),
          isTrue,
        );

        final events = await (database.select(
          database.matchEvents,
        )..where((row) => row.matchId.equals(started.match.id))).get();
        expect(events.map((event) => event.type), [
          EventKind.freeThrow.name,
          EventKind.freeThrow.name,
          EventKind.fieldGoal.name,
          EventKind.foul.name,
          EventKind.possession.name,
          EventKind.note.name,
          EventKind.custom.name,
        ]);
        expect(events[1].outcome, ShotOutcome.missed.name);
        expect(events[2].outcome, ShotOutcome.missed.name);
        expect(controller.currentPossession, TeamSide.red);
      });
    },
  );

  test('miss tracking is rejected when coverage excludes attempts', () async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final started = await service.start(
        _startCommand(
          matchId: 'task8-coverage',
          trackingCoverage: TrackingCoverage.scoresOnly,
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        started,
        service,
      );

      expect(await controller.recordMissCommitted(side: TeamSide.red), isFalse);
      expect(await database.select(database.matchEvents).get(), isEmpty);
    });
  });

  test(
    'locate-last-shot is explicit and cancel leaves history unlocated',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final started = await service.start(
          _startCommand(
            matchId: 'task8-location',
            trackingCoverage: TrackingCoverage.locations,
          ),
        );
        final controller = ScoringController.fromCommittedProjection(
          started,
          service,
        );
        await controller.recordScoreCommitted(side: TeamSide.red, points: 2);

        expect(controller.beginLocateLastUnlocatedShot(), isTrue);
        expect(controller.state.pendingLocation, isNotNull);
        expect(controller.cancelLocateLastUnlocatedShot(), isTrue);
        expect(controller.state.pendingLocation, isNull);
        expect(controller.state.score.redScore, 2);
        expect(await database.select(database.shotLocations).get(), isEmpty);
      });
    },
  );

  test(
    'detailed shot is a local court-first draft and commits one event plus location',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final started = await service.start(
          _startCommand(
            matchId: 'task8-detailed',
            recordingMode: RecordingMode.detailed,
            trackingCoverage: TrackingCoverage.locations,
          ),
        );
        final possession = await service.record(
          RecordMatchEventCommand(
            matchId: started.match.id,
            type: EventKind.possession,
            side: TeamSide.blue,
            points: 0,
            occurredAt: DateTime.utc(2026, 8, 23, 9, 1),
          ),
        );
        final controller = ScoringController.fromCommittedProjection(
          possession,
          service,
        );

        expect(
          controller.beginDetailedShot(CourtPoint(x: 0.2, y: 0.8)),
          isTrue,
        );
        expect(controller.detailedShotDraft?.side, TeamSide.blue);
        controller.updateDetailedShot(side: TeamSide.red, points: 3);
        expect(await controller.commitDetailedShot(), isTrue);
        expect(controller.detailedShotDraft, isNull);
        final events = await database.select(database.matchEvents).get();
        expect(
          events.where((event) => event.type == EventKind.fieldGoal.name),
          hasLength(1),
        );
        expect(events.last.type, EventKind.fieldGoal.name);
        expect(events.last.side, TeamSide.red.name);
        expect(events.last.points, 3);
        expect(
          await database.select(database.shotLocations).get(),
          hasLength(1),
        );
      });
    },
  );

  test(
    'an explicitly located missed field goal keeps the missed outcome',
    () async {
      await withTestDatabase((database) async {
        final service = MatchCommandService(database);
        final started = await service.start(
          _startCommand(
            matchId: 'task8-missed-location',
            trackingCoverage: TrackingCoverage.locations,
          ),
        );
        final controller = ScoringController.fromCommittedProjection(
          started,
          service,
        );
        await controller.recordMissCommitted(side: TeamSide.red);
        expect(controller.beginLocateLastUnlocatedShot(), isTrue);
        await controller.confirmPendingLocation(CourtPoint(x: 0.1, y: 0.9));

        final event = await database.select(database.matchEvents).getSingle();
        expect(event.outcome, ShotOutcome.missed.name);
        expect(
          await database.select(database.shotLocations).get(),
          hasLength(1),
        );
      });
    },
  );

  test('detailed draft cancellation writes no event or location', () async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final started = await service.start(
        _startCommand(
          matchId: 'task8-cancel',
          recordingMode: RecordingMode.detailed,
          trackingCoverage: TrackingCoverage.locations,
        ),
      );
      final controller = ScoringController.fromCommittedProjection(
        started,
        service,
      );
      expect(controller.beginDetailedShot(CourtPoint(x: 0.5, y: 0.5)), isTrue);
      expect(controller.cancelDetailedShot(), isTrue);
      expect(await database.select(database.matchEvents).get(), isEmpty);
      expect(await database.select(database.shotLocations).get(), isEmpty);
    });
  });

  test('pause and resume use semantic command events', () async {
    await withTestDatabase((database) async {
      final service = MatchCommandService(database);
      final started = await service.start(
        _startCommand(matchId: 'task8-clock', timerEnabled: false),
      );
      final controller = ScoringController.fromCommittedProjection(
        started,
        service,
      );

      expect(await controller.pauseCommitted(), isTrue);
      expect(await controller.resumeCommitted(), isTrue);
      final events = await database.select(database.matchEvents).get();
      expect(events.map((event) => event.customLabel), ['pause', 'resume']);
    });
  });

  test(
    'retry keeps the original command and updates projection after commit',
    () async {
      await withTestDatabase((database) async {
        var beforeCommitCalls = 0;
        var armed = false;
        final service = MatchCommandService(
          database,
          failureInjector: (point) {
            if (armed &&
                point == MatchCommandFailurePoint.beforeCommit &&
                beforeCommitCalls++ == 0) {
              throw StateError('retry once');
            }
          },
        );
        final started = await service.start(
          _startCommand(matchId: 'task8-retry'),
        );
        armed = true;
        final controller = ScoringController.fromCommittedProjection(
          started,
          service,
        );

        MatchCommandFailure? failure;
        try {
          await controller.recordScoreCommitted(side: TeamSide.red, points: 2);
        } on MatchCommandFailure catch (error) {
          failure = error;
        }
        expect(failure, isNotNull);
        expect(failure!.command, isA<RecordMatchEventCommand>());
        await controller.retryCommand(failure);
        expect(controller.state.score.redScore, 2);
        expect(await database.select(database.matchEvents).get(), hasLength(1));
      });
    },
  );

  test(
    'disposed controller does not mutate or notify after queued command commits',
    () async {
      await withTestDatabase((database) async {
        final entered = Completer<void>();
        final release = Completer<void>();
        var armed = false;
        final service = MatchCommandService(
          database,
          failureInjector: (point) async {
            if (armed && point == MatchCommandFailurePoint.beforeCommit) {
              entered.complete();
              await release.future;
            }
          },
        );
        final started = await service.start(
          _startCommand(matchId: 'task8-dispose'),
        );
        armed = true;
        final controller = ScoringController.fromCommittedProjection(
          started,
          service,
        );
        var notifications = 0;
        controller.addListener(() => notifications++);
        final command = controller.recordScoreCommitted(
          side: TeamSide.red,
          points: 2,
        );
        await entered.future;
        controller.dispose();
        release.complete();
        expect(await command, isFalse);
        expect(notifications, 0);
        expect(await database.select(database.matchEvents).get(), hasLength(1));
      });
    },
  );
}

StartMatchCommand _startCommand({
  required String matchId,
  RecordingMode recordingMode = RecordingMode.simple,
  TrackingCoverage trackingCoverage = TrackingCoverage.scoresOnly,
  bool timerEnabled = false,
}) {
  return StartMatchCommand(
    commandId: '$matchId-start',
    matchId: matchId,
    redName: 'Red',
    blueName: 'Blue',
    ruleTemplate: const RuleTemplate(
      id: 'free',
      name: 'Free',
      scoreButtons: [1, 2, 3],
    ),
    recordingMode: recordingMode,
    trackingCoverage: trackingCoverage,
    timerEnabled: timerEnabled,
    createdAt: DateTime.utc(2026, 8, 23, 9),
    startedAt: DateTime.utc(2026, 8, 23, 9),
  );
}
