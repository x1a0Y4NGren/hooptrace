import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/rules/rule_engine.dart';
import 'package:hooptrace/core/domain/scoring/score_state.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

void main() {
  test('target score creates a non-blocking match point hint', () {
    const template = RuleTemplate(
      id: 'standard-11',
      name: '11 points',
      scoreButtons: [1, 2, 3],
      targetScore: 11,
      winByTwo: true,
    );

    final hints = RuleEngine().evaluate(
      template: template,
      score: const ScoreState(redScore: 10, blueScore: 8),
      scoringSide: TeamSide.red,
      scoringPoints: 1,
    );

    expect(hints.any((hint) => hint.type == RuleHintType.matchPoint), isTrue);
    expect(hints.every((hint) => hint.isBlocking == false), isTrue);
  });
}
