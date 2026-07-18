import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';

void main() {
  test('pre-game state starts with default red and blue players', () {
    final controller = PregameController();

    expect(controller.state.redName, '红方');
    expect(controller.state.blueName, '蓝方');
    expect(controller.state.targetScore, 11);
    expect(controller.state.timerEnabled, isFalse);
  });

  test('pre-game controller creates an in-memory match setup', () {
    final controller = PregameController()
      ..setRedName('A Li')
      ..setBlueName('Bo')
      ..setTargetScore(21)
      ..setTimerEnabled(true)
      ..setWinByTwo(true);

    final setup = controller.createMatchSetup();

    expect(setup.matchId, startsWith('match-'));
    expect(setup.redName, 'A Li');
    expect(setup.blueName, 'Bo');
    expect(setup.targetScore, 21);
    expect(setup.timerEnabled, isTrue);
    expect(setup.winByTwo, isTrue);
  });

  test('timed template keeps a null target score in match setup', () {
    final controller = PregameController(
      templates: RuleTemplateRepository.builtIns,
    )..setRuleTemplateId('timed_ten');

    final setup = controller.createMatchSetup();

    expect(setup.targetScore, isNull);
  });
}
