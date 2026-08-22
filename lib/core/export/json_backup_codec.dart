import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:hooptrace/core/audit/audit_log_entry.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/domain/entities/match.dart' as domain_match;
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/core/export/backup_manifest.dart';

sealed class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class BackupFormatException extends BackupException {
  const BackupFormatException(super.message);
}

class BackupChecksumException extends BackupException {
  const BackupChecksumException()
    : super('Backup checksum does not match its payload.');
}

class UnsupportedBackupSchemaException extends BackupException {
  const UnsupportedBackupSchemaException({
    required this.schemaVersion,
    required this.supportedSchemaVersion,
  }) : super(
         'Backup schema $schemaVersion is newer than supported schema '
         '$supportedSchemaVersion.',
       );

  final int schemaVersion;
  final int supportedSchemaVersion;
}

class BackupValidationException extends BackupException {
  const BackupValidationException(super.message);
}

class BackupRestoreException extends BackupException {
  const BackupRestoreException(super.message);
}

class JsonBackupCodec {
  JsonBackupCodec(
    this.database, {
    required this.appVersion,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  static const appName = 'HoopTrace';

  final AppDatabase database;
  final String appVersion;
  final DateTime Function() now;

  Future<String> export() async {
    final tables = <String, List<Map<String, dynamic>>>{
      'matches': await _rows(database.matches),
      'matchParticipants': await _rows(database.matchParticipants),
      'matchClocks': await _rows(database.matchClocks),
      'activeSessions': await _rows(database.activeSessions),
      'matchEvents': await _rows(database.matchEvents),
      'shotLocations': await _rows(database.shotLocations),
      'players': await _rows(database.players),
      'ruleTemplates': await _rows(database.ruleTemplates),
      'possessionSegments': await _rows(database.possessionSegments),
      'auditLogs': await _rows(database.auditLogs),
      'appSettings': await _rows(database.appSettings, key: 'key'),
    };
    final counts = <String, int>{
      for (final entry in tables.entries) entry.key: entry.value.length,
    };
    final sourceManifest = BackupManifest(
      appName: appName,
      appVersion: appVersion,
      schemaVersion: database.schemaVersion,
      exportedAt: now().toUtc(),
      recordCounts: counts,
      checksum: '',
    );
    final checksum = _checksum(sourceManifest, tables);
    final manifest = BackupManifest(
      appName: sourceManifest.appName,
      appVersion: sourceManifest.appVersion,
      schemaVersion: sourceManifest.schemaVersion,
      exportedAt: sourceManifest.exportedAt,
      recordCounts: sourceManifest.recordCounts,
      checksum: checksum,
    );
    return jsonEncode({'manifest': manifest.toJson(), 'data': tables});
  }

  Future<void> restore(String source) async {
    late final BackupManifest manifest;
    late final Map<String, List<Map<String, dynamic>>> data;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) {
        throw const BackupFormatException('Backup root must be an object.');
      }
      final manifestJson = decoded['manifest'];
      final dataJson = decoded['data'];
      if (manifestJson is! Map<String, dynamic> ||
          dataJson is! Map<String, dynamic>) {
        throw const BackupFormatException(
          'Backup must contain manifest and data objects.',
        );
      }
      manifest = BackupManifest.fromJson(manifestJson);
      data = dataJson.map((key, value) => MapEntry(key, _jsonRows(key, value)));
    } on BackupException {
      rethrow;
    } on Object catch (error) {
      throw BackupFormatException('Backup JSON is invalid: $error');
    }
    if (manifest.schemaVersion > database.schemaVersion) {
      throw UnsupportedBackupSchemaException(
        schemaVersion: manifest.schemaVersion,
        supportedSchemaVersion: database.schemaVersion,
      );
    }
    if (manifest.schemaVersion != database.schemaVersion) {
      throw BackupValidationException(
        'Backup schema ${manifest.schemaVersion} is not supported.',
      );
    }
    if (_checksum(manifest, data) != manifest.checksum) {
      throw const BackupChecksumException();
    }

    _validateTableGroups(manifest, data);
    late final List<Matche> matches;
    late final List<MatchParticipant> participants;
    late final List<MatchClock> clocks;
    late final List<ActiveSession> activeSessions;
    late final List<MatchEventRow> events;
    late final List<ShotLocation> locations;
    late final List<PlayerRow> players;
    late final List<RuleTemplateRow> templates;
    late final List<PossessionSegment> possessions;
    late final List<AuditLog> audits;
    late final List<AppSetting> settings;
    try {
      matches = data['matches']!.map(Matche.fromJson).toList();
      participants = data['matchParticipants']!
          .map(MatchParticipant.fromJson)
          .toList();
      clocks = data['matchClocks']!.map(MatchClock.fromJson).toList();
      activeSessions = data['activeSessions']!
          .map(ActiveSession.fromJson)
          .toList();
      events = data['matchEvents']!.map(MatchEventRow.fromJson).toList();
      locations = data['shotLocations']!.map(ShotLocation.fromJson).toList();
      players = data['players']!.map(PlayerRow.fromJson).toList();
      templates = data['ruleTemplates']!.map(RuleTemplateRow.fromJson).toList();
      possessions = data['possessionSegments']!
          .map(PossessionSegment.fromJson)
          .toList();
      audits = data['auditLogs']!.map(AuditLog.fromJson).toList();
      settings = data['appSettings']!.map(AppSetting.fromJson).toList();
    } on Object catch (error) {
      throw BackupValidationException('Backup row is invalid: $error');
    }
    _validateRows(
      matches: matches,
      participants: participants,
      clocks: clocks,
      activeSessions: activeSessions,
      events: events,
      locations: locations,
      players: players,
      templates: templates,
      possessions: possessions,
      audits: audits,
      settings: settings,
    );

    try {
      await database.transaction(() async {
        await database.delete(database.shotLocations).go();
        await database.delete(database.activeSessions).go();
        await database.delete(database.possessionSegments).go();
        await database.delete(database.auditLogs).go();
        await database.delete(database.matchEvents).go();
        await database.delete(database.matchParticipants).go();
        await database.delete(database.matchClocks).go();
        await database.delete(database.matches).go();
        await database.delete(database.players).go();
        await database.delete(database.ruleTemplates).go();
        await database.delete(database.appSettings).go();

        await _insertAll(database.players, players);
        await _insertAll(database.ruleTemplates, templates);
        await _insertAll(database.appSettings, settings);
        await _insertAll(database.matches, matches);
        await _insertAll(database.matchParticipants, participants);
        await _insertAll(database.matchClocks, clocks);
        await _insertAll(database.matchEvents, events);
        await _insertAll(database.shotLocations, locations);
        await _insertAll(database.possessionSegments, possessions);
        await _insertAll(database.auditLogs, audits);
        await _insertAll(database.activeSessions, activeSessions);
      });
    } on Object catch (error) {
      throw BackupRestoreException('Atomic restore failed: $error');
    }
  }

