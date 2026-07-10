import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/match_session_coordinator.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';

void main() {
  test('persists the latest scoring snapshot including undo', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = MatchRepository(database);
    final coordinator = MatchSessionCoordinator(repository);
    addTearDown(coordinator.dispose);
    const setup = MatchSetup(
      matchId: 'match-session',
      redName: '红方',
      blueName: '蓝方',
      ruleTemplateId: 'free',
      targetScore: 11,
      timerEnabled: false,
      timeLimitMinutes: 10,
      winByTwo: false,
    );

    final controller = coordinator.beginMatch(setup);
    controller.addScore(side: TeamSide.red, points: 2);
    controller.skipPendingLocation();
    controller.undoLastEvent();
    controller.addScore(side: TeamSide.blue, points: 3);
    controller.skipPendingLocation();
    await coordinator.saveCurrent(setup.matchId);

    final detail = await repository.getMatchDetail(setup.matchId);
    expect(detail, isNotNull);
    expect(detail!.events, hasLength(1));
    expect(detail.redScore, 0);
    expect(detail.blueScore, 3);
  });
}
