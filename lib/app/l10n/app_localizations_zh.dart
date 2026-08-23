// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'HoopTrace';

  @override
  String get startScoring => '开始计分';

  @override
  String get replayHistory => '复盘历史';

  @override
  String get settings => '设置';

  @override
  String get projectDetails => '项目详情';

  @override
  String get ruleTargetReached => '已达到目标分数，请确认结束或继续';

  @override
  String get ruleWinByTwoRequired => '已达到目标分数，但还需领先两分，请继续';

  @override
  String get ruleMatchPoint => '赛点';

  @override
  String get rulePossessionSuggested => '球权建议';

  @override
  String ruleFoulLimit(Object limit, Object side) {
    return '$side犯规已达到$limit次';
  }

  @override
  String get finishOrContinueOvertime => '常规时间结束，请确认结束或进入加时';
}