  static List<Map<String, dynamic>> _jsonRows(String table, Object? value) {
    if (value is! List<dynamic>) {
      throw BackupFormatException('$table must be a JSON array.');
    }
    return value
        .map((row) {
          if (row is! Map<String, dynamic>) {
            throw BackupFormatException('$table contains a non-object row.');
          }
          return row;
        })
        .toList(growable: false);
  }

  void _validateTableGroups(
    BackupManifest manifest,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    if (manifest.appName != appName || manifest.appVersion.trim().isEmpty) {
      throw const BackupValidationException(
        'Backup manifest does not identify a supported HoopTrace export.',
      );
    }
    const expected = {
      'matches',
      'matchParticipants',
      'matchClocks',
      'activeSessions',
      'matchEvents',
      'shotLocations',
      'players',
      'ruleTemplates',
      'possessionSegments',
      'auditLogs',
      'appSettings',
    };
    if (data.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(data.keys.toSet()).isNotEmpty) {
      throw const BackupValidationException(
        'Backup must contain exactly the eleven persisted table groups.',
      );
    }
    if (manifest.recordCounts.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(manifest.recordCounts.keys.toSet()).isNotEmpty) {
      throw const BackupValidationException('Manifest counts are incomplete.');
    }
    for (final table in expected) {
      if (manifest.recordCounts[table] != data[table]!.length) {
        throw BackupValidationException(
          'Manifest count for $table does not match its rows.',
        );
      }
    }
  }

