const defaultRedPlayerName = '红方';
const defaultBluePlayerName = '蓝方';

class MatchSetup {
  const MatchSetup({
    required this.matchId,
    required this.redName,
    required this.blueName,
    required this.ruleTemplateId,
    required this.targetScore,
    required this.timerEnabled,
    required this.timeLimitMinutes,
  });

  final String matchId;
  final String redName;
  final String blueName;
  final String ruleTemplateId;
  final int targetScore;
  final bool timerEnabled;
  final int timeLimitMinutes;
}

class PregameState {
  const PregameState({
    this.redName = defaultRedPlayerName,
    this.blueName = defaultBluePlayerName,
    this.ruleTemplateId = 'free',
    this.timerEnabled = false,
    this.targetScore = 11,
    this.timeLimitMinutes = 10,
    this.advancedExpanded = false,
  });

  final String redName;
  final String blueName;
  final String ruleTemplateId;
  final bool timerEnabled;
  final int targetScore;
  final int timeLimitMinutes;
  final bool advancedExpanded;

  PregameState copyWith({
    String? redName,
    String? blueName,
    String? ruleTemplateId,
    bool? timerEnabled,
    int? targetScore,
    int? timeLimitMinutes,
    bool? advancedExpanded,
  }) {
    return PregameState(
      redName: redName ?? this.redName,
      blueName: blueName ?? this.blueName,
      ruleTemplateId: ruleTemplateId ?? this.ruleTemplateId,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      targetScore: targetScore ?? this.targetScore,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      advancedExpanded: advancedExpanded ?? this.advancedExpanded,
    );
  }
}

class PregameController {
  PregameController({PregameState state = const PregameState()})
      : _state = state;

  PregameState _state;

  PregameState get state => _state;

  void setRedName(String value) {
    _state =
        _state.copyWith(redName: _fallbackName(value, defaultRedPlayerName));
  }

  void setBlueName(String value) {
    _state =
        _state.copyWith(blueName: _fallbackName(value, defaultBluePlayerName));
  }

  void setRuleTemplateId(String value) {
    _state = _state.copyWith(ruleTemplateId: value);
  }

  void setTimerEnabled(bool value) {
    _state = _state.copyWith(timerEnabled: value);
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
    return MatchSetup(
      matchId: 'match-${DateTime.now().microsecondsSinceEpoch}',
      redName: _state.redName,
      blueName: _state.blueName,
      ruleTemplateId: _state.ruleTemplateId,
      targetScore: _state.targetScore,
      timerEnabled: _state.timerEnabled,
      timeLimitMinutes: _state.timeLimitMinutes,
    );
  }

  static String _fallbackName(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
