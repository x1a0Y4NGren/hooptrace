import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics_calculator.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

void main() {
  final calculator = MatchAnalyticsCalculator();

  test(
      'calculates a stable chronological scoring flow and ignores deleted events',
      () {
    final start = DateTime.utc(2026);
    final events = [
      _score(
        'blue-later',
        TeamSide.blue,
        2,
        start.add(const Duration(minutes: 2)),
      ),
      _score(
        'red-first',
        TeamSide.red,
        2,
        start.add(const Duration(minutes: 1)),
      ),
      _score(
        'red-same-time',
        TeamSide.red,
        1,
        start.add(const Duration(minutes: 1)),
      ),
      MatchEvent(
        id: 'deleted',
        matchId: 'm1',
        type: MatchEventType.score,
        side: TeamSide.blue,
        points: 100,
        occurredAt: start,
        isDeleted: true,
      ),
    ];

    final analytics = calculator.calculate(events);

    expect(
      analytics.scoringFlow,
      [
        ScoringFlowEntry(
          eventId: 'red-first',
          side: TeamSide.red,
          points: 2,
          redScore: 2,
          blueScore: 0,
          occurredAt: start.add(const Duration(minutes: 1)),
        ),
        ScoringFlowEntry(
          eventId: 'red-same-time',
          side: TeamSide.red,
          points: 1,
          redScore: 3,
          blueScore: 0,
          occurredAt: start.add(const Duration(minutes: 1)),
        ),
        ScoringFlowEntry(
          eventId: 'blue-later',
          side: TeamSide.blue,
          points: 2,
          redScore: 3,
          blueScore: 2,
          occurredAt: start.add(const Duration(minutes: 2)),
        ),
      ],
    );
    expect(analytics.largestLeadSide, TeamSide.red);
    expect(analytics.largestLeadPoints, 3);
  });

  test('counts when non-tied leader switches across ties', () {
    final start = DateTime.utc(2026);
    final analytics = calculator.calculate([
      _score('r1', TeamSide.red, 2, start),
      _score('b1', TeamSide.blue, 2, start.add(const Duration(seconds: 1))),
      _score('b2', TeamSide.blue, 1, start.add(const Duration(seconds: 2))),
      _score('r2', TeamSide.red, 1, start.add(const Duration(seconds: 3))),
      _score('r3', TeamSide.red, 1, start.add(const Duration(seconds: 4))),
      _score('b3', TeamSide.blue, 3, start.add(const Duration(seconds: 5))),
    ]);

    expect(analytics.leadChanges, 3);
    expect(analytics.largestLeadSide, TeamSide.red);
    expect(analytics.largestLeadPoints, 2);
  });

  test('calculates shooting percentage from made and missed shots', () {
    final start = DateTime.utc(2026);
    final analytics = calculator.calculate([
      _score('r1', TeamSide.red, 2, start),
      _score('r2', TeamSide.red, 3, start.add(const Duration(seconds: 1))),
      _miss('r3', TeamSide.red, start.add(const Duration(seconds: 2))),
      _miss('b1', TeamSide.blue, start.add(const Duration(seconds: 3))),
      MatchEvent(
        id: 'deleted-miss',
        matchId: 'm1',
        type: MatchEventType.miss,
        side: TeamSide.blue,
        points: 0,
        occurredAt: start.add(const Duration(seconds: 4)),
        isDeleted: true,
      ),
    ]);

    expect(analytics.madeShotCount, 2);
    expect(analytics.missedShotCount, 2);
    expect(analytics.shootingPercentage, 0.5);
    final empty = calculator.calculate(const []);
    expect(empty.shootingPercentage, 0);
    expect(empty.scoringFlow, isEmpty);
    expect(empty.largestLeadSide, isNull);
    expect(empty.largestLeadPoints, 0);
    expect(empty.leadChanges, 0);
  });

  test('records tie, overtake, match point, and one scoring run possession',
      () {
    final start = DateTime.utc(2026);
    final analytics = calculator.calculate(
      [
        _score('r1', TeamSide.red, 2, start),
        _score('b1', TeamSide.blue, 2, start.add(const Duration(seconds: 1))),
        _score('b2', TeamSide.blue, 2, start.add(const Duration(seconds: 2))),
        _score('r2', TeamSide.red, 3, start.add(const Duration(seconds: 3))),
        _score('r3', TeamSide.red, 1, start.add(const Duration(seconds: 4))),
        _score('r4', TeamSide.red, 1, start.add(const Duration(seconds: 5))),
      ],
      targetScore: 7,
    );

    expect(
      analytics.keyPossessions,
      [
        KeyPossession(
          type: KeyPossessionType.tie,
          eventId: 'b1',
          side: TeamSide.blue,
          redScore: 2,
          blueScore: 2,
          occurredAt: start.add(const Duration(seconds: 1)),
        ),
        KeyPossession(
          type: KeyPossessionType.overtake,
          eventId: 'b2',
          side: TeamSide.blue,
          redScore: 2,
          blueScore: 4,
          occurredAt: start.add(const Duration(seconds: 2)),
        ),
        KeyPossession(
          type: KeyPossessionType.overtake,
          eventId: 'r2',
          side: TeamSide.red,
          redScore: 5,
          blueScore: 4,
          occurredAt: start.add(const Duration(seconds: 3)),
        ),
        KeyPossession(
          type: KeyPossessionType.matchPoint,
          eventId: 'r3',
          side: TeamSide.red,
          redScore: 6,
          blueScore: 4,
          occurredAt: start.add(const Duration(seconds: 4)),
        ),
        KeyPossession(
          type: KeyPossessionType.scoringRun,
          eventId: 'r4',
          side: TeamSide.red,
          redScore: 7,
          blueScore: 4,
          occurredAt: start.add(const Duration(seconds: 5)),
        ),
      ],
    );
  });

  test('records an overtake after scoring through a tie', () {
    final start = DateTime.utc(2026);
    final analytics = calculator.calculate([
      _score('r1', TeamSide.red, 2, start),
      _score('b1', TeamSide.blue, 2, start.add(const Duration(seconds: 1))),
      _score('b2', TeamSide.blue, 1, start.add(const Duration(seconds: 2))),
    ]);

    expect(
      analytics.keyPossessions.map((item) => item.type),
      [KeyPossessionType.tie, KeyPossessionType.overtake],
    );
    expect(analytics.keyPossessions.last.eventId, 'b2');
  });

  test('win-by-two match point excludes ties and follows one-point leads', () {
    final start = DateTime.utc(2026);
    final analytics = calculator.calculate(
      [
        _score('b10', TeamSide.blue, 10, start),
        _score('r10', TeamSide.red, 10, start.add(const Duration(seconds: 1))),
        _score('r11', TeamSide.red, 1, start.add(const Duration(seconds: 2))),
      ],
      targetScore: 11,
      winByTwo: true,
    );

    expect(
      analytics.keyPossessions
          .where((item) => item.type == KeyPossessionType.matchPoint)
          .map((item) => item.eventId),
      ['b10', 'r11'],
    );
  });

  test(
      'analytics and nested value objects compare by value and expose immutable lists',
      () {
    final start = DateTime.utc(2026);
    final events = [_score('r1', TeamSide.red, 2, start)];
    final first = calculator.calculate(events);
    final second = calculator.calculate(events);

    expect(first, second);
    expect(first.scoringFlow.single, second.scoringFlow.single);
    expect(
      () => first.scoringFlow.add(first.scoringFlow.single),
      throwsUnsupportedError,
    );
    expect(
      () => first.keyPossessions.add(
        KeyPossession(
          type: KeyPossessionType.tie,
          eventId: 'unused',
          side: TeamSide.red,
          redScore: 1,
          blueScore: 1,
          occurredAt: start,
        ),
      ),
      throwsUnsupportedError,
    );
  });
}

MatchEvent _score(String id, TeamSide side, int points, DateTime occurredAt) {
  return MatchEvent.score(
    id: id,
    matchId: 'm1',
    side: side,
    points: points,
    occurredAt: occurredAt,
  );
}

MatchEvent _miss(String id, TeamSide side, DateTime occurredAt) {
  return MatchEvent(
    id: id,
    matchId: 'm1',
    type: MatchEventType.miss,
    side: side,
    points: 0,
    occurredAt: occurredAt,
  );
}