  void _validateRows({
    required List<Matche> matches,
    required List<MatchParticipant> participants,
    required List<MatchClock> clocks,
    required List<ActiveSession> activeSessions,
    required List<MatchEventRow> events,
    required List<ShotLocation> locations,
    required List<PlayerRow> players,
    required List<RuleTemplateRow> templates,
    required List<PossessionSegment> possessions,
    required List<AuditLog> audits,
    required List<AppSetting> settings,
  }) {
    final matchIds = _uniqueIds('matches', matches.map((row) => row.id));
    final matchesById = {for (final match in matches) match.id: match};
    _uniqueIds('matchParticipants', participants.map((row) => row.id));
    _uniqueIds('matchClocks', clocks.map((row) => row.id));
    _uniqueIds('activeSessions', activeSessions.map((row) => row.id));
    _uniqueIds('matchEvents', events.map((row) => row.id));
    _uniqueIds('shotLocations', locations.map((row) => row.id));
    _uniqueIds('players', players.map((row) => row.id));
    _uniqueIds('ruleTemplates', templates.map((row) => row.id));
    _uniqueIds('possessionSegments', possessions.map((row) => row.id));
    _uniqueIds('auditLogs', audits.map((row) => row.id));
    _uniqueIds('appSettings', settings.map((row) => row.key));

    if (activeSessions.length > 1 ||
        (activeSessions.isNotEmpty &&
            (activeSessions.single.id != 'active' ||
                !matchIds.contains(activeSessions.single.matchId) ||
                matchesById[activeSessions.single.matchId]?.lifecycle !=
                    domain_match.MatchLifecycle.active.name))) {
      throw const BackupValidationException(
        'Backup contains an invalid active session graph.',
      );
    }

    for (final participant in participants) {
      if (!matchIds.contains(participant.matchId) ||
          !{'red', 'blue'}.contains(participant.side) ||
          participant.nameSnapshot.trim().isEmpty ||
          (participant.playerProfileId != null &&
              !players.any(
                (player) => player.id == participant.playerProfileId,
              ))) {
        throw BackupValidationException(
          'Participant ${participant.id} contains invalid references or values.',
        );
      }
    }
    final participantSides = <String>{};
    for (final participant in participants) {
      if (!participantSides.add('${participant.matchId}:${participant.side}')) {
        throw BackupValidationException(
          'Match ${participant.matchId} contains duplicate participant sides.',
        );
      }
    }
    for (final matchId in matchIds) {
      final sides = participants
          .where((participant) => participant.matchId == matchId)
          .map((participant) => participant.side)
          .toSet();
      if (sides.length != 2 ||
          !sides.contains('red') ||
          !sides.contains('blue')) {
        throw BackupValidationException(
          'Match $matchId must contain exactly one red and one blue participant.',
        );
      }
    }
    for (final match in matches) {
      _validateMatch(match);
    }
    final clocksByMatch = <String, String>{};
    for (final clock in clocks) {
      if (!matchIds.contains(clock.matchId) ||
          !{'countUp', 'countdown'}.contains(clock.mode) ||
          !{
            'regulation',
            'regulationExpired',
            'overtime',
          }.contains(clock.phase) ||
          clock.accumulatedSeconds < 0 ||
          (clock.regulationSeconds != null && clock.regulationSeconds! < 0)) {
        throw BackupValidationException(
          'Clock ${clock.id} contains invalid references or values.',
        );
      }
      if (clocksByMatch.containsKey(clock.matchId)) {
        throw BackupValidationException(
          'Match ${clock.matchId} contains more than one clock.',
        );
      }
      clocksByMatch[clock.matchId] = clock.id;
    }

    for (final event in events) {
      if (!matchIds.contains(event.matchId)) {
        throw BackupValidationException(
          'Event ${event.id} references missing match ${event.matchId}.',
        );
      }
      if (event.type == 'score' && (event.side == null || event.points <= 0)) {
        throw BackupValidationException(
          'Score event ${event.id} has invalid side or points.',
        );
      }
      if (!_enumNames(MatchEventType.values).contains(event.type) ||
          (event.side != null &&
              !_enumNames(TeamSide.values).contains(event.side)) ||
          event.points < 0 ||
          (event.outcome != null &&
              !_enumNames(ShotOutcome.values).contains(event.outcome)) ||
          (event.matchClockPositionSeconds != null &&
              event.matchClockPositionSeconds! < 0) ||
          (event.customLabel != null && event.customLabel!.trim().isEmpty)) {
        throw BackupValidationException(
          'Event ${event.id} contains invalid domain values.',
        );
      }
    }
    final eventsById = {for (final event in events) event.id: event};
    for (final location in locations) {
      final event = eventsById[location.eventId];
      if (!matchIds.contains(location.matchId) ||
          event == null ||
          event.matchId != location.matchId ||
          !{'fieldGoal', 'score', 'miss'}.contains(event.type) ||
          !location.x.isFinite ||
          !location.y.isFinite ||
          location.x < 0 ||
          location.x > 1 ||
          location.y < 0 ||
          location.y > 1) {
        throw BackupValidationException(
          'Shot location ${location.id} has invalid match/event references.',
        );
      }
    }
    for (final player in players) {
      if (player.nickname.trim().isEmpty ||
          (player.preferredSide != null &&
              !_enumNames(TeamSide.values).contains(player.preferredSide))) {
        throw BackupValidationException(
          'Player ${player.id} contains invalid domain values.',
        );
      }
    }
    for (final template in templates) {
      _validateRuleTemplate(template);
    }
    for (final possession in possessions) {
      final start = eventsById[possession.startedAtEventId];
      final end = possession.endedAtEventId == null
          ? null
          : eventsById[possession.endedAtEventId];
      if (!matchIds.contains(possession.matchId) ||
          !_enumNames(TeamSide.values).contains(possession.side) ||
          !_enumNames(PossessionSource.values).contains(possession.source) ||
          start == null ||
          start.matchId != possession.matchId ||
          (possession.endedAtEventId != null &&
              (end == null || end.matchId != possession.matchId))) {
        throw BackupValidationException(
          'Possession ${possession.id} has invalid references.',
        );
      }
    }
    for (final audit in audits) {
      if (!matchIds.contains(audit.matchId) ||
          audit.targetId.trim().isEmpty ||
          !_enumNames(AuditAction.values).contains(audit.action)) {
        throw BackupValidationException(
          'Audit ${audit.id} contains invalid domain values.',
        );
      }
      _decodeJsonObject('Audit ${audit.id} beforeJson', audit.beforeJson);
      _decodeJsonObject('Audit ${audit.id} afterJson', audit.afterJson);
    }
    for (final setting in settings) {
      _decodeJson('App setting ${setting.key}', setting.valueJson);
    }
  }

