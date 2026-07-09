import 'package:hooptrace/core/domain/value_objects/team_side.dart';

enum MatchEventType {
  score,
  miss,
  foul,
  reward,
  pause,
  interruption,
  note,
  custom,
}

class MatchEvent {
  const MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    required this.side,
    required this.points,
    required this.occurredAt,
    this.note,
    this.customType,
    this.isDeleted = false,
  });

  factory MatchEvent.score({
    required String id,
    required String matchId,
    required TeamSide side,
    required int points,
    required DateTime occurredAt,
  }) {
    if (points <= 0) {
      throw ArgumentError('Score points must be positive.');
    }
    return MatchEvent(
      id: id,
      matchId: matchId,
      type: MatchEventType.score,
      side: side,
      points: points,
      occurredAt: occurredAt,
    );
  }

  final String id;
  final String matchId;
  final MatchEventType type;
  final TeamSide? side;
  final int points;
  final DateTime occurredAt;
  final String? note;
  final String? customType;
  final bool isDeleted;
}
