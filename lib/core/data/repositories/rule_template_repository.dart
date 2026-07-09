import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';

class RuleTemplateRepository {
  RuleTemplateRepository(this._database);

  final AppDatabase _database;

  Future<void> save(RuleTemplate template, {bool isBuiltIn = false}) {
    return _database.into(_database.ruleTemplates).insertOnConflictUpdate(
          RuleTemplatesCompanion.insert(
            id: template.id,
            name: template.name,
            scoreButtonsJson: jsonEncode(template.scoreButtons),
            targetScore: Value(template.targetScore),
            timeLimitSeconds: Value(template.timeLimitSeconds),
            winByTwo: Value(template.winByTwo),
            foulLimit: Value(template.foulLimit),
            customEventTypesJson: Value(jsonEncode(template.customEventTypes)),
            isBuiltIn: Value(isBuiltIn),
          ),
        );
  }

  Stream<List<RuleTemplate>> watchAll() {
    final query = _database.select(_database.ruleTemplates)
      ..orderBy([(template) => OrderingTerm.desc(template.isBuiltIn)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return RuleTemplate(
          id: row.id,
          name: row.name,
          scoreButtons: (jsonDecode(row.scoreButtonsJson) as List<Object?>)
              .cast<num>()
              .map((value) => value.toInt())
              .toList(),
          targetScore: row.targetScore,
          timeLimitSeconds: row.timeLimitSeconds,
          winByTwo: row.winByTwo,
          foulLimit: row.foulLimit,
          customEventTypes:
              (jsonDecode(row.customEventTypesJson) as List<Object?>)
                  .cast<String>(),
        );
      }).toList();
    });
  }
}
