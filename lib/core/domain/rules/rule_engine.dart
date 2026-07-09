import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/scoring/score_state.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

enum RuleHintType {
  matchPoint,
  targetReached,
  winByTwoRequired,
  possessionChange
}

class RuleHint {
  const RuleHint({
    required this.type,
    required this.message,
    this.isBlocking = false,
  });

  final RuleHintType type;
  final String message;
  final bool isBlocking;
}

class RuleEngine {
  List<RuleHint> evaluate({
    required RuleTemplate template,
    required ScoreState score,
    required TeamSide scoringSide,
    required int scoringPoints,
  }) {
    final targetScore = template.targetScore;
    if (targetScore == null) {
      return const [];
    }

    final newRed =
        score.redScore + (scoringSide == TeamSide.red ? scoringPoints : 0);
    final newBlue =
        score.blueScore + (scoringSide == TeamSide.blue ? scoringPoints : 0);
    final currentSideScore =
        scoringSide == TeamSide.red ? score.redScore : score.blueScore;
    final sideScore = scoringSide == TeamSide.red ? newRed : newBlue;
    final opponentScore = scoringSide == TeamSide.red ? newBlue : newRed;
    final hints = <RuleHint>[];

    if (currentSideScore == targetScore - 1 || sideScore == targetScore - 1) {
      hints.add(
        const RuleHint(
          type: RuleHintType.matchPoint,
          message: 'Match point',
        ),
      );
    }

    if (sideScore >= targetScore) {
      if (template.winByTwo && sideScore - opponentScore < 2) {
        hints.add(
          const RuleHint(
            type: RuleHintType.winByTwoRequired,
            message: 'Win by two required',
          ),
        );
      } else {
        hints.add(
          const RuleHint(
            type: RuleHintType.targetReached,
            message: 'Target score reached',
          ),
        );
      }
    }

    return hints;
  }
}
