import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
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

  test('profile selection stores the profile id and current name snapshot', () {
    final player = Player(
      id: 'player-red',
      nickname: 'Old Red',
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final controller = PregameController(players: [player]);

    expect(controller.selectRedProfile(player.id), isTrue);

    final setup = controller.createMatchSetup();
    expect(setup.redPlayerProfileId, player.id);
    expect(setup.redName, 'Old Red');
  });

  test('the same profile cannot be selected for both sides', () {
    final player = Player(
      id: 'player-1',
      nickname: 'Player One',
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final controller = PregameController(players: [player]);

    expect(controller.selectRedProfile(player.id), isTrue);
    expect(controller.selectBlueProfile(player.id), isFalse);
    expect(controller.state.bluePlayerProfileId, isNull);
    expect(
      controller.validate().errors,
      isNot(contains(PregameValidationError.duplicatePlayerProfile)),
    );
  });

  test('duplicate temporary names remain valid because sides are explicit', () {
    final controller = PregameController()
      ..setRedName('Alex')
      ..setBlueName('Alex')
      ..setRecordingMode(RecordingMode.simple);

    final result = controller.validate();

    expect(result.isValid, isTrue);
    expect(controller.createMatchSetup().redPlayerProfileId, isNull);
    expect(controller.createMatchSetup().bluePlayerProfileId, isNull);
  });

  test('every match requires an explicit recording mode', () {
    final controller = PregameController();

    expect(
      controller.validate().errors,
      contains(PregameValidationError.recordingModeRequired),
    );

    controller.setRecordingMode(RecordingMode.detailed);
    expect(
      controller.validate().errors,
      isNot(contains(PregameValidationError.recordingModeRequired)),
    );
  });

  test('countdown requires a positive duration within the supported range', () {
    final controller = PregameController(
      state: const PregameState(
        clockMode: ClockMode.countdown,
        timeLimitMinutes: 0,
        recordingMode: RecordingMode.simple,
      ),
    );

    expect(
      controller.validate().errors,
      contains(PregameValidationError.invalidCountdownDuration),
    );

    controller.setTimeLimitMinutes(15);
    expect(
      controller.validate().errors,
      isNot(contains(PregameValidationError.invalidCountdownDuration)),
    );
  });

  test('clock mode and timer enablement remain independent', () {
    final controller = PregameController()
      ..setTimerEnabled(true)
      ..setClockMode(ClockMode.countUp);

    expect(controller.state.clockMode, ClockMode.countUp);
    expect(controller.state.timerEnabled, isTrue);
    final setup = controller.createMatchSetup();
    expect(setup.clockMode, ClockMode.countUp);
    expect(setup.timerEnabled, isTrue);
  });

  test('changing a selected profile to a temporary name clears its id', () {
    final player = Player(
      id: 'player-red',
      nickname: 'Profile Name',
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final controller = PregameController(players: [player]);

    controller.selectRedProfile(player.id);
    controller.setRedName('Temporary Red');

    expect(controller.state.redPlayerProfileId, isNull);
    expect(controller.state.redName, 'Temporary Red');
  });

  test('selected profile snapshot does not follow later profile rename', () {
    final original = Player(
      id: 'player-red',
      nickname: 'Before Rename',
      createdAt: DateTime.utc(2026, 8, 23),
    );
    final controller = PregameController(players: [original])
      ..selectRedProfile(original.id)
      ..setRecordingMode(RecordingMode.simple);

    controller.setPlayers([
      Player(
        id: original.id,
        nickname: 'After Rename',
        createdAt: original.createdAt,
      ),
    ]);

    final setup = controller.createMatchSetup();
    expect(setup.redPlayerProfileId, original.id);
    expect(setup.redName, 'Before Rename');
  });

  test('unknown profile selections are rejected without changing the side', () {
    final controller = PregameController();

    expect(controller.selectRedProfile('missing'), isFalse);
    expect(controller.state.redPlayerProfileId, isNull);
    expect(controller.state.redName, defaultRedPlayerName);
  });
}
