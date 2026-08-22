import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/audit/audit_diff.dart';
import 'package:hooptrace/core/audit/audit_log_entry.dart';
import 'package:hooptrace/core/domain/entities/match.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/match_history_entry.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/entities/shot_location.dart' as domain;
import 'package:hooptrace/core/domain/scoring/scoring_reducer.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:uuid/uuid.dart';

class MatchRepository {
  MatchRepository(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  Future<void> createMinimalMatch({
    required String id,
    required String redName,
    required String blueName,
    required DateTime createdAt,
  }) {
    return saveMatch(
      Match(
        id: id,
        redName: redName,
        blueName: blueName,
        status: MatchStatus.active,
        ruleTemplateSnapshot: const RuleTemplate(
          id: 'free',
          name: 'Free scoring',
          scoreButtons: [1, 2, 3],
        ),
        createdAt: createdAt,
      ),
    );
  }

  Future<void> saveMatch(Match match) {
    return _database
        .into(_database.matches)
        .insertOnConflictUpdate(
          MatchesCompanion.insert(
            id: match.id,
            redName: match.redName,
            blueName: match.blueName,
            status: match.status.name,
            ruleTemplateJson: jsonEncode(
              _ruleTemplateToJson(match.ruleTemplateSnapshot),
            ),
            createdAt: match.createdAt,
            startedAt: Value(match.startedAt),
            endedAt: Value(match.endedAt),
            timerEnabled: Value(match.timerEnabled),
            note: Value(match.note),
          ),
        );
  }

  Future<void> addEvent(MatchEvent event) => saveEvent(event);

  Future<void> saveEvent(MatchEvent event) {
    return _database
        .into(_database.matchEvents)
        .insertOnConflictUpdate(_eventCompanion(event));
  }

  Future<void> saveShotLocation(domain.ShotLocation location) {
    return _database
        .into(_database.shotLocations)
        .insertOnConflictUpdate(_shotLocationCompanion(location));
  }

  Future<void> saveEventWithShotLocation(
    MatchEvent event, {
    domain.ShotLocation? shotLocation,
  }) {
    if (shotLocation != null &&
        (shotLocation.matchId != event.matchId ||
            shotLocation.eventId != event.id)) {
      throw ArgumentError(
        'Shot location must reference the event and match being saved.',
      );
    }

    return _database.transaction(() async {
      await saveEvent(event);
      if (shotLocation != null) {
        await saveShotLocation(shotLocation);
      }
    });
  }

  Future<void> replaceMatchSnapshot(
    String matchId, {
    required List<MatchEvent> events,
    required List<domain.ShotLocation> shotLocations,
  }) {
    final eventIds = <String>{};
    for (final event in events) {
      if (event.matchId != matchId) {
        throw ArgumentError(
          'Event ${event.id} does not belong to match $matchId.',
        );
      }
      if (!eventIds.add(event.id)) {
        throw ArgumentError('Duplicate event id ${event.id} in snapshot.');
      }
    }

    final locationIds = <String>{};
    for (final location in shotLocations) {
      if (location.matchId != matchId) {
        throw ArgumentError(
          'Shot location ${location.id} does not belong to match $matchId.',
        );
      }
      if (!eventIds.contains(location.eventId)) {
        throw ArgumentError(
          'Shot location ${location.id} references an event outside the '
          'snapshot.',
        );
      }
      if (!locationIds.add(location.id)) {
        throw ArgumentError(
          'Duplicate shot location id ${location.id} in snapshot.',
        );
      }
    }

    return _database.transaction(() async {
      await (_database.delete(
        _database.shotLocations,
      )..where((location) => location.matchId.equals(matchId))).go();
      await (_database.delete(
        _database.matchEvents,
      )..where((event) => event.matchId.equals(matchId))).go();
      for (final event in events) {
        await _database
            .into(_database.matchEvents)
            .insert(_eventCompanion(event));
      }
      for (final location in shotLocations) {
        await _database
            .into(_database.shotLocations)
            .insert(_shotLocationCompanion(location));
      }
    });
  }

  Future<void> finishMatch(String matchId, {required DateTime endedAt}) async {
    final updated =
        await (_database.update(
          _database.matches,
        )..where((match) => match.id.equals(matchId))).write(
          MatchesCompanion(
            status: Value(MatchStatus.finished.name),
            endedAt: Value(endedAt),
          ),
        );
    if (updated == 0) {
      throw StateError('Cannot finish missing match $matchId.');
    }
  }

  Future<void> moveShotLocation({
    required String locationId,
    required CourtPoint point,
    String? reason,
  }) {
    return _database.transaction(() async {
      final query = _database.select(_database.shotLocations)
        ..where((location) => location.id.equals(locationId));
      final before = await query.getSingleOrNull();
      if (before == null) {
        throw StateError('Missing shot location $locationId.');
      }
      if (!before.isConfirmed) {
        throw StateError('Only confirmed shot locations can be moved.');
      }
      await (_database.update(_database.shotLocations)
            ..where((location) => location.id.equals(locationId)))
          .write(ShotLocationsCompanion(x: Value(point.x), y: Value(point.y)));
      await _writeAudit(
        matchId: before.matchId,
        targetId: locationId,
        action: AuditAction.edit,
        before: _locationJson(before),
        after: {..._locationJson(before), ...point.toJson()},
        reason: reason,
      );
    });
  }

  Future<void> softDeleteEvent({required String eventId, String? reason}) {
    return _database.transaction(() async {
      final before = await _eventRow(eventId);
      if (before == null) throw StateError('Missing event $eventId.');
      if (before.isDeleted) return;
      await (_database.update(_database.matchEvents)
            ..where((event) => event.id.equals(eventId)))
          .write(const MatchEventsCompanion(isDeleted: Value(true)));
      await _writeAudit(
        matchId: before.matchId,
        targetId: eventId,
        action: AuditAction.delete,
        before: _eventJson(before),
        after: {..._eventJson(before), 'isDeleted': true},
        reason: reason,
      );
    });
  }

  Future<void> updateEventNote({
    required String eventId,
    required String note,
    String? reason,
  }) {
    return _database.transaction(() async {
      final before = await _eventRow(eventId);
      if (before == null) throw StateError('Missing event $eventId.');
      await (_database.update(_database.matchEvents)
            ..where((event) => event.id.equals(eventId)))
          .write(MatchEventsCompanion(note: Value(note.trim())));
      await _writeAudit(
        matchId: before.matchId,
        targetId: eventId,
        action: AuditAction.edit,
        before: _eventJson(before),
        after: {..._eventJson(before), 'note': note.trim()},
        reason: reason,
      );
    });
  }

  Future<List<AuditLogEntry>> listAuditLogs(String matchId) async {
    final query = _database.select(_database.auditLogs)
      ..where((log) => log.matchId.equals(matchId))
      ..orderBy([
        (log) => OrderingTerm.desc(log.createdAt),
        (_) => OrderingTerm.desc(const CustomExpression<int>('rowid')),
      ]);
    return (await query.get())
        .map(
          (row) => AuditLogEntry(
            id: row.id,
            matchId: row.matchId,
            targetId: row.targetId,
            action: AuditAction.values.byName(row.action),
            createdAt: row.createdAt.toUtc(),
            reason: row.reason,
            diff: AuditDiff(
              before: (jsonDecode(row.beforeJson) as Map)
                  .cast<String, Object?>(),
              after: (jsonDecode(row.afterJson) as Map).cast<String, Object?>(),
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<MatchEventRow?> _eventRow(String eventId) {
    final query = _database.select(_database.matchEvents)
      ..where((event) => event.id.equals(eventId));
    return query.getSingleOrNull();
  }

  Future<void> _writeAudit({
    required String matchId,
    required String targetId,
    required AuditAction action,
    required Map<String, Object?> before,
    required Map<String, Object?> after,
    String? reason,
  }) {
    return _database
        .into(_database.auditLogs)
        .insert(
          AuditLogsCompanion.insert(
            id: _uuid.v4(),
            matchId: matchId,
            targetId: targetId,
            action: action.name,
            beforeJson: jsonEncode(before),
            afterJson: jsonEncode(after),
            reason: Value(_normalizeReason(reason)),
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  static String? _normalizeReason(String? reason) {
    final value = reason?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Map<String, Object?> _eventJson(MatchEventRow row) => {
    'id': row.id,
    'matchId': row.matchId,
    'type': row.type,
    'side': row.side,
    'points': row.points,
    'occurredAt': row.occurredAt.toUtc().toIso8601String(),
    'note': row.note,
    'customEventType': row.customEventType,
    'isDeleted': row.isDeleted,
  };

  static Map<String, Object?> _locationJson(ShotLocation row) => {
    'id': row.id,
    'matchId': row.matchId,
    'eventId': row.eventId,
    'x': row.x,
    'y': row.y,
    'isConfirmed': row.isConfirmed,
  };

  Stream<List<MatchEvent>> watchEvents(String matchId) {
    final query = _database.select(_database.matchEvents)
      ..where((event) => event.matchId.equals(matchId))
      ..orderBy([(event) => OrderingTerm.asc(event.occurredAt)]);

    return query.watch().map((rows) {
      return rows.map(mapEventRow).toList();
    });
  }

  Future<MatchDetail?> getMatchDetail(String matchId) {
    return _database.transaction(() async {
      final matchQuery = _database.select(_database.matches)
        ..where((match) => match.id.equals(matchId));
      final matchRow = await matchQuery.getSingleOrNull();
      if (matchRow == null) {
        return null;
      }

      final eventQuery = _database.select(_database.matchEvents)
        ..where((event) => event.matchId.equals(matchId))
        ..orderBy([(event) => OrderingTerm.asc(event.occurredAt)]);
      final locationQuery = _database.select(_database.shotLocations)
        ..where((location) => location.matchId.equals(matchId));
      final eventRows = await eventQuery.get();
      final locationRows = await locationQuery.get();

      return _buildDetail(matchRow, eventRows, locationRows);
    });
  }

  Future<List<MatchHistoryEntry>> listHistory() async {
    final query = _database.select(_database.matches)
      ..where(
        (match) => match.status.isIn([
          MatchStatus.finished.name,
          MatchStatus.archived.name,
        ]),
      )
      ..orderBy([
        (match) => OrderingTerm.desc(match.startedAt),
        (match) => OrderingTerm.desc(match.createdAt),
      ]);
    final rows = await query.get();
    final entries = <MatchHistoryEntry>[];
    for (final row in rows) {
      final detail = await getMatchDetail(row.id);
      if (detail != null) {
        entries.add(_historyEntry(detail));
      }
    }
    entries.sort((left, right) => right.playedAt.compareTo(left.playedAt));
    return entries;
  }

  Stream<List<MatchHistoryEntry>> watchHistory() {
    final query = _database.select(_database.matches).join([
      leftOuterJoin(
        _database.matchEvents,
        _database.matchEvents.matchId.equalsExp(_database.matches.id),
      ),
      leftOuterJoin(
        _database.shotLocations,
        _database.shotLocations.matchId.equalsExp(_database.matches.id),
      ),
    ]);
    return query.watch().asyncMap((_) => listHistory());
  }

  static MatchEvent mapEventRow(MatchEventRow row) {
    final type = MatchEventType.values.byName(row.type);
    final side = row.side == null ? null : TeamSide.values.byName(row.side!);

    if (type == MatchEventType.score && (side == null || row.points <= 0)) {
      throw StateError(
        'Invalid persisted score event ${row.id}: score events require side '
        'and positive points.',
      );
    }

    return MatchEvent(
      id: row.id,
      matchId: row.matchId,
      type: type,
      side: side,
      points: row.points,
      occurredAt: row.occurredAt.toUtc(),
      note: row.note,
      customType: row.customEventType,
      isDeleted: row.isDeleted,
    );
  }

  static Match mapMatchRow(Matche row) {
    return Match(
      id: row.id,
      createdAt: row.createdAt.toUtc(),
      startedAt: row.startedAt?.toUtc(),
      endedAt: row.endedAt?.toUtc(),
      status: MatchStatus.values.byName(row.status),
      redName: row.redName,
      blueName: row.blueName,
      ruleTemplateSnapshot: _ruleTemplateFromJson(row.ruleTemplateJson),
      timerEnabled: row.timerEnabled,
      note: row.note,
    );
  }

  static MatchEventsCompanion _eventCompanion(MatchEvent event) {
    return MatchEventsCompanion.insert(
      id: event.id,
      matchId: event.matchId,
      type: event.type.name,
      side: Value(event.side?.name),
      points: Value(event.points),
      occurredAt: event.occurredAt,
      note: Value(event.note),
      customEventType: Value(event.customType),
      isDeleted: Value(event.isDeleted),
    );
  }

  static ShotLocationsCompanion _shotLocationCompanion(
    domain.ShotLocation location,
  ) {
    return ShotLocationsCompanion.insert(
      id: location.id,
      matchId: location.matchId,
      eventId: location.eventId,
      x: location.point.x,
      y: location.point.y,
      isConfirmed: Value(location.isConfirmed),
    );
  }

  static domain.ShotLocation _mapShotLocationRow(ShotLocation row) {
    return domain.ShotLocation(
      id: row.id,
      matchId: row.matchId,
      eventId: row.eventId,
      point: CourtPoint(x: row.x, y: row.y),
      isConfirmed: row.isConfirmed,
    );
  }

  static MatchDetail _buildDetail(
    Matche matchRow,
    List<MatchEventRow> eventRows,
    List<ShotLocation> locationRows,
  ) {
    final events = eventRows.map(mapEventRow).toList(growable: false);
    final locations = locationRows
        .map(_mapShotLocationRow)
        .toList(growable: false);
    final activeEvents = events.where((event) => !event.isDeleted).toList();
    final score = ScoringReducer().reduce(activeEvents);
    final shotEventIds = activeEvents
        .where(
          (event) =>
              event.type == MatchEventType.score ||
              event.type == MatchEventType.miss,
        )
        .map((event) => event.id)
        .toSet();
    final locatedEventIds = locations
        .where(
          (location) =>
              location.isConfirmed && shotEventIds.contains(location.eventId),
        )
        .map((location) => location.eventId)
        .toSet();

    return MatchDetail(
      match: mapMatchRow(matchRow),
      events: List.unmodifiable(events),
      shotLocations: List.unmodifiable(locations),
      redScore: score.redScore,
      blueScore: score.blueScore,
      redFouls: _countFouls(activeEvents, TeamSide.red),
      blueFouls: _countFouls(activeEvents, TeamSide.blue),
      shotAttemptCount: shotEventIds.length,
      locatedShotCount: locatedEventIds.length,
    );
  }

  static int _countFouls(List<MatchEvent> events, TeamSide side) {
    return events
        .where(
          (event) => event.type == MatchEventType.foul && event.side == side,
        )
        .length;
  }

  static MatchHistoryEntry _historyEntry(MatchDetail detail) {
    return MatchHistoryEntry(
      id: detail.match.id,
      playedAt: detail.match.startedAt ?? detail.match.createdAt,
      redName: detail.match.redName,
      blueName: detail.match.blueName,
      redScore: detail.redScore,
      blueScore: detail.blueScore,
      winner: detail.winner,
      ruleName: detail.match.ruleTemplateSnapshot.name,
      duration: detail.duration,
      shotAttemptCount: detail.shotAttemptCount,
      locatedShotCount: detail.locatedShotCount,
      shotLocationCompleteness: detail.shotLocationCompleteness,
    );
  }

  static Map<String, Object?> _ruleTemplateToJson(RuleTemplate template) {
    return {
      'id': template.id,
      'name': template.name,
      'scoreButtons': template.scoreButtons,
      'targetScore': template.targetScore,
      'timeLimitSeconds': template.timeLimitSeconds,
      'winByTwo': template.winByTwo,
      'foulLimit': template.foulLimit,
      'possessionHintEnabled': template.possessionHintEnabled,
      'customEventTypes': template.customEventTypes,
    };
  }

  static RuleTemplate _ruleTemplateFromJson(String encoded) {
    final json = (jsonDecode(encoded) as Map).cast<String, Object?>();
    return RuleTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      scoreButtons: (json['scoreButtons'] as List<Object?>)
          .cast<num>()
          .map((value) => value.toInt())
          .toList(growable: false),
      targetScore: (json['targetScore'] as num?)?.toInt(),
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
      winByTwo: json['winByTwo'] as bool? ?? false,
      foulLimit: (json['foulLimit'] as num?)?.toInt(),
      possessionHintEnabled: json['possessionHintEnabled'] as bool? ?? false,
      customEventTypes: (json['customEventTypes'] as List<Object?>? ?? const [])
          .cast<String>(),
    );
  }
}
