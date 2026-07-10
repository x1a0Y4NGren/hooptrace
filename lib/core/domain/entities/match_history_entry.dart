import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class MatchHistoryEntry {
  const MatchHistoryEntry({
    required this.id,
    required this.playedAt,
    required this.redName,
    required this.blueName,
    required this.redScore,
    required this.blueScore,
    required this.winner,
    required this.ruleName,
    required this.duration,
    required this.shotAttemptCount,
    required this.locatedShotCount,
    required this.shotLocationCompleteness,
  });

  final String id;
  final DateTime playedAt;
  final String redName;
  final String blueName;
  final int redScore;
  final int blueScore;
  final TeamSide? winner;
  final String ruleName;
  final Duration? duration;
  final int shotAttemptCount;
  final int locatedShotCount;
  final double shotLocationCompleteness;
}
