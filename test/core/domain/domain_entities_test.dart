import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

void main() {
  test('court point rejects coordinates outside normalized court bounds', () {
    expect(() => CourtPoint(x: -0.1, y: 0.5), throwsArgumentError);
    expect(() => CourtPoint(x: 0.5, y: 1.1), throwsArgumentError);
    expect(CourtPoint(x: 0.25, y: 0.75).x, 0.25);
  });

  test('score event carries side and points', () {
    final event = MatchEvent.score(
      id: 'event-1',
      matchId: 'match-1',
      side: TeamSide.red,
      points: 2,
      occurredAt: DateTime.utc(2026, 5, 12, 12),
    );

    expect(event.side, TeamSide.red);
    expect(event.points, 2);
    expect(event.type, MatchEventType.score);
  });

  test(
    'score event requires side and positive points from base constructor',
    () {
      expect(
        () => MatchEvent(
          id: 'event-2',
          matchId: 'match-1',
          type: MatchEventType.score,
          side: null,
          points: 2,
          occurredAt: DateTime.utc(2026, 5, 12, 12),
        ),
        throwsArgumentError,
      );

      expect(
        () => MatchEvent(
          id: 'event-3',
          matchId: 'match-1',
          type: MatchEventType.score,
          side: TeamSide.red,
          points: 0,
          occurredAt: DateTime.utc(2026, 5, 12, 12),
        ),
        throwsArgumentError,
      );
    },
  );
}
