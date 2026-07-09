class RuleTemplate {
  const RuleTemplate({
    required this.id,
    required this.name,
    required this.scoreButtons,
    this.targetScore,
    this.timeLimitSeconds,
    this.winByTwo = false,
    this.foulLimit,
    this.customEventTypes = const [],
  });

  final String id;
  final String name;
  final List<int> scoreButtons;
  final int? targetScore;
  final int? timeLimitSeconds;
  final bool winByTwo;
  final int? foulLimit;
  final List<String> customEventTypes;
}
