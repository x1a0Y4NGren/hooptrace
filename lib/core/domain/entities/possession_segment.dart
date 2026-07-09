import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class PossessionSegment {
  const PossessionSegment({
    required this.id,
    required this.matchId,
    required this.side,
    required this.startedAtEventId,
    this.endedAtEventId,
    this.reason,
  });

  final String id;
  final String matchId;
  final TeamSide side;
  final String startedAtEventId;
  final String? endedAtEventId;
  final String? reason;
}
