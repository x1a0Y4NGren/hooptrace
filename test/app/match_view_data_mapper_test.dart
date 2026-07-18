import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/match_view_data_mapper.dart';
import 'package:hooptrace/core/domain/entities/match.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/entities/shot_location.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';

void main() {
  test('maps persisted match detail into read-only replay data', () {
    final startedAt = DateTime.utc(2026, 7, 10, 10);
    final detail = MatchDetail(
      match: Match(
        id: 'match-1',
        createdAt: startedAt,
        startedAt: startedAt,
        endedAt: startedAt.add(const Duration(minutes: 4)),
        status: MatchStatus.finished,
        redName: '红方',
        blueName: '蓝方',
        ruleTemplateSnapshot: const RuleTemplate(
          id: 'free',
          name: '自由计分',
          scoreButtons: [1, 2, 3],
        ),
      ),
      events: [
        MatchEvent.score(
          id: 'score-1',
          matchId: 'match-1',
          side: TeamSide.red,
          points: 2,
          occurredAt: startedAt.add(const Duration(seconds: 12)),
        ),
      ],
      shotLocations: [
        ShotLocation(
          id: 'shot-1',
          matchId: 'match-1',
          eventId: 'score-1',
          point: CourtPoint(x: 0.2, y: 0.7),
          isConfirmed: true,
        ),
      ],
      redScore: 2,
      blueScore: 0,
      redFouls: 0,
      blueFouls: 0,
      shotAttemptCount: 1,
      locatedShotCount: 1,
    );

    final replay = replayDataFromDetail(detail);

    expect(replay.duration, const Duration(minutes: 4));
    expect(replay.events.single.kind, ReplayEventKind.score);
    expect(replay.events.single.elapsed, const Duration(seconds: 12));
    expect(replay.events.single.shotPoint?.x, 0.2);
    expect(replay.events.single.shotPoint?.y, 0.7);
  });

  test('omits soft-deleted events and their locations from replay data', () {
    final startedAt = DateTime.utc(2026, 7, 10, 10);
    final detail = MatchDetail(
      match: Match(
        id: 'match-1',
        createdAt: startedAt,
        startedAt: startedAt,
        status: MatchStatus.finished,
        redName: 'Red',
        blueName: 'Blue',
        ruleTemplateSnapshot: const RuleTemplate(
          id: 'free',
          name: 'Free scoring',
          scoreButtons: [1, 2, 3],
        ),
      ),
      events: [
        MatchEvent(
          id: 'deleted-score',
          matchId: 'match-1',
          type: MatchEventType.score,
          side: TeamSide.red,
          points: 2,
          occurredAt: startedAt.add(const Duration(seconds: 12)),
          isDeleted: true,
        ),
      ],
      shotLocations: [
        ShotLocation(
          id: 'deleted-shot',
          matchId: 'match-1',
          eventId: 'deleted-score',
          point: CourtPoint(x: 0.2, y: 0.7),
          isConfirmed: true,
        ),
      ],
      redScore: 0,
      blueScore: 0,
      redFouls: 0,
      blueFouls: 0,
      shotAttemptCount: 0,
      locatedShotCount: 0,
    );

    final replay = replayDataFromDetail(detail);

    expect(replay.events, isEmpty);
  });
}
