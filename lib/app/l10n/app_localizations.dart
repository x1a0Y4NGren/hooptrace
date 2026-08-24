import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'HoopTrace'**
  String get appName;

  /// No description provided for @startScoring.
  ///
  /// In zh, this message translates to:
  /// **'开始计分'**
  String get startScoring;

  /// No description provided for @replayHistory.
  ///
  /// In zh, this message translates to:
  /// **'复盘历史'**
  String get replayHistory;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @projectDetails.
  ///
  /// In zh, this message translates to:
  /// **'项目详情'**
  String get projectDetails;

  /// No description provided for @ruleTargetReached.
  ///
  /// In zh, this message translates to:
  /// **'已达到目标分数，请确认结束或继续'**
  String get ruleTargetReached;

  /// No description provided for @ruleWinByTwoRequired.
  ///
  /// In zh, this message translates to:
  /// **'已达到目标分数，但还需领先两分，请继续'**
  String get ruleWinByTwoRequired;

  /// No description provided for @ruleMatchPoint.
  ///
  /// In zh, this message translates to:
  /// **'赛点'**
  String get ruleMatchPoint;

  /// No description provided for @rulePossessionSuggested.
  ///
  /// In zh, this message translates to:
  /// **'球权建议'**
  String get rulePossessionSuggested;

  /// No description provided for @ruleFoulLimit.
  ///
  /// In zh, this message translates to:
  /// **'{side}犯规已达到{limit}次'**
  String ruleFoulLimit(Object limit, Object side);

  /// No description provided for @finishOrContinueOvertime.
  ///
  /// In zh, this message translates to:
  /// **'常规时间结束，请确认结束或进入加时'**
  String get finishOrContinueOvertime;

  /// No description provided for @matchDecisionTitle.
  ///
  /// In zh, this message translates to:
  /// **'比赛决策'**
  String get matchDecisionTitle;

  /// No description provided for @continueMatch.
  ///
  /// In zh, this message translates to:
  /// **'继续比赛'**
  String get continueMatch;

  /// No description provided for @finishMatch.
  ///
  /// In zh, this message translates to:
  /// **'结束比赛'**
  String get finishMatch;

  /// No description provided for @confirmFinalScoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认最终比分'**
  String get confirmFinalScoreTitle;

  /// No description provided for @confirmFinalScoreBody.
  ///
  /// In zh, this message translates to:
  /// **'结束后将锁定当前比分并关闭进行中的比赛。'**
  String get confirmFinalScoreBody;

  /// No description provided for @finalScoreLine.
  ///
  /// In zh, this message translates to:
  /// **'{redName} {redScore} : {blueScore} {blueName}'**
  String finalScoreLine(
    Object blueName,
    Object blueScore,
    Object redName,
    Object redScore,
  );

  /// No description provided for @cancelAction.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancelAction;

  /// No description provided for @actionFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试。'**
  String get actionFailedRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