  void _validateMatch(Matche match) {
    if (!_enumNames(
          domain_match.MatchLifecycle.values,
        ).contains(match.lifecycle) ||
        !_enumNames(
          domain_match.RecordingMode.values,
        ).contains(match.recordingMode) ||
        !_enumNames(
          domain_match.TrackingCoverage.values,
        ).contains(match.trackingCoverage) ||
        (match.startedAt != null &&
            match.startedAt!.isBefore(match.createdAt)) ||
        (match.endedAt != null &&
            match.endedAt!.isBefore(match.startedAt ?? match.createdAt))) {
      throw BackupValidationException(
        'Match ${match.id} contains invalid domain values.',
      );
    }
    final snapshot = _decodeJsonObject(
      'Match ${match.id} rule snapshot',
      match.ruleTemplateJson,
    );
    _validateRuleJson('Match ${match.id} rule snapshot', snapshot);
  }

  void _validateRuleTemplate(RuleTemplateRow template) {
    if (template.name.trim().isEmpty ||
        (template.targetScore != null && template.targetScore! <= 0) ||
        (template.timeLimitSeconds != null &&
            template.timeLimitSeconds! <= 0) ||
        (template.foulLimit != null && template.foulLimit! <= 0)) {
      throw BackupValidationException(
        'Rule template ${template.id} contains invalid values.',
      );
    }
    final scoreButtons = _decodeJson(
      'Rule template ${template.id} score buttons',
      template.scoreButtonsJson,
    );
    if (scoreButtons is! List<dynamic> ||
        scoreButtons.isEmpty ||
        scoreButtons.any((value) => value is! int || value <= 0)) {
      throw BackupValidationException(
        'Rule template ${template.id} has invalid score buttons.',
      );
    }
    final customEventMetadata = _decodeJson(
      'Rule template ${template.id} custom events',
      template.customEventTypesJson,
    );
    final customEvents = switch (customEventMetadata) {
      final List<dynamic> values => values,
      final Map<String, dynamic> metadata => metadata['eventTypes'],
      _ => null,
    };
    final possessionHint = customEventMetadata is Map<String, dynamic>
        ? customEventMetadata['possessionHintEnabled']
        : false;
    if (customEvents is! List<dynamic> ||
        customEvents.any((value) => value is! String || value.trim().isEmpty) ||
        possessionHint is! bool) {
      throw BackupValidationException(
        'Rule template ${template.id} has invalid custom event metadata.',
      );
    }
  }

