import 'package:hooptrace/core/domain/entities/match.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/shot_location.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class MatchDetail {
  const MatchDetail({
    required this.match,
    required this.events,
    required this.shotLocations,
    required this.redScore,
    required this.blueScore,
    required this.redFouls,
    required this.blueFouls,
    required this.shotAttemptCount,
    required this.locatedShotCount,
  });

  final Match match;
  final List<MatchEvent> events;
  final List<ShotLocation> shotLocations;
  final int redScore;
  final int blueScore;
  final int redFouls;
  final int blueFouls;
  final int shotAttemptCount;
  final int locatedShotCount;

  TeamSide? get winner {
    if (redScore == blueScore) {
      return null;
    }
    return redScore > blueScore ? TeamSide.red : TeamSide.blue;
  }

  Duration? get duration {
    final endedAt = match.endedAt;
    if (endedAt == null) {
      return null;
    }
    return endedAt.difference(match.startedAt ?? match.createdAt);
  }

  double get shotLocationCompleteness {
    if (shotAttemptCount == 0) {
      return 0;
    }
    return locatedShotCount / shotAttemptCount;
  }
}
