import 'package:hooptrace/core/domain/entities/rule_template.dart';

const defaultRedPlayerName = '红方';
const defaultBluePlayerName = '蓝方';

class MatchSetup {
  const MatchSetup({
    required this.matchId,
    required this.redName,
    required this.blueName,
    required this.ruleTemplateId,
    this.ruleTemplateName,
    required this.targetScore,
    required this.timerEnabled,
    required this.timeLimitMinutes,
    required this.winByTwo,
    this.scoreButtons = const [1, 2, 3],
    this.foulLimit,
    this.possessionHintEnabled = false,
    this.customEventTypes = const [],
  });

  final String matchId;
  final String redName;
  final String blueName;
  final String ruleTemplateId;
  final String? ruleTemplateName;
  final int? targetScore;
  final bool timerEnabled;
  final int timeLimitMinutes;
  final bool winByTwo;
  final List<int> scoreButtons;
  final int? foulLimit;
  final bool possessionHintEnabled;
  final List<String> customEventTypes;
}

class PregameState {
  const PregameState({
    this.redName = defaultRedPlayerName,
    this.blueName = defaultBluePlayerName,
    this.ruleTemplateId = 'free',
    this.timerEnabled = false,
    this.targetScore = 11,
    this.timeLimitMinutes = 10,
    this.winByTwo = false,
    this.advancedExpanded = false,
  });

  final String redName;
  final String blueName;
  final String ruleTemplateId;
  final bool timerEnabled;
  final int targetScore;
  final int timeLimitMinutes;
  final bool winByTwo;
  final bool advancedExpanded;

  PregameState copyWith({
    String? redName,
    String? blueName,
    String? ruleTemplateId,
    bool? timerEnabled,
    int? targetScore,
    int? timeLimitMinutes,
    bool? winByTwo,
    bool? advancedExpanded,
  }) {
    return PregameState(
      redName: redName ?? this.redName,
      blueName: blueName ?? this.blueName,
      ruleTemplateId: ruleTemplateId ?? this.ruleTemplateId,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      targetScore: targetScore ?? this.targetScore,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      winByTwo: winByTwo ?? this.winByTwo,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
    );
  }
}

class PregameController {
  PregameController({
    PregameState state = const PregameState(),
    List<RuleTemplate> templates = const [],
  }) : _state = state,
       _templates = List.of(templates);

  PregameState _state;
  List<RuleTemplate> _templates;

  PregameState get state => _state;

  void setTemplates(List<RuleTemplate> templates) {
    _templates = List.of(templates);
    if (_templates.any((item) => item.id == _state.ruleTemplateId)) return;
    final fallback =
        _templates.where((item) => item.id == 'free').firstOrNull ??
        _templates.firstOrNull;
    if (fallback != null) setRuleTemplateId(fallback.id);
  }

  void setRedName(String value) {
    _state = _state.copyWith(
      redName: _fallbackName(value, defaultRedPlayerName),
    );
  }

  void setBlueName(String value) {
    _state = _state.copyWith(
      blueName: _fallbackName(value, defaultBluePlayerName),
    );
  }

  void setRuleTemplateId(String value) {
    final selected = _templates.where((item) => item.id == value).firstOrNull;
    _state = _state.copyWith(
      ruleTemplateId: value,
      targetScore: selected?.targetScore ?? _state.targetScore,
      timerEnabled: selected?.timeLimitSeconds != null,
      timeLimitMinutes: selected?.timeLimitSeconds == null
          ? _state.timeLimitMinutes
          : selected!.timeLimitSeconds! ~/ 60,
      winByTwo: selected?.winByTwo ?? false,
    );
  }

  void setTimerEnabled(bool value) {
    _state = _state.copyWith(timerEnabled: value);
  }

  void setWinByTwo(bool value) {
    _state = _state.copyWith(winByTwo: value);
  }

  void setTargetScore(int value) {
    _state = _state.copyWith(targetScore: value.clamp(1, 99));
  }

  void setTimeLimitMinutes(int value) {
    _state = _state.copyWith(timeLimitMinutes: value.clamp(1, 180));
  }

  void setAdvancedExpanded(bool value) {
    _state = _state.copyWith(advancedExpanded: value);
  }

  MatchSetup createMatchSetup() {
    final selected = _templates
        .where((item) => item.id == _state.ruleTemplateId)
        .firstOrNull;
    return MatchSetup(
      matchId: 'match-${DateTime.now().microsecondsSinceEpoch}',
      redName: _state.redName,
      blueName: _state.blueName,
      ruleTemplateId: _state.ruleTemplateId,
      ruleTemplateName: selected?.name,
      targetScore: selected == null ? _state.targetScore : selected.targetScore,
      timerEnabled: _state.timerEnabled,
      timeLimitMinutes: _state.timeLimitMinutes,
      winByTwo: _state.winByTwo,
      scoreButtons: selected?.scoreButtons ?? const [1, 2, 3],
      foulLimit: selected?.foulLimit,
      possessionHintEnabled: selected?.possessionHintEnabled ?? false,
      customEventTypes: selected?.customEventTypes ?? const [],
    );
  }

  static String _fallbackName(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
