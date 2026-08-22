import 'package:hooptrace/core/domain/value_objects/team_side.dart';

import 'package:hooptrace/core/domain/domain_enums.dart';

export 'package:hooptrace/core/domain/domain_enums.dart'
    show EventKind, MatchEventType, ShotOutcome;

class MatchEvent {
  MatchEvent({
    required this.id,
    required this.matchId,
    required this.type,
    required this.side,
    required this.points,
    required this.occurredAt,
    this.note,
    ShotOutcome? outcome,
    this.matchClockPositionSeconds,
    String? customLabel,
    String? customType,
    this.isDeleted = false,
  }) : outcome = outcome,
       customLabel = _normalizeLabel(customLabel ?? customType) {
    if (type == EventKind.score || type == EventKind.fieldGoal) {
      if (side == null) {
        throw ArgumentError('Score events require a side.');
      }
      if ((this.outcome ?? ShotOutcome.made) == ShotOutcome.made &&
          points <= 0) {
        throw ArgumentError('Score points must be positive.');
      }
    }
    if (type == EventKind.freeThrow && (side == null || points <= 0)) {
      throw ArgumentError(
        'Free-throw events require a side and positive points.',
      );
    }
    if (matchClockPositionSeconds != null && matchClockPositionSeconds! < 0) {
      throw ArgumentError('Match-clock positions cannot be negative.');
    }
  }

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
      outcome: ShotOutcome.made,
    );
  }

  final String id;
  final String matchId;
  final MatchEventType type;
  final TeamSide? side;
  final int points;
  final DateTime occurredAt;
  final String? note;
  final ShotOutcome? outcome;
  final int? matchClockPositionSeconds;
  final String? customLabel;

  /// Compatibility getter for the v0.1 database field name.
  String? get customType => customLabel;
  final bool isDeleted;

  static String? _normalizeLabel(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
