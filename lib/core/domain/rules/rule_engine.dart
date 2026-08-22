import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/scoring/score_state.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

enum RuleHintType {
  matchPoint,
  targetReached,
  winByTwoRequired,
  possessionChange,
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
    final hints = <RuleHint>[];
    if (template.possessionHintEnabled) {
      hints.add(
        RuleHint(
          type: RuleHintType.possessionChange,
          message: '${scoringSide == TeamSide.red ? '蓝方' : '红方'}球权',
        ),
      );
    }
    final targetScore = template.targetScore;
    if (targetScore == null) {
      return hints;
    }

    final newRed =
        score.redScore + (scoringSide == TeamSide.red ? scoringPoints : 0);
    final newBlue =
        score.blueScore + (scoringSide == TeamSide.blue ? scoringPoints : 0);
    final sideScore = scoringSide == TeamSide.red ? newRed : newBlue;
    final opponentScore = scoringSide == TeamSide.red ? newBlue : newRed;
    if (sideScore >= targetScore) {
      if (template.winByTwo && sideScore - opponentScore < 2) {
        return [
          ...hints,
          const RuleHint(
            type: RuleHintType.winByTwoRequired,
            message: 'Win by two required',
          ),
        ];
      }

      return [
        ...hints,
        const RuleHint(
          type: RuleHintType.targetReached,
          message: 'Target score reached',
        ),
      ];
    }

    if (sideScore == targetScore - 1) {
      hints.add(
        const RuleHint(type: RuleHintType.matchPoint, message: 'Match point'),
      );
    }

    return hints;
  }
}
