import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class MatchRepository {
  MatchRepository(this._database);

  final AppDatabase _database;

  Future<void> createMinimalMatch({
    required String id,
    required String redName,
    required String blueName,
    required DateTime createdAt,
  }) {
    return _database.into(_database.matches).insert(
          MatchesCompanion.insert(
            id: id,
            redName: redName,
            blueName: blueName,
            status: 'active',
            ruleTemplateJson: jsonEncode({
              'id': 'free',
              'name': 'Free scoring',
              'scoreButtons': [1, 2, 3],
            }),
            createdAt: createdAt,
          ),
        );
  }

  Future<void> addEvent(MatchEvent event) {
    return _database.into(_database.matchEvents).insert(
          MatchEventsCompanion.insert(
            id: event.id,
            matchId: event.matchId,
            type: event.type.name,
            side: Value(event.side?.name),
            points: Value(event.points),
            occurredAt: event.occurredAt,
            note: Value(event.note),
            customEventType: Value(event.customType),
            isDeleted: Value(event.isDeleted),
          ),
        );
  }

  Stream<List<MatchEvent>> watchEvents(String matchId) {
    final query = _database.select(_database.matchEvents)
      ..where((event) => event.matchId.equals(matchId))
      ..orderBy([(event) => OrderingTerm.asc(event.occurredAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return MatchEvent(
          id: row.id,
          matchId: row.matchId,
          type: MatchEventType.values.byName(row.type),
          side: row.side == null ? null : TeamSide.values.byName(row.side!),
          points: row.points,
          occurredAt: row.occurredAt,
          note: row.note,
          customType: row.customEventType,
          isDeleted: row.isDeleted,
        );
      }).toList();
    });
  }
}