  void _validateRuleJson(String label, Map<String, dynamic> rule) {
    final scoreButtons = rule['scoreButtons'];
    final customEvents = rule['customEventTypes'];
    final targetScore = rule['targetScore'];
    final timeLimit = rule['timeLimitSeconds'];
    final foulLimit = rule['foulLimit'];
    if (rule['id'] is! String ||
        (rule['id'] as String).trim().isEmpty ||
        rule['name'] is! String ||
        (rule['name'] as String).trim().isEmpty ||
        scoreButtons is! List<dynamic> ||
        scoreButtons.isEmpty ||
        scoreButtons.any((value) => value is! int || value <= 0) ||
        (targetScore != null && (targetScore is! int || targetScore <= 0)) ||
        (timeLimit != null && (timeLimit is! int || timeLimit <= 0)) ||
        rule['winByTwo'] is! bool ||
        (foulLimit != null && (foulLimit is! int || foulLimit <= 0)) ||
        rule['possessionHintEnabled'] is! bool ||
        customEvents is! List<dynamic> ||
        customEvents.any((value) => value is! String || value.trim().isEmpty)) {
      throw BackupValidationException('$label is invalid.');
    }
  }

  Object? _decodeJson(String label, String source) {
    try {
      return jsonDecode(source);
    } on Object catch (error) {
      throw BackupValidationException('$label is not valid JSON: $error');
    }
  }

  Map<String, dynamic> _decodeJsonObject(String label, String source) {
    final decoded = _decodeJson(label, source);
    if (decoded is! Map<String, dynamic>) {
      throw BackupValidationException('$label must be a JSON object.');
    }
    return decoded;
  }

  Set<String> _enumNames(Iterable<Enum> values) {
    return values.map((value) => value.name).toSet();
  }

  Set<String> _uniqueIds(String table, Iterable<String> ids) {
    final result = <String>{};
    for (final id in ids) {
      if (id.isEmpty || !result.add(id)) {
        throw BackupValidationException(
          '$table contains an empty or duplicate primary key.',
        );
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> _rows<T extends DataClass>(
    TableInfo<Table, T> table, {
    String key = 'id',
  }) async {
    final rows = await database.select(table).get();
    final json = rows.map((row) => row.toJson()).toList();
    json.sort(
      (first, second) =>
          (first[key] as String).compareTo(second[key] as String),
    );
    return json;
  }

  Future<void> _insertAll<T extends Object>(
    TableInfo<Table, T> table,
    Iterable<Insertable<T>> rows,
  ) async {
    for (final row in rows) {
      await database.into(table).insert(row);
    }
  }

  String _checksum(
    BackupManifest manifest,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    final encoded = jsonEncode({
      'manifest': manifest.checksumSourceJson(),
      'data': data,
    });
    return sha256.convert(utf8.encode(encoded)).toString();
  }
}
