import 'package:hooptrace/core/domain/value_objects/team_side.dart';

enum KeyPossessionType { tie, overtake, matchPoint, scoringRun }

class ScoringFlowEntry {
  const ScoringFlowEntry({
    required this.eventId,
    required this.side,
    required this.points,
    required this.redScore,
    required this.blueScore,
    required this.occurredAt,
  });

  final String eventId;
  final TeamSide side;
  final int points;
  final int redScore;
  final int blueScore;
  final DateTime occurredAt;

  @override
  bool operator ==(Object other) {
    return other is ScoringFlowEntry &&
        other.eventId == eventId &&
        other.side == side &&
        other.points == points &&
        other.redScore == redScore &&
        other.blueScore == blueScore &&
        other.occurredAt == occurredAt;
  }

  @override
  int get hashCode =>
      Object.hash(eventId, side, points, redScore, blueScore, occurredAt);
}

class KeyPossession {
  const KeyPossession({
    required this.type,
    required this.eventId,
    required this.side,
    required this.redScore,
    required this.blueScore,
    required this.occurredAt,
  });

  final KeyPossessionType type;
  final String eventId;
  final TeamSide side;
  final int redScore;
  final int blueScore;
  final DateTime occurredAt;

  @override
  bool operator ==(Object other) {
    return other is KeyPossession &&
        other.type == type &&
        other.eventId == eventId &&
        other.side == side &&
        other.redScore == redScore &&
        other.blueScore == blueScore &&
        other.occurredAt == occurredAt;
  }

  @override
  int get hashCode =>
      Object.hash(type, eventId, side, redScore, blueScore, occurredAt);
}

class MatchAnalytics {
  MatchAnalytics({
    required List<ScoringFlowEntry> scoringFlow,
    required this.largestLeadSide,
    required this.largestLeadPoints,
    required this.leadChanges,
    required this.madeShotCount,
    required this.missedShotCount,
    required this.shootingPercentage,
    required List<KeyPossession> keyPossessions,
  }) : scoringFlow = List.unmodifiable(scoringFlow),
       keyPossessions = List.unmodifiable(keyPossessions);

  final List<ScoringFlowEntry> scoringFlow;
  final TeamSide? largestLeadSide;
  final int largestLeadPoints;
  final int leadChanges;
  final int madeShotCount;
  final int missedShotCount;
  final double shootingPercentage;
  final List<KeyPossession> keyPossessions;

  @override
  bool operator ==(Object other) {
    return other is MatchAnalytics &&
        _listEquals(other.scoringFlow, scoringFlow) &&
        other.largestLeadSide == largestLeadSide &&
        other.largestLeadPoints == largestLeadPoints &&
        other.leadChanges == leadChanges &&
        other.madeShotCount == madeShotCount &&
        other.missedShotCount == missedShotCount &&
        other.shootingPercentage == shootingPercentage &&
        _listEquals(other.keyPossessions, keyPossessions);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(scoringFlow),
    largestLeadSide,
    largestLeadPoints,
    leadChanges,
    madeShotCount,
    missedShotCount,
    shootingPercentage,
    Object.hashAll(keyPossessions),
  );
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
