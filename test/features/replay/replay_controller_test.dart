import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';

void main() {
  test('maps located scores and filters timeline without mutating data', () {
    final controller = ReplayController(
      data: ReplayMatchData(
        matchId: 'match-1',
        redName: '红队',
        blueName: '蓝队',
        redScore: 2,
        blueScore: 1,
        duration: const Duration(minutes: 8, seconds: 9),
        events: [
          ReplayEventData(
            id: 'score-red',
            kind: ReplayEventKind.score,
            side: TeamSide.red,
            points: 2,
            elapsed: const Duration(seconds: 12),
            shotPoint: CourtPoint(x: 0.25, y: 0.6),
          ),
          const ReplayEventData(
            id: 'foul-blue',
            kind: ReplayEventKind.foul,
            side: TeamSide.blue,
            elapsed: Duration(seconds: 20),
          ),
        ],
      ),
    );

    expect(controller.shotLocations, hasLength(1));
    expect(controller.shotLocations.single.eventId, 'score-red');
    expect(controller.shotLocations.single.side, TeamSide.red);
    expect(controller.shotLocations.single.isLocked, isTrue);

    controller.setKindFilter(ReplayKindFilter.fouls);
    controller.setSideFilter(ReplaySideFilter.blue);

    expect(controller.visibleEvents.map((event) => event.id), ['foul-blue']);
    expect(controller.data.events, hasLength(2));
  });
}
