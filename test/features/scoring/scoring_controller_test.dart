import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

void main() {
  test('adding a score creates a pending location and updates totals', () {
    final controller = ScoringController(matchId: 'match-1');

    controller.addScore(side: TeamSide.red, points: 2);
    controller.addScore(side: TeamSide.blue, points: 3);

    expect(controller.state.score.redScore, 2);
    expect(controller.state.score.blueScore, 3);
    expect(controller.state.pendingLocation?.side, TeamSide.blue);
    expect(controller.state.pendingLocation?.points, 3);
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
  });
}
