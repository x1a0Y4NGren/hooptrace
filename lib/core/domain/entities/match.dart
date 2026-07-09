import 'package:hooptrace/core/domain/entities/rule_template.dart';

enum MatchStatus { draft, active, finished, archived }

class Match {
  const Match({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.redName,
    required this.blueName,
    required this.ruleTemplateSnapshot,
    this.startedAt,
    this.endedAt,
    this.timerEnabled = false,
    this.note,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final MatchStatus status;
  final String redName;
  final String blueName;
  final RuleTemplate ruleTemplateSnapshot;
  final bool timerEnabled;
  final String? note;
}
