// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HoopTrace';

  @override
  String get startScoring => 'Start';

  @override
  String get replayHistory => 'Replay History';

  @override
  String get settings => 'Settings';

  @override
  String get projectDetails => 'Project';

  @override
  String get ruleTargetReached =>
      'Target score reached. Confirm finish or continue.';

  @override
  String get ruleWinByTwoRequired =>
      'Target reached, but a two-point lead is required. Continue?';

  @override
  String get ruleMatchPoint => 'Match point';

  @override
  String get rulePossessionSuggested => 'Possession suggested';

  @override
  String ruleFoulLimit(Object limit, Object side) {
    return '$side foul limit reached ($limit).';
  }

  @override
  String get finishOrContinueOvertime =>
      'Regulation time expired. Confirm finish or continue in overtime?';

  @override
  String get matchDecisionTitle => 'Match decision';

  @override
  String get continueMatch => 'Continue';

  @override
  String get finishMatch => 'Finish match';

  @override
  String get confirmFinalScoreTitle => 'Confirm final score';

  @override
  String get confirmFinalScoreBody =>
      'Finishing locks this score and closes the live match.';

  @override
  String finalScoreLine(
    Object blueName,
    Object blueScore,
    Object redName,
    Object redScore,
  ) {
    return '$redName $redScore : $blueScore $blueName';
  }

  @override
  String get cancelAction => 'Cancel';

  @override
  String get actionFailedRetry => 'Action failed. Please try again.';
}
