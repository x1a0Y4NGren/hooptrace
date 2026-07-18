import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class MatchAnalyticsCalculator {
  MatchAnalytics calculate(
    List<MatchEvent> events, {
    int? targetScore,
    bool winByTwo = false,
  }) {
    final orderedEvents = events
        .asMap()
        .entries
        .where((entry) => !entry.value.isDeleted)
        .map((entry) => _IndexedEvent(entry.key, entry.value))
        .toList()
      ..sort((first, second) {
        final timeComparison =
            first.event.occurredAt.compareTo(second.event.occurredAt);
        return timeComparison == 0
            ? first.index.compareTo(second.index)
            : timeComparison;
      });

    var redScore = 0;
    var blueScore = 0;
    var madeShotCount = 0;
    var missedShotCount = 0;
    var largestLeadPoints = 0;
    TeamSide? largestLeadSide;
    TeamSide? previousLeader;
    var leadChanges = 0;
    TeamSide? scoringRunSide;
    var scoringRunLength = 0;

    final scoringFlow = <ScoringFlowEntry>[];
    final keyPossessions = <KeyPossession>[];

    for (final indexedEvent in orderedEvents) {
      final event = indexedEvent.event;
      if (event.type == MatchEventType.miss) {
        missedShotCount++;
        continue;
      }
      if (event.type != MatchEventType.score) continue;

      final side = event.side!;
      if (side == TeamSide.red) {
        redScore += event.points;
      } else {
        blueScore += event.points;
      }
      madeShotCount++;

      scoringFlow.add(
        ScoringFlowEntry(
          eventId: event.id,
          side: side,
          points: event.points,
          redScore: redScore,
          blueScore: blueScore,
          occurredAt: event.occurredAt,
        ),
      );

      final leader = _leader(redScore, blueScore);
      final leadChanged =
          previousLeader != null && leader != null && previousLeader != leader;
      if (leadChanged) {
        leadChanges++;
      }
      if (leader != null) {
        previousLeader = leader;
      }

      final leadPoints = (redScore - blueScore).abs();
      if (leadPoints > largestLeadPoints) {
        largestLeadPoints = leadPoints;
        largestLeadSide = leader;
      }

      if (redScore == blueScore && redScore != 0) {
        keyPossessions.add(
          _keyPossession(
            type: KeyPossessionType.tie,
            event: event,
            redScore: redScore,
            blueScore: blueScore,
          ),
        );
      }

      if (leadChanged) {
        keyPossessions.add(
          _keyPossession(
            type: KeyPossessionType.overtake,
            event: event,
            redScore: redScore,
            blueScore: blueScore,
          ),
        );
      }

      final sideScore = side == TeamSide.red ? redScore : blueScore;
      final opponentScore = side == TeamSide.red ? blueScore : redScore;
      if (_isMatchPoint(
        sideScore: sideScore,
        opponentScore: opponentScore,
        targetScore: targetScore,
        winByTwo: winByTwo,
      )) {
        keyPossessions.add(
          _keyPossession(
            type: KeyPossessionType.matchPoint,
            event: event,
            redScore: redScore,
            blueScore: blueScore,
          ),
        );
      }

      if (scoringRunSide == side) {
        scoringRunLength++;
      } else {
        scoringRunSide = side;
        scoringRunLength = 1;
      }
      if (scoringRunLength == 3) {
        keyPossessions.add(
          _keyPossession(
            type: KeyPossessionType.scoringRun,
            event: event,
            redScore: redScore,
            blueScore: blueScore,
          ),
        );
      }
    }

    final attempts = madeShotCount + missedShotCount;
    return MatchAnalytics(
      scoringFlow: scoringFlow,
      largestLeadSide: largestLeadSide,
      largestLeadPoints: largestLeadPoints,
      leadChanges: leadChanges,
      madeShotCount: madeShotCount,
      missedShotCount: missedShotCount,
      shootingPercentage: attempts == 0 ? 0 : madeShotCount / attempts,
      keyPossessions: keyPossessions,
    );
  }

  KeyPossession _keyPossession({
    required KeyPossessionType type,
    required MatchEvent event,
    required int redScore,
    required int blueScore,
  }) {
    return KeyPossession(
      type: type,
      eventId: event.id,
      side: event.side!,
      redScore: redScore,
      blueScore: blueScore,
      occurredAt: event.occurredAt,
    );
  }

  TeamSide? _leader(int redScore, int blueScore) {
    if (redScore == blueScore) return null;
    return redScore > blueScore ? TeamSide.red : TeamSide.blue;
  }

  bool _isMatchPoint({
    required int sideScore,
    required int opponentScore,
    required int? targetScore,
    required bool winByTwo,
  }) {
    if (targetScore == null) return false;
    if (!winByTwo) return sideScore == targetScore - 1;
    if (sideScore <= opponentScore) return false;
    if (sideScore < targetScore) return sideScore == targetScore - 1;
    return sideScore - opponentScore == 1;
  }
}

class _IndexedEvent {
  const _IndexedEvent(this.index, this.event);

  final int index;
  final MatchEvent event;
}
