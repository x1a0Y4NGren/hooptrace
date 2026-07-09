import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/rules/rule_engine.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

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
      controller.state.events
          .where((event) => event.type == MatchEventType.foul),
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
}
