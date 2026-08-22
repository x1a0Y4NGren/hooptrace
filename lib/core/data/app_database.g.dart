// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MatchesTable extends Matches with TableInfo<$MatchesTable, Matche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _redNameMeta = const VerificationMeta(
    'redName',
  );
  @override
  late final GeneratedColumn<String> redName = GeneratedColumn<String>(
    'red_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blueNameMeta = const VerificationMeta(
    'blueName',
  );
  @override
  late final GeneratedColumn<String> blueName = GeneratedColumn<String>(
    'blue_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleTemplateJsonMeta = const VerificationMeta(
    'ruleTemplateJson',
  );
  @override
  late final GeneratedColumn<String> ruleTemplateJson = GeneratedColumn<String>(
    'rule_template_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timerEnabledMeta = const VerificationMeta(
    'timerEnabled',
  );
  @override
  late final GeneratedColumn<bool> timerEnabled = GeneratedColumn<bool>(
    'timer_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("timer_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    redName,
    blueName,
    status,
    ruleTemplateJson,
    createdAt,
    startedAt,
    endedAt,
    timerEnabled,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches';
  @override
  VerificationContext validateIntegrity(
    Insertable<Matche> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('red_name')) {
      context.handle(
        _redNameMeta,
        redName.isAcceptableOrUnknown(data['red_name']!, _redNameMeta),
      );
    } else if (isInserting) {
      context.missing(_redNameMeta);
    }
    if (data.containsKey('blue_name')) {
      context.handle(
        _blueNameMeta,
        blueName.isAcceptableOrUnknown(data['blue_name']!, _blueNameMeta),
      );
    } else if (isInserting) {
      context.missing(_blueNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('rule_template_json')) {
      context.handle(
        _ruleTemplateJsonMeta,
        ruleTemplateJson.isAcceptableOrUnknown(
          data['rule_template_json']!,
          _ruleTemplateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleTemplateJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('timer_enabled')) {
      context.handle(
        _timerEnabledMeta,
        timerEnabled.isAcceptableOrUnknown(
          data['timer_enabled']!,
          _timerEnabledMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Matche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Matche(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      redName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}red_name'],
      )!,
      blueName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blue_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      ruleTemplateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_template_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      timerEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}timer_enabled'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $MatchesTable createAlias(String alias) {
    return $MatchesTable(attachedDatabase, alias);
  }
}

class Matche extends DataClass implements Insertable<Matche> {
  final String id;
  final String redName;
  final String blueName;
  final String status;
  final String ruleTemplateJson;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool timerEnabled;
  final String? note;
  const Matche({
    required this.id,
    required this.redName,
    required this.blueName,
    required this.status,
    required this.ruleTemplateJson,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    required this.timerEnabled,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['red_name'] = Variable<String>(redName);
    map['blue_name'] = Variable<String>(blueName);
    map['status'] = Variable<String>(status);
    map['rule_template_json'] = Variable<String>(ruleTemplateJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['timer_enabled'] = Variable<bool>(timerEnabled);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  MatchesCompanion toCompanion(bool nullToAbsent) {
    return MatchesCompanion(
      id: Value(id),
      redName: Value(redName),
      blueName: Value(blueName),
      status: Value(status),
      ruleTemplateJson: Value(ruleTemplateJson),
      createdAt: Value(createdAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      timerEnabled: Value(timerEnabled),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Matche.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Matche(
      id: serializer.fromJson<String>(json['id']),
      redName: serializer.fromJson<String>(json['redName']),
      blueName: serializer.fromJson<String>(json['blueName']),
      status: serializer.fromJson<String>(json['status']),
      ruleTemplateJson: serializer.fromJson<String>(json['ruleTemplateJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      timerEnabled: serializer.fromJson<bool>(json['timerEnabled']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'redName': serializer.toJson<String>(redName),
      'blueName': serializer.toJson<String>(blueName),
      'status': serializer.toJson<String>(status),
      'ruleTemplateJson': serializer.toJson<String>(ruleTemplateJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'timerEnabled': serializer.toJson<bool>(timerEnabled),
      'note': serializer.toJson<String?>(note),
    };
  }

  Matche copyWith({
    String? id,
    String? redName,
    String? blueName,
    String? status,
    String? ruleTemplateJson,
    DateTime? createdAt,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> endedAt = const Value.absent(),
    bool? timerEnabled,
    Value<String?> note = const Value.absent(),
  }) => Matche(
    id: id ?? this.id,
    redName: redName ?? this.redName,
    blueName: blueName ?? this.blueName,
    status: status ?? this.status,
    ruleTemplateJson: ruleTemplateJson ?? this.ruleTemplateJson,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    timerEnabled: timerEnabled ?? this.timerEnabled,
    note: note.present ? note.value : this.note,
  );
  Matche copyWithCompanion(MatchesCompanion data) {
    return Matche(
      id: data.id.present ? data.id.value : this.id,
      redName: data.redName.present ? data.redName.value : this.redName,
      blueName: data.blueName.present ? data.blueName.value : this.blueName,
      status: data.status.present ? data.status.value : this.status,
      ruleTemplateJson: data.ruleTemplateJson.present
          ? data.ruleTemplateJson.value
          : this.ruleTemplateJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      timerEnabled: data.timerEnabled.present
          ? data.timerEnabled.value
          : this.timerEnabled,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Matche(')
          ..write('id: $id, ')
          ..write('redName: $redName, ')
          ..write('blueName: $blueName, ')
          ..write('status: $status, ')
          ..write('ruleTemplateJson: $ruleTemplateJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('timerEnabled: $timerEnabled, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    redName,
    blueName,
    status,
    ruleTemplateJson,
    createdAt,
    startedAt,
    endedAt,
    timerEnabled,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Matche &&
          other.id == this.id &&
          other.redName == this.redName &&
          other.blueName == this.blueName &&
          other.status == this.status &&
          other.ruleTemplateJson == this.ruleTemplateJson &&
          other.createdAt == this.createdAt &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.timerEnabled == this.timerEnabled &&
          other.note == this.note);
}

class MatchesCompanion extends UpdateCompanion<Matche> {
  final Value<String> id;
  final Value<String> redName;
  final Value<String> blueName;
  final Value<String> status;
  final Value<String> ruleTemplateJson;
  final Value<DateTime> createdAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endedAt;
  final Value<bool> timerEnabled;
  final Value<String?> note;
  final Value<int> rowid;
  const MatchesCompanion({
    this.id = const Value.absent(),
    this.redName = const Value.absent(),
    this.blueName = const Value.absent(),
    this.status = const Value.absent(),
    this.ruleTemplateJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.timerEnabled = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchesCompanion.insert({
    required String id,
    required String redName,
    required String blueName,
    required String status,
    required String ruleTemplateJson,
    required DateTime createdAt,
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.timerEnabled = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       redName = Value(redName),
       blueName = Value(blueName),
       status = Value(status),
       ruleTemplateJson = Value(ruleTemplateJson),
       createdAt = Value(createdAt);
  static Insertable<Matche> custom({
    Expression<String>? id,
    Expression<String>? redName,
    Expression<String>? blueName,
    Expression<String>? status,
    Expression<String>? ruleTemplateJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<bool>? timerEnabled,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (redName != null) 'red_name': redName,
      if (blueName != null) 'blue_name': blueName,
      if (status != null) 'status': status,
      if (ruleTemplateJson != null) 'rule_template_json': ruleTemplateJson,
      if (createdAt != null) 'created_at': createdAt,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (timerEnabled != null) 'timer_enabled': timerEnabled,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchesCompanion copyWith({
    Value<String>? id,
    Value<String>? redName,
    Value<String>? blueName,
    Value<String>? status,
    Value<String>? ruleTemplateJson,
    Value<DateTime>? createdAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? endedAt,
    Value<bool>? timerEnabled,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return MatchesCompanion(
      id: id ?? this.id,
      redName: redName ?? this.redName,
      blueName: blueName ?? this.blueName,
      status: status ?? this.status,
      ruleTemplateJson: ruleTemplateJson ?? this.ruleTemplateJson,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (redName.present) {
      map['red_name'] = Variable<String>(redName.value);
    }
    if (blueName.present) {
      map['blue_name'] = Variable<String>(blueName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (ruleTemplateJson.present) {
      map['rule_template_json'] = Variable<String>(ruleTemplateJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (timerEnabled.present) {
      map['timer_enabled'] = Variable<bool>(timerEnabled.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCompanion(')
          ..write('id: $id, ')
          ..write('redName: $redName, ')
          ..write('blueName: $blueName, ')
          ..write('status: $status, ')
          ..write('ruleTemplateJson: $ruleTemplateJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('timerEnabled: $timerEnabled, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatchEventsTable extends MatchEvents
    with TableInfo<$MatchEventsTable, MatchEventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES matches (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
    'side',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
    'points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customEventTypeMeta = const VerificationMeta(
    'customEventType',
  );
  @override
  late final GeneratedColumn<String> customEventType = GeneratedColumn<String>(
    'custom_event_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    type,
    side,
    points,
    occurredAt,
    note,
    customEventType,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'match_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<MatchEventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('side')) {
      context.handle(
        _sideMeta,
        side.isAcceptableOrUnknown(data['side']!, _sideMeta),
      );
    }
    if (data.containsKey('points')) {
      context.handle(
        _pointsMeta,
        points.isAcceptableOrUnknown(data['points']!, _pointsMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('custom_event_type')) {
      context.handle(
        _customEventTypeMeta,
        customEventType.isAcceptableOrUnknown(
          data['custom_event_type']!,
          _customEventTypeMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MatchEventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MatchEventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      side: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side'],
      ),
      points: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      customEventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_event_type'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $MatchEventsTable createAlias(String alias) {
    return $MatchEventsTable(attachedDatabase, alias);
  }
}

class MatchEventRow extends DataClass implements Insertable<MatchEventRow> {
  final String id;
  final String matchId;
  final String type;
  final String? side;
  final int points;
  final DateTime occurredAt;
  final String? note;
  final String? customEventType;
  final bool isDeleted;
  const MatchEventRow({
    required this.id,
    required this.matchId,
    required this.type,
    this.side,
    required this.points,
    required this.occurredAt,
    this.note,
    this.customEventType,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || side != null) {
      map['side'] = Variable<String>(side);
    }
    map['points'] = Variable<int>(points);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || customEventType != null) {
      map['custom_event_type'] = Variable<String>(customEventType);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  MatchEventsCompanion toCompanion(bool nullToAbsent) {
    return MatchEventsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      type: Value(type),
      side: side == null && nullToAbsent ? const Value.absent() : Value(side),
      points: Value(points),
      occurredAt: Value(occurredAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      customEventType: customEventType == null && nullToAbsent
          ? const Value.absent()
          : Value(customEventType),
      isDeleted: Value(isDeleted),
    );
  }

  factory MatchEventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MatchEventRow(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      type: serializer.fromJson<String>(json['type']),
      side: serializer.fromJson<String?>(json['side']),
      points: serializer.fromJson<int>(json['points']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      note: serializer.fromJson<String?>(json['note']),
      customEventType: serializer.fromJson<String?>(json['customEventType']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'type': serializer.toJson<String>(type),
      'side': serializer.toJson<String?>(side),
      'points': serializer.toJson<int>(points),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'note': serializer.toJson<String?>(note),
      'customEventType': serializer.toJson<String?>(customEventType),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  MatchEventRow copyWith({
    String? id,
    String? matchId,
    String? type,
    Value<String?> side = const Value.absent(),
    int? points,
    DateTime? occurredAt,
    Value<String?> note = const Value.absent(),
    Value<String?> customEventType = const Value.absent(),
    bool? isDeleted,
  }) => MatchEventRow(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    type: type ?? this.type,
    side: side.present ? side.value : this.side,
    points: points ?? this.points,
    occurredAt: occurredAt ?? this.occurredAt,
    note: note.present ? note.value : this.note,
    customEventType: customEventType.present
        ? customEventType.value
        : this.customEventType,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  MatchEventRow copyWithCompanion(MatchEventsCompanion data) {
    return MatchEventRow(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      type: data.type.present ? data.type.value : this.type,
      side: data.side.present ? data.side.value : this.side,
      points: data.points.present ? data.points.value : this.points,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      note: data.note.present ? data.note.value : this.note,
      customEventType: data.customEventType.present
          ? data.customEventType.value
          : this.customEventType,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MatchEventRow(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('type: $type, ')
          ..write('side: $side, ')
          ..write('points: $points, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('customEventType: $customEventType, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchId,
    type,
    side,
    points,
    occurredAt,
    note,
    customEventType,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MatchEventRow &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.type == this.type &&
          other.side == this.side &&
          other.points == this.points &&
          other.occurredAt == this.occurredAt &&
          other.note == this.note &&
          other.customEventType == this.customEventType &&
          other.isDeleted == this.isDeleted);
}

class MatchEventsCompanion extends UpdateCompanion<MatchEventRow> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<String> type;
  final Value<String?> side;
  final Value<int> points;
  final Value<DateTime> occurredAt;
  final Value<String?> note;
  final Value<String?> customEventType;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const MatchEventsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.type = const Value.absent(),
    this.side = const Value.absent(),
    this.points = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.customEventType = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchEventsCompanion.insert({
    required String id,
    required String matchId,
    required String type,
    this.side = const Value.absent(),
    this.points = const Value.absent(),
    required DateTime occurredAt,
    this.note = const Value.absent(),
    this.customEventType = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       matchId = Value(matchId),
       type = Value(type),
       occurredAt = Value(occurredAt);
  static Insertable<MatchEventRow> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<String>? type,
    Expression<String>? side,
    Expression<int>? points,
    Expression<DateTime>? occurredAt,
    Expression<String>? note,
    Expression<String>? customEventType,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (type != null) 'type': type,
      if (side != null) 'side': side,
      if (points != null) 'points': points,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (note != null) 'note': note,
      if (customEventType != null) 'custom_event_type': customEventType,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? matchId,
    Value<String>? type,
    Value<String?>? side,
    Value<int>? points,
    Value<DateTime>? occurredAt,
    Value<String?>? note,
    Value<String?>? customEventType,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return MatchEventsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      type: type ?? this.type,
      side: side ?? this.side,
      points: points ?? this.points,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      customEventType: customEventType ?? this.customEventType,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (customEventType.present) {
      map['custom_event_type'] = Variable<String>(customEventType.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchEventsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('type: $type, ')
          ..write('side: $side, ')
          ..write('points: $points, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('note: $note, ')
          ..write('customEventType: $customEventType, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShotLocationsTable extends ShotLocations
    with TableInfo<$ShotLocationsTable, ShotLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShotLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES matches (id)',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES match_events (id)',
    ),
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isConfirmedMeta = const VerificationMeta(
    'isConfirmed',
  );
  @override
  late final GeneratedColumn<bool> isConfirmed = GeneratedColumn<bool>(
    'is_confirmed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_confirmed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    eventId,
    x,
    y,
    isConfirmed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shot_locations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShotLocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('is_confirmed')) {
      context.handle(
        _isConfirmedMeta,
        isConfirmed.isAcceptableOrUnknown(
          data['is_confirmed']!,
          _isConfirmedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShotLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShotLocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      isConfirmed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_confirmed'],
      )!,
    );
  }

  @override
  $ShotLocationsTable createAlias(String alias) {
    return $ShotLocationsTable(attachedDatabase, alias);
  }
}

class ShotLocation extends DataClass implements Insertable<ShotLocation> {
  final String id;
  final String matchId;
  final String eventId;
  final double x;
  final double y;
  final bool isConfirmed;
  const ShotLocation({
    required this.id,
    required this.matchId,
    required this.eventId,
    required this.x,
    required this.y,
    required this.isConfirmed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['event_id'] = Variable<String>(eventId);
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['is_confirmed'] = Variable<bool>(isConfirmed);
    return map;
  }

  ShotLocationsCompanion toCompanion(bool nullToAbsent) {
    return ShotLocationsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      eventId: Value(eventId),
      x: Value(x),
      y: Value(y),
      isConfirmed: Value(isConfirmed),
    );
  }

  factory ShotLocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShotLocation(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      isConfirmed: serializer.fromJson<bool>(json['isConfirmed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'eventId': serializer.toJson<String>(eventId),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'isConfirmed': serializer.toJson<bool>(isConfirmed),
    };
  }

  ShotLocation copyWith({
    String? id,
    String? matchId,
    String? eventId,
    double? x,
    double? y,
    bool? isConfirmed,
  }) => ShotLocation(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    eventId: eventId ?? this.eventId,
    x: x ?? this.x,
    y: y ?? this.y,
    isConfirmed: isConfirmed ?? this.isConfirmed,
  );
  ShotLocation copyWithCompanion(ShotLocationsCompanion data) {
    return ShotLocation(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      isConfirmed: data.isConfirmed.present
          ? data.isConfirmed.value
          : this.isConfirmed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShotLocation(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('eventId: $eventId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('isConfirmed: $isConfirmed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, matchId, eventId, x, y, isConfirmed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShotLocation &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.eventId == this.eventId &&
          other.x == this.x &&
          other.y == this.y &&
          other.isConfirmed == this.isConfirmed);
}

class ShotLocationsCompanion extends UpdateCompanion<ShotLocation> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<String> eventId;
  final Value<double> x;
  final Value<double> y;
  final Value<bool> isConfirmed;
  final Value<int> rowid;
  const ShotLocationsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.isConfirmed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShotLocationsCompanion.insert({
    required String id,
    required String matchId,
    required String eventId,
    required double x,
    required double y,
    this.isConfirmed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       matchId = Value(matchId),
       eventId = Value(eventId),
       x = Value(x),
       y = Value(y);
  static Insertable<ShotLocation> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<String>? eventId,
    Expression<double>? x,
    Expression<double>? y,
    Expression<bool>? isConfirmed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (eventId != null) 'event_id': eventId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (isConfirmed != null) 'is_confirmed': isConfirmed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShotLocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? matchId,
    Value<String>? eventId,
    Value<double>? x,
    Value<double>? y,
    Value<bool>? isConfirmed,
    Value<int>? rowid,
  }) {
    return ShotLocationsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      eventId: eventId ?? this.eventId,
      x: x ?? this.x,
      y: y ?? this.y,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (isConfirmed.present) {
      map['is_confirmed'] = Variable<bool>(isConfirmed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShotLocationsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('eventId: $eventId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('isConfirmed: $isConfirmed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayersTable extends Players with TableInfo<$PlayersTable, PlayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _preferredSideMeta = const VerificationMeta(
    'preferredSide',
  );
  @override
  late final GeneratedColumn<String> preferredSide = GeneratedColumn<String>(
    'preferred_side',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nickname,
    createdAt,
    preferredSide,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'players';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('preferred_side')) {
      context.handle(
        _preferredSideMeta,
        preferredSide.isAcceptableOrUnknown(
          data['preferred_side']!,
          _preferredSideMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      preferredSide: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_side'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $PlayersTable createAlias(String alias) {
    return $PlayersTable(attachedDatabase, alias);
  }
}

class PlayerRow extends DataClass implements Insertable<PlayerRow> {
  final String id;
  final String nickname;
  final DateTime createdAt;
  final String? preferredSide;
  final String? note;
  const PlayerRow({
    required this.id,
    required this.nickname,
    required this.createdAt,
    this.preferredSide,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nickname'] = Variable<String>(nickname);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || preferredSide != null) {
      map['preferred_side'] = Variable<String>(preferredSide);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  PlayersCompanion toCompanion(bool nullToAbsent) {
    return PlayersCompanion(
      id: Value(id),
      nickname: Value(nickname),
      createdAt: Value(createdAt),
      preferredSide: preferredSide == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredSide),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory PlayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerRow(
      id: serializer.fromJson<String>(json['id']),
      nickname: serializer.fromJson<String>(json['nickname']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      preferredSide: serializer.fromJson<String?>(json['preferredSide']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nickname': serializer.toJson<String>(nickname),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'preferredSide': serializer.toJson<String?>(preferredSide),
      'note': serializer.toJson<String?>(note),
    };
  }

  PlayerRow copyWith({
    String? id,
    String? nickname,
    DateTime? createdAt,
    Value<String?> preferredSide = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => PlayerRow(
    id: id ?? this.id,
    nickname: nickname ?? this.nickname,
    createdAt: createdAt ?? this.createdAt,
    preferredSide: preferredSide.present
        ? preferredSide.value
        : this.preferredSide,
    note: note.present ? note.value : this.note,
  );
  PlayerRow copyWithCompanion(PlayersCompanion data) {
    return PlayerRow(
      id: data.id.present ? data.id.value : this.id,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      preferredSide: data.preferredSide.present
          ? data.preferredSide.value
          : this.preferredSide,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerRow(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('createdAt: $createdAt, ')
          ..write('preferredSide: $preferredSide, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nickname, createdAt, preferredSide, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerRow &&
          other.id == this.id &&
          other.nickname == this.nickname &&
          other.createdAt == this.createdAt &&
          other.preferredSide == this.preferredSide &&
          other.note == this.note);
}

class PlayersCompanion extends UpdateCompanion<PlayerRow> {
  final Value<String> id;
  final Value<String> nickname;
  final Value<DateTime> createdAt;
  final Value<String?> preferredSide;
  final Value<String?> note;
  final Value<int> rowid;
  const PlayersCompanion({
    this.id = const Value.absent(),
    this.nickname = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.preferredSide = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayersCompanion.insert({
    required String id,
    required String nickname,
    required DateTime createdAt,
    this.preferredSide = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nickname = Value(nickname),
       createdAt = Value(createdAt);
  static Insertable<PlayerRow> custom({
    Expression<String>? id,
    Expression<String>? nickname,
    Expression<DateTime>? createdAt,
    Expression<String>? preferredSide,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nickname != null) 'nickname': nickname,
      if (createdAt != null) 'created_at': createdAt,
      if (preferredSide != null) 'preferred_side': preferredSide,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayersCompanion copyWith({
    Value<String>? id,
    Value<String>? nickname,
    Value<DateTime>? createdAt,
    Value<String?>? preferredSide,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return PlayersCompanion(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      createdAt: createdAt ?? this.createdAt,
      preferredSide: preferredSide ?? this.preferredSide,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (preferredSide.present) {
      map['preferred_side'] = Variable<String>(preferredSide.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayersCompanion(')
          ..write('id: $id, ')
          ..write('nickname: $nickname, ')
          ..write('createdAt: $createdAt, ')
          ..write('preferredSide: $preferredSide, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuleTemplatesTable extends RuleTemplates
    with TableInfo<$RuleTemplatesTable, RuleTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreButtonsJsonMeta = const VerificationMeta(
    'scoreButtonsJson',
  );
  @override
  late final GeneratedColumn<String> scoreButtonsJson = GeneratedColumn<String>(
    'score_buttons_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetScoreMeta = const VerificationMeta(
    'targetScore',
  );
  @override
  late final GeneratedColumn<int> targetScore = GeneratedColumn<int>(
    'target_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeLimitSecondsMeta = const VerificationMeta(
    'timeLimitSeconds',
  );
  @override
  late final GeneratedColumn<int> timeLimitSeconds = GeneratedColumn<int>(
    'time_limit_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _winByTwoMeta = const VerificationMeta(
    'winByTwo',
  );
  @override
  late final GeneratedColumn<bool> winByTwo = GeneratedColumn<bool>(
    'win_by_two',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("win_by_two" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _foulLimitMeta = const VerificationMeta(
    'foulLimit',
  );
  @override
  late final GeneratedColumn<int> foulLimit = GeneratedColumn<int>(
    'foul_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customEventTypesJsonMeta =
      const VerificationMeta('customEventTypesJson');
  @override
  late final GeneratedColumn<String> customEventTypesJson =
      GeneratedColumn<String>(
        'custom_event_types_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    scoreButtonsJson,
    targetScore,
    timeLimitSeconds,
    winByTwo,
    foulLimit,
    customEventTypesJson,
    isBuiltIn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('score_buttons_json')) {
      context.handle(
        _scoreButtonsJsonMeta,
        scoreButtonsJson.isAcceptableOrUnknown(
          data['score_buttons_json']!,
          _scoreButtonsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoreButtonsJsonMeta);
    }
    if (data.containsKey('target_score')) {
      context.handle(
        _targetScoreMeta,
        targetScore.isAcceptableOrUnknown(
          data['target_score']!,
          _targetScoreMeta,
        ),
      );
    }
    if (data.containsKey('time_limit_seconds')) {
      context.handle(
        _timeLimitSecondsMeta,
        timeLimitSeconds.isAcceptableOrUnknown(
          data['time_limit_seconds']!,
          _timeLimitSecondsMeta,
        ),
      );
    }
    if (data.containsKey('win_by_two')) {
      context.handle(
        _winByTwoMeta,
        winByTwo.isAcceptableOrUnknown(data['win_by_two']!, _winByTwoMeta),
      );
    }
    if (data.containsKey('foul_limit')) {
      context.handle(
        _foulLimitMeta,
        foulLimit.isAcceptableOrUnknown(data['foul_limit']!, _foulLimitMeta),
      );
    }
    if (data.containsKey('custom_event_types_json')) {
      context.handle(
        _customEventTypesJsonMeta,
        customEventTypesJson.isAcceptableOrUnknown(
          data['custom_event_types_json']!,
          _customEventTypesJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scoreButtonsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}score_buttons_json'],
      )!,
      targetScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_score'],
      ),
      timeLimitSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_limit_seconds'],
      ),
      winByTwo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}win_by_two'],
      )!,
      foulLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}foul_limit'],
      ),
      customEventTypesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_event_types_json'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
    );
  }

  @override
  $RuleTemplatesTable createAlias(String alias) {
    return $RuleTemplatesTable(attachedDatabase, alias);
  }
}

class RuleTemplateRow extends DataClass implements Insertable<RuleTemplateRow> {
  final String id;
  final String name;
  final String scoreButtonsJson;
  final int? targetScore;
  final int? timeLimitSeconds;
  final bool winByTwo;
  final int? foulLimit;
  final String customEventTypesJson;
  final bool isBuiltIn;
  const RuleTemplateRow({
    required this.id,
    required this.name,
    required this.scoreButtonsJson,
    this.targetScore,
    this.timeLimitSeconds,
    required this.winByTwo,
    this.foulLimit,
    required this.customEventTypesJson,
    required this.isBuiltIn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['score_buttons_json'] = Variable<String>(scoreButtonsJson);
    if (!nullToAbsent || targetScore != null) {
      map['target_score'] = Variable<int>(targetScore);
    }
    if (!nullToAbsent || timeLimitSeconds != null) {
      map['time_limit_seconds'] = Variable<int>(timeLimitSeconds);
    }
    map['win_by_two'] = Variable<bool>(winByTwo);
    if (!nullToAbsent || foulLimit != null) {
      map['foul_limit'] = Variable<int>(foulLimit);
    }
    map['custom_event_types_json'] = Variable<String>(customEventTypesJson);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    return map;
  }

  RuleTemplatesCompanion toCompanion(bool nullToAbsent) {
    return RuleTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      scoreButtonsJson: Value(scoreButtonsJson),
      targetScore: targetScore == null && nullToAbsent
          ? const Value.absent()
          : Value(targetScore),
      timeLimitSeconds: timeLimitSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(timeLimitSeconds),
      winByTwo: Value(winByTwo),
      foulLimit: foulLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(foulLimit),
      customEventTypesJson: Value(customEventTypesJson),
      isBuiltIn: Value(isBuiltIn),
    );
  }

  factory RuleTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      scoreButtonsJson: serializer.fromJson<String>(json['scoreButtonsJson']),
      targetScore: serializer.fromJson<int?>(json['targetScore']),
      timeLimitSeconds: serializer.fromJson<int?>(json['timeLimitSeconds']),
      winByTwo: serializer.fromJson<bool>(json['winByTwo']),
      foulLimit: serializer.fromJson<int?>(json['foulLimit']),
      customEventTypesJson: serializer.fromJson<String>(
        json['customEventTypesJson'],
      ),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'scoreButtonsJson': serializer.toJson<String>(scoreButtonsJson),
      'targetScore': serializer.toJson<int?>(targetScore),
      'timeLimitSeconds': serializer.toJson<int?>(timeLimitSeconds),
      'winByTwo': serializer.toJson<bool>(winByTwo),
      'foulLimit': serializer.toJson<int?>(foulLimit),
      'customEventTypesJson': serializer.toJson<String>(customEventTypesJson),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
    };
  }

  RuleTemplateRow copyWith({
    String? id,
    String? name,
    String? scoreButtonsJson,
    Value<int?> targetScore = const Value.absent(),
    Value<int?> timeLimitSeconds = const Value.absent(),
    bool? winByTwo,
    Value<int?> foulLimit = const Value.absent(),
    String? customEventTypesJson,
    bool? isBuiltIn,
  }) => RuleTemplateRow(
    id: id ?? this.id,
    name: name ?? this.name,
    scoreButtonsJson: scoreButtonsJson ?? this.scoreButtonsJson,
    targetScore: targetScore.present ? targetScore.value : this.targetScore,
    timeLimitSeconds: timeLimitSeconds.present
        ? timeLimitSeconds.value
        : this.timeLimitSeconds,
    winByTwo: winByTwo ?? this.winByTwo,
    foulLimit: foulLimit.present ? foulLimit.value : this.foulLimit,
    customEventTypesJson: customEventTypesJson ?? this.customEventTypesJson,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
  );
  RuleTemplateRow copyWithCompanion(RuleTemplatesCompanion data) {
    return RuleTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      scoreButtonsJson: data.scoreButtonsJson.present
          ? data.scoreButtonsJson.value
          : this.scoreButtonsJson,
      targetScore: data.targetScore.present
          ? data.targetScore.value
          : this.targetScore,
      timeLimitSeconds: data.timeLimitSeconds.present
          ? data.timeLimitSeconds.value
          : this.timeLimitSeconds,
      winByTwo: data.winByTwo.present ? data.winByTwo.value : this.winByTwo,
      foulLimit: data.foulLimit.present ? data.foulLimit.value : this.foulLimit,
      customEventTypesJson: data.customEventTypesJson.present
          ? data.customEventTypesJson.value
          : this.customEventTypesJson,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleTemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scoreButtonsJson: $scoreButtonsJson, ')
          ..write('targetScore: $targetScore, ')
          ..write('timeLimitSeconds: $timeLimitSeconds, ')
          ..write('winByTwo: $winByTwo, ')
          ..write('foulLimit: $foulLimit, ')
          ..write('customEventTypesJson: $customEventTypesJson, ')
          ..write('isBuiltIn: $isBuiltIn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    scoreButtonsJson,
    targetScore,
    timeLimitSeconds,
    winByTwo,
    foulLimit,
    customEventTypesJson,
    isBuiltIn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleTemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.scoreButtonsJson == this.scoreButtonsJson &&
          other.targetScore == this.targetScore &&
          other.timeLimitSeconds == this.timeLimitSeconds &&
          other.winByTwo == this.winByTwo &&
          other.foulLimit == this.foulLimit &&
          other.customEventTypesJson == this.customEventTypesJson &&
          other.isBuiltIn == this.isBuiltIn);
}

class RuleTemplatesCompanion extends UpdateCompanion<RuleTemplateRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> scoreButtonsJson;
  final Value<int?> targetScore;
  final Value<int?> timeLimitSeconds;
  final Value<bool> winByTwo;
  final Value<int?> foulLimit;
  final Value<String> customEventTypesJson;
  final Value<bool> isBuiltIn;
  final Value<int> rowid;
  const RuleTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.scoreButtonsJson = const Value.absent(),
    this.targetScore = const Value.absent(),
    this.timeLimitSeconds = const Value.absent(),
    this.winByTwo = const Value.absent(),
    this.foulLimit = const Value.absent(),
    this.customEventTypesJson = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleTemplatesCompanion.insert({
    required String id,
    required String name,
    required String scoreButtonsJson,
    this.targetScore = const Value.absent(),
    this.timeLimitSeconds = const Value.absent(),
    this.winByTwo = const Value.absent(),
    this.foulLimit = const Value.absent(),
    this.customEventTypesJson = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       scoreButtonsJson = Value(scoreButtonsJson);
  static Insertable<RuleTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? scoreButtonsJson,
    Expression<int>? targetScore,
    Expression<int>? timeLimitSeconds,
    Expression<bool>? winByTwo,
    Expression<int>? foulLimit,
    Expression<String>? customEventTypesJson,
    Expression<bool>? isBuiltIn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (scoreButtonsJson != null) 'score_buttons_json': scoreButtonsJson,
      if (targetScore != null) 'target_score': targetScore,
      if (timeLimitSeconds != null) 'time_limit_seconds': timeLimitSeconds,
      if (winByTwo != null) 'win_by_two': winByTwo,
      if (foulLimit != null) 'foul_limit': foulLimit,
      if (customEventTypesJson != null)
        'custom_event_types_json': customEventTypesJson,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? scoreButtonsJson,
    Value<int?>? targetScore,
    Value<int?>? timeLimitSeconds,
    Value<bool>? winByTwo,
    Value<int?>? foulLimit,
    Value<String>? customEventTypesJson,
    Value<bool>? isBuiltIn,
    Value<int>? rowid,
  }) {
    return RuleTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      scoreButtonsJson: scoreButtonsJson ?? this.scoreButtonsJson,
      targetScore: targetScore ?? this.targetScore,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      winByTwo: winByTwo ?? this.winByTwo,
      foulLimit: foulLimit ?? this.foulLimit,
      customEventTypesJson: customEventTypesJson ?? this.customEventTypesJson,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scoreButtonsJson.present) {
      map['score_buttons_json'] = Variable<String>(scoreButtonsJson.value);
    }
    if (targetScore.present) {
      map['target_score'] = Variable<int>(targetScore.value);
    }
    if (timeLimitSeconds.present) {
      map['time_limit_seconds'] = Variable<int>(timeLimitSeconds.value);
    }
    if (winByTwo.present) {
      map['win_by_two'] = Variable<bool>(winByTwo.value);
    }
    if (foulLimit.present) {
      map['foul_limit'] = Variable<int>(foulLimit.value);
    }
    if (customEventTypesJson.present) {
      map['custom_event_types_json'] = Variable<String>(
        customEventTypesJson.value,
      );
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('scoreButtonsJson: $scoreButtonsJson, ')
          ..write('targetScore: $targetScore, ')
          ..write('timeLimitSeconds: $timeLimitSeconds, ')
          ..write('winByTwo: $winByTwo, ')
          ..write('foulLimit: $foulLimit, ')
          ..write('customEventTypesJson: $customEventTypesJson, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PossessionSegmentsTable extends PossessionSegments
    with TableInfo<$PossessionSegmentsTable, PossessionSegment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PossessionSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES matches (id)',
    ),
  );
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
    'side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtEventIdMeta = const VerificationMeta(
    'startedAtEventId',
  );
  @override
  late final GeneratedColumn<String> startedAtEventId = GeneratedColumn<String>(
    'started_at_event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES match_events (id)',
    ),
  );
  static const VerificationMeta _endedAtEventIdMeta = const VerificationMeta(
    'endedAtEventId',
  );
  @override
  late final GeneratedColumn<String> endedAtEventId = GeneratedColumn<String>(
    'ended_at_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES match_events (id)',
    ),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    side,
    startedAtEventId,
    endedAtEventId,
    reason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'possession_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PossessionSegment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('side')) {
      context.handle(
        _sideMeta,
        side.isAcceptableOrUnknown(data['side']!, _sideMeta),
      );
    } else if (isInserting) {
      context.missing(_sideMeta);
    }
    if (data.containsKey('started_at_event_id')) {
      context.handle(
        _startedAtEventIdMeta,
        startedAtEventId.isAcceptableOrUnknown(
          data['started_at_event_id']!,
          _startedAtEventIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtEventIdMeta);
    }
    if (data.containsKey('ended_at_event_id')) {
      context.handle(
        _endedAtEventIdMeta,
        endedAtEventId.isAcceptableOrUnknown(
          data['ended_at_event_id']!,
          _endedAtEventIdMeta,
        ),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PossessionSegment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PossessionSegment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      side: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side'],
      )!,
      startedAtEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at_event_id'],
      )!,
      endedAtEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ended_at_event_id'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
    );
  }

  @override
  $PossessionSegmentsTable createAlias(String alias) {
    return $PossessionSegmentsTable(attachedDatabase, alias);
  }
}

class PossessionSegment extends DataClass
    implements Insertable<PossessionSegment> {
  final String id;
  final String matchId;
  final String side;
  final String startedAtEventId;
  final String? endedAtEventId;
  final String? reason;
  const PossessionSegment({
    required this.id,
    required this.matchId,
    required this.side,
    required this.startedAtEventId,
    this.endedAtEventId,
    this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['side'] = Variable<String>(side);
    map['started_at_event_id'] = Variable<String>(startedAtEventId);
    if (!nullToAbsent || endedAtEventId != null) {
      map['ended_at_event_id'] = Variable<String>(endedAtEventId);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    return map;
  }

  PossessionSegmentsCompanion toCompanion(bool nullToAbsent) {
    return PossessionSegmentsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      side: Value(side),
      startedAtEventId: Value(startedAtEventId),
      endedAtEventId: endedAtEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtEventId),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
    );
  }

  factory PossessionSegment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PossessionSegment(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      side: serializer.fromJson<String>(json['side']),
      startedAtEventId: serializer.fromJson<String>(json['startedAtEventId']),
      endedAtEventId: serializer.fromJson<String?>(json['endedAtEventId']),
      reason: serializer.fromJson<String?>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'side': serializer.toJson<String>(side),
      'startedAtEventId': serializer.toJson<String>(startedAtEventId),
      'endedAtEventId': serializer.toJson<String?>(endedAtEventId),
      'reason': serializer.toJson<String?>(reason),
    };
  }

  PossessionSegment copyWith({
    String? id,
    String? matchId,
    String? side,
    String? startedAtEventId,
    Value<String?> endedAtEventId = const Value.absent(),
    Value<String?> reason = const Value.absent(),
  }) => PossessionSegment(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    side: side ?? this.side,
    startedAtEventId: startedAtEventId ?? this.startedAtEventId,
    endedAtEventId: endedAtEventId.present
        ? endedAtEventId.value
        : this.endedAtEventId,
    reason: reason.present ? reason.value : this.reason,
  );
  PossessionSegment copyWithCompanion(PossessionSegmentsCompanion data) {
    return PossessionSegment(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      side: data.side.present ? data.side.value : this.side,
      startedAtEventId: data.startedAtEventId.present
          ? data.startedAtEventId.value
          : this.startedAtEventId,
      endedAtEventId: data.endedAtEventId.present
          ? data.endedAtEventId.value
          : this.endedAtEventId,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PossessionSegment(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('side: $side, ')
          ..write('startedAtEventId: $startedAtEventId, ')
          ..write('endedAtEventId: $endedAtEventId, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, matchId, side, startedAtEventId, endedAtEventId, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PossessionSegment &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.side == this.side &&
          other.startedAtEventId == this.startedAtEventId &&
          other.endedAtEventId == this.endedAtEventId &&
          other.reason == this.reason);
}

class PossessionSegmentsCompanion extends UpdateCompanion<PossessionSegment> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<String> side;
  final Value<String> startedAtEventId;
  final Value<String?> endedAtEventId;
  final Value<String?> reason;
  final Value<int> rowid;
  const PossessionSegmentsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.side = const Value.absent(),
    this.startedAtEventId = const Value.absent(),
    this.endedAtEventId = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PossessionSegmentsCompanion.insert({
    required String id,
    required String matchId,
    required String side,
    required String startedAtEventId,
    this.endedAtEventId = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       matchId = Value(matchId),
       side = Value(side),
       startedAtEventId = Value(startedAtEventId);
  static Insertable<PossessionSegment> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<String>? side,
    Expression<String>? startedAtEventId,
    Expression<String>? endedAtEventId,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (side != null) 'side': side,
      if (startedAtEventId != null) 'started_at_event_id': startedAtEventId,
      if (endedAtEventId != null) 'ended_at_event_id': endedAtEventId,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PossessionSegmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? matchId,
    Value<String>? side,
    Value<String>? startedAtEventId,
    Value<String?>? endedAtEventId,
    Value<String?>? reason,
    Value<int>? rowid,
  }) {
    return PossessionSegmentsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      side: side ?? this.side,
      startedAtEventId: startedAtEventId ?? this.startedAtEventId,
      endedAtEventId: endedAtEventId ?? this.endedAtEventId,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (startedAtEventId.present) {
      map['started_at_event_id'] = Variable<String>(startedAtEventId.value);
    }
    if (endedAtEventId.present) {
      map['ended_at_event_id'] = Variable<String>(endedAtEventId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PossessionSegmentsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('side: $side, ')
          ..write('startedAtEventId: $startedAtEventId, ')
          ..write('endedAtEventId: $endedAtEventId, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogsTable extends AuditLogs
    with TableInfo<$AuditLogsTable, AuditLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _matchIdMeta = const VerificationMeta(
    'matchId',
  );
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
    'match_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES matches (id)',
    ),
  );
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<String> targetId = GeneratedColumn<String>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _beforeJsonMeta = const VerificationMeta(
    'beforeJson',
  );
  @override
  late final GeneratedColumn<String> beforeJson = GeneratedColumn<String>(
    'before_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _afterJsonMeta = const VerificationMeta(
    'afterJson',
  );
  @override
  late final GeneratedColumn<String> afterJson = GeneratedColumn<String>(
    'after_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    matchId,
    targetId,
    action,
    beforeJson,
    afterJson,
    reason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(
        _matchIdMeta,
        matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('before_json')) {
      context.handle(
        _beforeJsonMeta,
        beforeJson.isAcceptableOrUnknown(data['before_json']!, _beforeJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_beforeJsonMeta);
    }
    if (data.containsKey('after_json')) {
      context.handle(
        _afterJsonMeta,
        afterJson.isAcceptableOrUnknown(data['after_json']!, _afterJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_afterJsonMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      matchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_id'],
      )!,
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      beforeJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}before_json'],
      )!,
      afterJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}after_json'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AuditLogsTable createAlias(String alias) {
    return $AuditLogsTable(attachedDatabase, alias);
  }
}

class AuditLog extends DataClass implements Insertable<AuditLog> {
  final String id;
  final String matchId;
  final String targetId;
  final String action;
  final String beforeJson;
  final String afterJson;
  final String? reason;
  final DateTime createdAt;
  const AuditLog({
    required this.id,
    required this.matchId,
    required this.targetId,
    required this.action,
    required this.beforeJson,
    required this.afterJson,
    this.reason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['match_id'] = Variable<String>(matchId);
    map['target_id'] = Variable<String>(targetId);
    map['action'] = Variable<String>(action);
    map['before_json'] = Variable<String>(beforeJson);
    map['after_json'] = Variable<String>(afterJson);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuditLogsCompanion toCompanion(bool nullToAbsent) {
    return AuditLogsCompanion(
      id: Value(id),
      matchId: Value(matchId),
      targetId: Value(targetId),
      action: Value(action),
      beforeJson: Value(beforeJson),
      afterJson: Value(afterJson),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      createdAt: Value(createdAt),
    );
  }

  factory AuditLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLog(
      id: serializer.fromJson<String>(json['id']),
      matchId: serializer.fromJson<String>(json['matchId']),
      targetId: serializer.fromJson<String>(json['targetId']),
      action: serializer.fromJson<String>(json['action']),
      beforeJson: serializer.fromJson<String>(json['beforeJson']),
      afterJson: serializer.fromJson<String>(json['afterJson']),
      reason: serializer.fromJson<String?>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'matchId': serializer.toJson<String>(matchId),
      'targetId': serializer.toJson<String>(targetId),
      'action': serializer.toJson<String>(action),
      'beforeJson': serializer.toJson<String>(beforeJson),
      'afterJson': serializer.toJson<String>(afterJson),
      'reason': serializer.toJson<String?>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuditLog copyWith({
    String? id,
    String? matchId,
    String? targetId,
    String? action,
    String? beforeJson,
    String? afterJson,
    Value<String?> reason = const Value.absent(),
    DateTime? createdAt,
  }) => AuditLog(
    id: id ?? this.id,
    matchId: matchId ?? this.matchId,
    targetId: targetId ?? this.targetId,
    action: action ?? this.action,
    beforeJson: beforeJson ?? this.beforeJson,
    afterJson: afterJson ?? this.afterJson,
    reason: reason.present ? reason.value : this.reason,
    createdAt: createdAt ?? this.createdAt,
  );
  AuditLog copyWithCompanion(AuditLogsCompanion data) {
    return AuditLog(
      id: data.id.present ? data.id.value : this.id,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      action: data.action.present ? data.action.value : this.action,
      beforeJson: data.beforeJson.present
          ? data.beforeJson.value
          : this.beforeJson,
      afterJson: data.afterJson.present ? data.afterJson.value : this.afterJson,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLog(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('targetId: $targetId, ')
          ..write('action: $action, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    matchId,
    targetId,
    action,
    beforeJson,
    afterJson,
    reason,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLog &&
          other.id == this.id &&
          other.matchId == this.matchId &&
          other.targetId == this.targetId &&
          other.action == this.action &&
          other.beforeJson == this.beforeJson &&
          other.afterJson == this.afterJson &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt);
}

class AuditLogsCompanion extends UpdateCompanion<AuditLog> {
  final Value<String> id;
  final Value<String> matchId;
  final Value<String> targetId;
  final Value<String> action;
  final Value<String> beforeJson;
  final Value<String> afterJson;
  final Value<String?> reason;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuditLogsCompanion({
    this.id = const Value.absent(),
    this.matchId = const Value.absent(),
    this.targetId = const Value.absent(),
    this.action = const Value.absent(),
    this.beforeJson = const Value.absent(),
    this.afterJson = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogsCompanion.insert({
    required String id,
    required String matchId,
    required String targetId,
    required String action,
    required String beforeJson,
    required String afterJson,
    this.reason = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       matchId = Value(matchId),
       targetId = Value(targetId),
       action = Value(action),
       beforeJson = Value(beforeJson),
       afterJson = Value(afterJson),
       createdAt = Value(createdAt);
  static Insertable<AuditLog> custom({
    Expression<String>? id,
    Expression<String>? matchId,
    Expression<String>? targetId,
    Expression<String>? action,
    Expression<String>? beforeJson,
    Expression<String>? afterJson,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (matchId != null) 'match_id': matchId,
      if (targetId != null) 'target_id': targetId,
      if (action != null) 'action': action,
      if (beforeJson != null) 'before_json': beforeJson,
      if (afterJson != null) 'after_json': afterJson,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? matchId,
    Value<String>? targetId,
    Value<String>? action,
    Value<String>? beforeJson,
    Value<String>? afterJson,
    Value<String?>? reason,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AuditLogsCompanion(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      targetId: targetId ?? this.targetId,
      action: action ?? this.action,
      beforeJson: beforeJson ?? this.beforeJson,
      afterJson: afterJson ?? this.afterJson,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (targetId.present) {
      map['target_id'] = Variable<String>(targetId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (beforeJson.present) {
      map['before_json'] = Variable<String>(beforeJson.value);
    }
    if (afterJson.present) {
      map['after_json'] = Variable<String>(afterJson.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogsCompanion(')
          ..write('id: $id, ')
          ..write('matchId: $matchId, ')
          ..write('targetId: $targetId, ')
          ..write('action: $action, ')
          ..write('beforeJson: $beforeJson, ')
          ..write('afterJson: $afterJson, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  @override
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, valueJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String valueJson;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.valueJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      valueJson: Value(valueJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      valueJson: serializer.fromJson<String>(json['valueJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueJson': serializer.toJson<String>(valueJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? valueJson, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        valueJson: valueJson ?? this.valueJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, valueJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.valueJson == this.valueJson &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> valueJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String valueJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueJson = Value(valueJson),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? valueJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      valueJson: valueJson ?? this.valueJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MatchesTable matches = $MatchesTable(this);
  late final $MatchEventsTable matchEvents = $MatchEventsTable(this);
  late final $ShotLocationsTable shotLocations = $ShotLocationsTable(this);
  late final $PlayersTable players = $PlayersTable(this);
  late final $RuleTemplatesTable ruleTemplates = $RuleTemplatesTable(this);
  late final $PossessionSegmentsTable possessionSegments =
      $PossessionSegmentsTable(this);
  late final $AuditLogsTable auditLogs = $AuditLogsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    matches,
    matchEvents,
    shotLocations,
    players,
    ruleTemplates,
    possessionSegments,
    auditLogs,
    appSettings,
  ];
}

typedef $$MatchesTableCreateCompanionBuilder =
    MatchesCompanion Function({
      required String id,
      required String redName,
      required String blueName,
      required String status,
      required String ruleTemplateJson,
      required DateTime createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<bool> timerEnabled,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$MatchesTableUpdateCompanionBuilder =
    MatchesCompanion Function({
      Value<String> id,
      Value<String> redName,
      Value<String> blueName,
      Value<String> status,
      Value<String> ruleTemplateJson,
      Value<DateTime> createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> endedAt,
      Value<bool> timerEnabled,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$MatchesTableReferences
    extends BaseReferences<_$AppDatabase, $MatchesTable, Matche> {
  $$MatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MatchEventsTable, List<MatchEventRow>>
  _matchEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.matchEvents,
    aliasName: 'matches__id__match_events__match_id',
  );

  $$MatchEventsTableProcessedTableManager get matchEventsRefs {
    final manager = $$MatchEventsTableTableManager(
      $_db,
      $_db.matchEvents,
    ).filter((f) => f.matchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_matchEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShotLocationsTable, List<ShotLocation>>
  _shotLocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shotLocations,
    aliasName: 'matches__id__shot_locations__match_id',
  );

  $$ShotLocationsTableProcessedTableManager get shotLocationsRefs {
    final manager = $$ShotLocationsTableTableManager(
      $_db,
      $_db.shotLocations,
    ).filter((f) => f.matchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotLocationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PossessionSegmentsTable, List<PossessionSegment>>
  _possessionSegmentsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.possessionSegments,
        aliasName: 'matches__id__possession_segments__match_id',
      );

  $$PossessionSegmentsTableProcessedTableManager get possessionSegmentsRefs {
    final manager = $$PossessionSegmentsTableTableManager(
      $_db,
      $_db.possessionSegments,
    ).filter((f) => f.matchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _possessionSegmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AuditLogsTable, List<AuditLog>>
  _auditLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.auditLogs,
    aliasName: 'matches__id__audit_logs__match_id',
  );

  $$AuditLogsTableProcessedTableManager get auditLogsRefs {
    final manager = $$AuditLogsTableTableManager(
      $_db,
      $_db.auditLogs,
    ).filter((f) => f.matchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_auditLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MatchesTableFilterComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get redName => $composableBuilder(
    column: $table.redName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blueName => $composableBuilder(
    column: $table.blueName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleTemplateJson => $composableBuilder(
    column: $table.ruleTemplateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get timerEnabled => $composableBuilder(
    column: $table.timerEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> matchEventsRefs(
    Expression<bool> Function($$MatchEventsTableFilterComposer f) f,
  ) {
    final $$MatchEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableFilterComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shotLocationsRefs(
    Expression<bool> Function($$ShotLocationsTableFilterComposer f) f,
  ) {
    final $$ShotLocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotLocations,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotLocationsTableFilterComposer(
            $db: $db,
            $table: $db.shotLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> possessionSegmentsRefs(
    Expression<bool> Function($$PossessionSegmentsTableFilterComposer f) f,
  ) {
    final $$PossessionSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.possessionSegments,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PossessionSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.possessionSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> auditLogsRefs(
    Expression<bool> Function($$AuditLogsTableFilterComposer f) f,
  ) {
    final $$AuditLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auditLogs,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuditLogsTableFilterComposer(
            $db: $db,
            $table: $db.auditLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get redName => $composableBuilder(
    column: $table.redName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blueName => $composableBuilder(
    column: $table.blueName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleTemplateJson => $composableBuilder(
    column: $table.ruleTemplateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get timerEnabled => $composableBuilder(
    column: $table.timerEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get redName =>
      $composableBuilder(column: $table.redName, builder: (column) => column);

  GeneratedColumn<String> get blueName =>
      $composableBuilder(column: $table.blueName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get ruleTemplateJson => $composableBuilder(
    column: $table.ruleTemplateJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get timerEnabled => $composableBuilder(
    column: $table.timerEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  Expression<T> matchEventsRefs<T extends Object>(
    Expression<T> Function($$MatchEventsTableAnnotationComposer a) f,
  ) {
    final $$MatchEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shotLocationsRefs<T extends Object>(
    Expression<T> Function($$ShotLocationsTableAnnotationComposer a) f,
  ) {
    final $$ShotLocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotLocations,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotLocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.shotLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> possessionSegmentsRefs<T extends Object>(
    Expression<T> Function($$PossessionSegmentsTableAnnotationComposer a) f,
  ) {
    final $$PossessionSegmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.possessionSegments,
          getReferencedColumn: (t) => t.matchId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PossessionSegmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.possessionSegments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> auditLogsRefs<T extends Object>(
    Expression<T> Function($$AuditLogsTableAnnotationComposer a) f,
  ) {
    final $$AuditLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auditLogs,
      getReferencedColumn: (t) => t.matchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuditLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.auditLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchesTable,
          Matche,
          $$MatchesTableFilterComposer,
          $$MatchesTableOrderingComposer,
          $$MatchesTableAnnotationComposer,
          $$MatchesTableCreateCompanionBuilder,
          $$MatchesTableUpdateCompanionBuilder,
          (Matche, $$MatchesTableReferences),
          Matche,
          PrefetchHooks Function({
            bool matchEventsRefs,
            bool shotLocationsRefs,
            bool possessionSegmentsRefs,
            bool auditLogsRefs,
          })
        > {
  $$MatchesTableTableManager(_$AppDatabase db, $MatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> redName = const Value.absent(),
                Value<String> blueName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> ruleTemplateJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> timerEnabled = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchesCompanion(
                id: id,
                redName: redName,
                blueName: blueName,
                status: status,
                ruleTemplateJson: ruleTemplateJson,
                createdAt: createdAt,
                startedAt: startedAt,
                endedAt: endedAt,
                timerEnabled: timerEnabled,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String redName,
                required String blueName,
                required String status,
                required String ruleTemplateJson,
                required DateTime createdAt,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<bool> timerEnabled = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchesCompanion.insert(
                id: id,
                redName: redName,
                blueName: blueName,
                status: status,
                ruleTemplateJson: ruleTemplateJson,
                createdAt: createdAt,
                startedAt: startedAt,
                endedAt: endedAt,
                timerEnabled: timerEnabled,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                matchEventsRefs = false,
                shotLocationsRefs = false,
                possessionSegmentsRefs = false,
                auditLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (matchEventsRefs) db.matchEvents,
                    if (shotLocationsRefs) db.shotLocations,
                    if (possessionSegmentsRefs) db.possessionSegments,
                    if (auditLogsRefs) db.auditLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (matchEventsRefs)
                        await $_getPrefetchedData<
                          Matche,
                          $MatchesTable,
                          MatchEventRow
                        >(
                          currentTable: table,
                          referencedTable: $$MatchesTableReferences
                              ._matchEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).matchEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shotLocationsRefs)
                        await $_getPrefetchedData<
                          Matche,
                          $MatchesTable,
                          ShotLocation
                        >(
                          currentTable: table,
                          referencedTable: $$MatchesTableReferences
                              ._shotLocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).shotLocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (possessionSegmentsRefs)
                        await $_getPrefetchedData<
                          Matche,
                          $MatchesTable,
                          PossessionSegment
                        >(
                          currentTable: table,
                          referencedTable: $$MatchesTableReferences
                              ._possessionSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).possessionSegmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (auditLogsRefs)
                        await $_getPrefetchedData<
                          Matche,
                          $MatchesTable,
                          AuditLog
                        >(
                          currentTable: table,
                          referencedTable: $$MatchesTableReferences
                              ._auditLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).auditLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchesTable,
      Matche,
      $$MatchesTableFilterComposer,
      $$MatchesTableOrderingComposer,
      $$MatchesTableAnnotationComposer,
      $$MatchesTableCreateCompanionBuilder,
      $$MatchesTableUpdateCompanionBuilder,
      (Matche, $$MatchesTableReferences),
      Matche,
      PrefetchHooks Function({
        bool matchEventsRefs,
        bool shotLocationsRefs,
        bool possessionSegmentsRefs,
        bool auditLogsRefs,
      })
    >;
typedef $$MatchEventsTableCreateCompanionBuilder =
    MatchEventsCompanion Function({
      required String id,
      required String matchId,
      required String type,
      Value<String?> side,
      Value<int> points,
      required DateTime occurredAt,
      Value<String?> note,
      Value<String?> customEventType,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$MatchEventsTableUpdateCompanionBuilder =
    MatchEventsCompanion Function({
      Value<String> id,
      Value<String> matchId,
      Value<String> type,
      Value<String?> side,
      Value<int> points,
      Value<DateTime> occurredAt,
      Value<String?> note,
      Value<String?> customEventType,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$MatchEventsTableReferences
    extends BaseReferences<_$AppDatabase, $MatchEventsTable, MatchEventRow> {
  $$MatchEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MatchesTable _matchIdTable(_$AppDatabase db) =>
      db.matches.createAlias('match_events__match_id__matches__id');

  $$MatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<String>('match_id')!;

    final manager = $$MatchesTableTableManager(
      $_db,
      $_db.matches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShotLocationsTable, List<ShotLocation>>
  _shotLocationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shotLocations,
    aliasName: 'match_events__id__shot_locations__event_id',
  );

  $$ShotLocationsTableProcessedTableManager get shotLocationsRefs {
    final manager = $$ShotLocationsTableTableManager(
      $_db,
      $_db.shotLocations,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shotLocationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PossessionSegmentsTable, List<PossessionSegment>>
  _startedPossessionSegmentsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.possessionSegments,
        aliasName: 'match_events__id__possession_segments__started_at_event_id',
      );

  $$PossessionSegmentsTableProcessedTableManager get startedPossessionSegments {
    final manager =
        $$PossessionSegmentsTableTableManager(
          $_db,
          $_db.possessionSegments,
        ).filter(
          (f) => f.startedAtEventId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _startedPossessionSegmentsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PossessionSegmentsTable, List<PossessionSegment>>
  _endedPossessionSegmentsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.possessionSegments,
        aliasName: 'match_events__id__possession_segments__ended_at_event_id',
      );

  $$PossessionSegmentsTableProcessedTableManager get endedPossessionSegments {
    final manager = $$PossessionSegmentsTableTableManager(
      $_db,
      $_db.possessionSegments,
    ).filter((f) => f.endedAtEventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _endedPossessionSegmentsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MatchEventsTableFilterComposer
    extends Composer<_$AppDatabase, $MatchEventsTable> {
  $$MatchEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customEventType => $composableBuilder(
    column: $table.customEventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$MatchesTableFilterComposer get matchId {
    final $$MatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableFilterComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> shotLocationsRefs(
    Expression<bool> Function($$ShotLocationsTableFilterComposer f) f,
  ) {
    final $$ShotLocationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotLocations,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotLocationsTableFilterComposer(
            $db: $db,
            $table: $db.shotLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> startedPossessionSegments(
    Expression<bool> Function($$PossessionSegmentsTableFilterComposer f) f,
  ) {
    final $$PossessionSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.possessionSegments,
      getReferencedColumn: (t) => t.startedAtEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PossessionSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.possessionSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> endedPossessionSegments(
    Expression<bool> Function($$PossessionSegmentsTableFilterComposer f) f,
  ) {
    final $$PossessionSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.possessionSegments,
      getReferencedColumn: (t) => t.endedAtEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PossessionSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.possessionSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MatchEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchEventsTable> {
  $$MatchEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get points => $composableBuilder(
    column: $table.points,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customEventType => $composableBuilder(
    column: $table.customEventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$MatchesTableOrderingComposer get matchId {
    final $$MatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableOrderingComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MatchEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchEventsTable> {
  $$MatchEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<int> get points =>
      $composableBuilder(column: $table.points, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get customEventType => $composableBuilder(
    column: $table.customEventType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$MatchesTableAnnotationComposer get matchId {
    final $$MatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> shotLocationsRefs<T extends Object>(
    Expression<T> Function($$ShotLocationsTableAnnotationComposer a) f,
  ) {
    final $$ShotLocationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shotLocations,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShotLocationsTableAnnotationComposer(
            $db: $db,
            $table: $db.shotLocations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> startedPossessionSegments<T extends Object>(
    Expression<T> Function($$PossessionSegmentsTableAnnotationComposer a) f,
  ) {
    final $$PossessionSegmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.possessionSegments,
          getReferencedColumn: (t) => t.startedAtEventId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PossessionSegmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.possessionSegments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> endedPossessionSegments<T extends Object>(
    Expression<T> Function($$PossessionSegmentsTableAnnotationComposer a) f,
  ) {
    final $$PossessionSegmentsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.possessionSegments,
          getReferencedColumn: (t) => t.endedAtEventId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PossessionSegmentsTableAnnotationComposer(
                $db: $db,
                $table: $db.possessionSegments,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$MatchEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MatchEventsTable,
          MatchEventRow,
          $$MatchEventsTableFilterComposer,
          $$MatchEventsTableOrderingComposer,
          $$MatchEventsTableAnnotationComposer,
          $$MatchEventsTableCreateCompanionBuilder,
          $$MatchEventsTableUpdateCompanionBuilder,
          (MatchEventRow, $$MatchEventsTableReferences),
          MatchEventRow,
          PrefetchHooks Function({
            bool matchId,
            bool shotLocationsRefs,
            bool startedPossessionSegments,
            bool endedPossessionSegments,
          })
        > {
  $$MatchEventsTableTableManager(_$AppDatabase db, $MatchEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> side = const Value.absent(),
                Value<int> points = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> customEventType = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchEventsCompanion(
                id: id,
                matchId: matchId,
                type: type,
                side: side,
                points: points,
                occurredAt: occurredAt,
                note: note,
                customEventType: customEventType,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String matchId,
                required String type,
                Value<String?> side = const Value.absent(),
                Value<int> points = const Value.absent(),
                required DateTime occurredAt,
                Value<String?> note = const Value.absent(),
                Value<String?> customEventType = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MatchEventsCompanion.insert(
                id: id,
                matchId: matchId,
                type: type,
                side: side,
                points: points,
                occurredAt: occurredAt,
                note: note,
                customEventType: customEventType,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MatchEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                matchId = false,
                shotLocationsRefs = false,
                startedPossessionSegments = false,
                endedPossessionSegments = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shotLocationsRefs) db.shotLocations,
                    if (startedPossessionSegments) db.possessionSegments,
                    if (endedPossessionSegments) db.possessionSegments,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (matchId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.matchId,
                                    referencedTable:
                                        $$MatchEventsTableReferences
                                            ._matchIdTable(db),
                                    referencedColumn:
                                        $$MatchEventsTableReferences
                                            ._matchIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shotLocationsRefs)
                        await $_getPrefetchedData<
                          MatchEventRow,
                          $MatchEventsTable,
                          ShotLocation
                        >(
                          currentTable: table,
                          referencedTable: $$MatchEventsTableReferences
                              ._shotLocationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).shotLocationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (startedPossessionSegments)
                        await $_getPrefetchedData<
                          MatchEventRow,
                          $MatchEventsTable,
                          PossessionSegment
                        >(
                          currentTable: table,
                          referencedTable: $$MatchEventsTableReferences
                              ._startedPossessionSegmentsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).startedPossessionSegments,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.startedAtEventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (endedPossessionSegments)
                        await $_getPrefetchedData<
                          MatchEventRow,
                          $MatchEventsTable,
                          PossessionSegment
                        >(
                          currentTable: table,
                          referencedTable: $$MatchEventsTableReferences
                              ._endedPossessionSegmentsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MatchEventsTableReferences(
                                db,
                                table,
                                p0,
                              ).endedPossessionSegments,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.endedAtEventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MatchEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MatchEventsTable,
      MatchEventRow,
      $$MatchEventsTableFilterComposer,
      $$MatchEventsTableOrderingComposer,
      $$MatchEventsTableAnnotationComposer,
      $$MatchEventsTableCreateCompanionBuilder,
      $$MatchEventsTableUpdateCompanionBuilder,
      (MatchEventRow, $$MatchEventsTableReferences),
      MatchEventRow,
      PrefetchHooks Function({
        bool matchId,
        bool shotLocationsRefs,
        bool startedPossessionSegments,
        bool endedPossessionSegments,
      })
    >;
typedef $$ShotLocationsTableCreateCompanionBuilder =
    ShotLocationsCompanion Function({
      required String id,
      required String matchId,
      required String eventId,
      required double x,
      required double y,
      Value<bool> isConfirmed,
      Value<int> rowid,
    });
typedef $$ShotLocationsTableUpdateCompanionBuilder =
    ShotLocationsCompanion Function({
      Value<String> id,
      Value<String> matchId,
      Value<String> eventId,
      Value<double> x,
      Value<double> y,
      Value<bool> isConfirmed,
      Value<int> rowid,
    });

final class $$ShotLocationsTableReferences
    extends BaseReferences<_$AppDatabase, $ShotLocationsTable, ShotLocation> {
  $$ShotLocationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MatchesTable _matchIdTable(_$AppDatabase db) =>
      db.matches.createAlias('shot_locations__match_id__matches__id');

  $$MatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<String>('match_id')!;

    final manager = $$MatchesTableTableManager(
      $_db,
      $_db.matches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MatchEventsTable _eventIdTable(_$AppDatabase db) =>
      db.matchEvents.createAlias('shot_locations__event_id__match_events__id');

  $$MatchEventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$MatchEventsTableTableManager(
      $_db,
      $_db.matchEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShotLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $ShotLocationsTable> {
  $$ShotLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnFilters(column),
  );

  $$MatchesTableFilterComposer get matchId {
    final $$MatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableFilterComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableFilterComposer get eventId {
    final $$MatchEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableFilterComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShotLocationsTable> {
  $$ShotLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => ColumnOrderings(column),
  );

  $$MatchesTableOrderingComposer get matchId {
    final $$MatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableOrderingComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableOrderingComposer get eventId {
    final $$MatchEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableOrderingComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShotLocationsTable> {
  $$ShotLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<bool> get isConfirmed => $composableBuilder(
    column: $table.isConfirmed,
    builder: (column) => column,
  );

  $$MatchesTableAnnotationComposer get matchId {
    final $$MatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableAnnotationComposer get eventId {
    final $$MatchEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShotLocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShotLocationsTable,
          ShotLocation,
          $$ShotLocationsTableFilterComposer,
          $$ShotLocationsTableOrderingComposer,
          $$ShotLocationsTableAnnotationComposer,
          $$ShotLocationsTableCreateCompanionBuilder,
          $$ShotLocationsTableUpdateCompanionBuilder,
          (ShotLocation, $$ShotLocationsTableReferences),
          ShotLocation,
          PrefetchHooks Function({bool matchId, bool eventId})
        > {
  $$ShotLocationsTableTableManager(_$AppDatabase db, $ShotLocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShotLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShotLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShotLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<bool> isConfirmed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotLocationsCompanion(
                id: id,
                matchId: matchId,
                eventId: eventId,
                x: x,
                y: y,
                isConfirmed: isConfirmed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String matchId,
                required String eventId,
                required double x,
                required double y,
                Value<bool> isConfirmed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShotLocationsCompanion.insert(
                id: id,
                matchId: matchId,
                eventId: eventId,
                x: x,
                y: y,
                isConfirmed: isConfirmed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShotLocationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({matchId = false, eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (matchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.matchId,
                                referencedTable: $$ShotLocationsTableReferences
                                    ._matchIdTable(db),
                                referencedColumn: $$ShotLocationsTableReferences
                                    ._matchIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (eventId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.eventId,
                                referencedTable: $$ShotLocationsTableReferences
                                    ._eventIdTable(db),
                                referencedColumn: $$ShotLocationsTableReferences
                                    ._eventIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShotLocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShotLocationsTable,
      ShotLocation,
      $$ShotLocationsTableFilterComposer,
      $$ShotLocationsTableOrderingComposer,
      $$ShotLocationsTableAnnotationComposer,
      $$ShotLocationsTableCreateCompanionBuilder,
      $$ShotLocationsTableUpdateCompanionBuilder,
      (ShotLocation, $$ShotLocationsTableReferences),
      ShotLocation,
      PrefetchHooks Function({bool matchId, bool eventId})
    >;
typedef $$PlayersTableCreateCompanionBuilder =
    PlayersCompanion Function({
      required String id,
      required String nickname,
      required DateTime createdAt,
      Value<String?> preferredSide,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$PlayersTableUpdateCompanionBuilder =
    PlayersCompanion Function({
      Value<String> id,
      Value<String> nickname,
      Value<DateTime> createdAt,
      Value<String?> preferredSide,
      Value<String?> note,
      Value<int> rowid,
    });

class $$PlayersTableFilterComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredSide => $composableBuilder(
    column: $table.preferredSide,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredSide => $composableBuilder(
    column: $table.preferredSide,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayersTable> {
  $$PlayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get preferredSide => $composableBuilder(
    column: $table.preferredSide,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$PlayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayersTable,
          PlayerRow,
          $$PlayersTableFilterComposer,
          $$PlayersTableOrderingComposer,
          $$PlayersTableAnnotationComposer,
          $$PlayersTableCreateCompanionBuilder,
          $$PlayersTableUpdateCompanionBuilder,
          (PlayerRow, BaseReferences<_$AppDatabase, $PlayersTable, PlayerRow>),
          PlayerRow,
          PrefetchHooks Function()
        > {
  $$PlayersTableTableManager(_$AppDatabase db, $PlayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> preferredSide = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion(
                id: id,
                nickname: nickname,
                createdAt: createdAt,
                preferredSide: preferredSide,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nickname,
                required DateTime createdAt,
                Value<String?> preferredSide = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayersCompanion.insert(
                id: id,
                nickname: nickname,
                createdAt: createdAt,
                preferredSide: preferredSide,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayersTable,
      PlayerRow,
      $$PlayersTableFilterComposer,
      $$PlayersTableOrderingComposer,
      $$PlayersTableAnnotationComposer,
      $$PlayersTableCreateCompanionBuilder,
      $$PlayersTableUpdateCompanionBuilder,
      (PlayerRow, BaseReferences<_$AppDatabase, $PlayersTable, PlayerRow>),
      PlayerRow,
      PrefetchHooks Function()
    >;
typedef $$RuleTemplatesTableCreateCompanionBuilder =
    RuleTemplatesCompanion Function({
      required String id,
      required String name,
      required String scoreButtonsJson,
      Value<int?> targetScore,
      Value<int?> timeLimitSeconds,
      Value<bool> winByTwo,
      Value<int?> foulLimit,
      Value<String> customEventTypesJson,
      Value<bool> isBuiltIn,
      Value<int> rowid,
    });
typedef $$RuleTemplatesTableUpdateCompanionBuilder =
    RuleTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> scoreButtonsJson,
      Value<int?> targetScore,
      Value<int?> timeLimitSeconds,
      Value<bool> winByTwo,
      Value<int?> foulLimit,
      Value<String> customEventTypesJson,
      Value<bool> isBuiltIn,
      Value<int> rowid,
    });

class $$RuleTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $RuleTemplatesTable> {
  $$RuleTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoreButtonsJson => $composableBuilder(
    column: $table.scoreButtonsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetScore => $composableBuilder(
    column: $table.targetScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeLimitSeconds => $composableBuilder(
    column: $table.timeLimitSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get winByTwo => $composableBuilder(
    column: $table.winByTwo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foulLimit => $composableBuilder(
    column: $table.foulLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customEventTypesJson => $composableBuilder(
    column: $table.customEventTypesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RuleTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $RuleTemplatesTable> {
  $$RuleTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoreButtonsJson => $composableBuilder(
    column: $table.scoreButtonsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetScore => $composableBuilder(
    column: $table.targetScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeLimitSeconds => $composableBuilder(
    column: $table.timeLimitSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get winByTwo => $composableBuilder(
    column: $table.winByTwo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foulLimit => $composableBuilder(
    column: $table.foulLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customEventTypesJson => $composableBuilder(
    column: $table.customEventTypesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RuleTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuleTemplatesTable> {
  $$RuleTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scoreButtonsJson => $composableBuilder(
    column: $table.scoreButtonsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetScore => $composableBuilder(
    column: $table.targetScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeLimitSeconds => $composableBuilder(
    column: $table.timeLimitSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get winByTwo =>
      $composableBuilder(column: $table.winByTwo, builder: (column) => column);

  GeneratedColumn<int> get foulLimit =>
      $composableBuilder(column: $table.foulLimit, builder: (column) => column);

  GeneratedColumn<String> get customEventTypesJson => $composableBuilder(
    column: $table.customEventTypesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);
}

class $$RuleTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuleTemplatesTable,
          RuleTemplateRow,
          $$RuleTemplatesTableFilterComposer,
          $$RuleTemplatesTableOrderingComposer,
          $$RuleTemplatesTableAnnotationComposer,
          $$RuleTemplatesTableCreateCompanionBuilder,
          $$RuleTemplatesTableUpdateCompanionBuilder,
          (
            RuleTemplateRow,
            BaseReferences<_$AppDatabase, $RuleTemplatesTable, RuleTemplateRow>,
          ),
          RuleTemplateRow,
          PrefetchHooks Function()
        > {
  $$RuleTemplatesTableTableManager(_$AppDatabase db, $RuleTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scoreButtonsJson = const Value.absent(),
                Value<int?> targetScore = const Value.absent(),
                Value<int?> timeLimitSeconds = const Value.absent(),
                Value<bool> winByTwo = const Value.absent(),
                Value<int?> foulLimit = const Value.absent(),
                Value<String> customEventTypesJson = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleTemplatesCompanion(
                id: id,
                name: name,
                scoreButtonsJson: scoreButtonsJson,
                targetScore: targetScore,
                timeLimitSeconds: timeLimitSeconds,
                winByTwo: winByTwo,
                foulLimit: foulLimit,
                customEventTypesJson: customEventTypesJson,
                isBuiltIn: isBuiltIn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String scoreButtonsJson,
                Value<int?> targetScore = const Value.absent(),
                Value<int?> timeLimitSeconds = const Value.absent(),
                Value<bool> winByTwo = const Value.absent(),
                Value<int?> foulLimit = const Value.absent(),
                Value<String> customEventTypesJson = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleTemplatesCompanion.insert(
                id: id,
                name: name,
                scoreButtonsJson: scoreButtonsJson,
                targetScore: targetScore,
                timeLimitSeconds: timeLimitSeconds,
                winByTwo: winByTwo,
                foulLimit: foulLimit,
                customEventTypesJson: customEventTypesJson,
                isBuiltIn: isBuiltIn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuleTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuleTemplatesTable,
      RuleTemplateRow,
      $$RuleTemplatesTableFilterComposer,
      $$RuleTemplatesTableOrderingComposer,
      $$RuleTemplatesTableAnnotationComposer,
      $$RuleTemplatesTableCreateCompanionBuilder,
      $$RuleTemplatesTableUpdateCompanionBuilder,
      (
        RuleTemplateRow,
        BaseReferences<_$AppDatabase, $RuleTemplatesTable, RuleTemplateRow>,
      ),
      RuleTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$PossessionSegmentsTableCreateCompanionBuilder =
    PossessionSegmentsCompanion Function({
      required String id,
      required String matchId,
      required String side,
      required String startedAtEventId,
      Value<String?> endedAtEventId,
      Value<String?> reason,
      Value<int> rowid,
    });
typedef $$PossessionSegmentsTableUpdateCompanionBuilder =
    PossessionSegmentsCompanion Function({
      Value<String> id,
      Value<String> matchId,
      Value<String> side,
      Value<String> startedAtEventId,
      Value<String?> endedAtEventId,
      Value<String?> reason,
      Value<int> rowid,
    });

final class $$PossessionSegmentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PossessionSegmentsTable,
          PossessionSegment
        > {
  $$PossessionSegmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MatchesTable _matchIdTable(_$AppDatabase db) =>
      db.matches.createAlias('possession_segments__match_id__matches__id');

  $$MatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<String>('match_id')!;

    final manager = $$MatchesTableTableManager(
      $_db,
      $_db.matches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MatchEventsTable _startedAtEventIdTable(_$AppDatabase db) =>
      db.matchEvents.createAlias(
        'possession_segments__started_at_event_id__match_events__id',
      );

  $$MatchEventsTableProcessedTableManager get startedAtEventId {
    final $_column = $_itemColumn<String>('started_at_event_id')!;

    final manager = $$MatchEventsTableTableManager(
      $_db,
      $_db.matchEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_startedAtEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MatchEventsTable _endedAtEventIdTable(_$AppDatabase db) => db
      .matchEvents
      .createAlias('possession_segments__ended_at_event_id__match_events__id');

  $$MatchEventsTableProcessedTableManager? get endedAtEventId {
    final $_column = $_itemColumn<String>('ended_at_event_id');
    if ($_column == null) return null;
    final manager = $$MatchEventsTableTableManager(
      $_db,
      $_db.matchEvents,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_endedAtEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PossessionSegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $PossessionSegmentsTable> {
  $$PossessionSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  $$MatchesTableFilterComposer get matchId {
    final $$MatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableFilterComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableFilterComposer get startedAtEventId {
    final $$MatchEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.startedAtEventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableFilterComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableFilterComposer get endedAtEventId {
    final $$MatchEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endedAtEventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableFilterComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PossessionSegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PossessionSegmentsTable> {
  $$PossessionSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  $$MatchesTableOrderingComposer get matchId {
    final $$MatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableOrderingComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableOrderingComposer get startedAtEventId {
    final $$MatchEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.startedAtEventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableOrderingComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableOrderingComposer get endedAtEventId {
    final $$MatchEventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endedAtEventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableOrderingComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PossessionSegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PossessionSegmentsTable> {
  $$PossessionSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  $$MatchesTableAnnotationComposer get matchId {
    final $$MatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableAnnotationComposer get startedAtEventId {
    final $$MatchEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.startedAtEventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MatchEventsTableAnnotationComposer get endedAtEventId {
    final $$MatchEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.endedAtEventId,
      referencedTable: $db.matchEvents,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.matchEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PossessionSegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PossessionSegmentsTable,
          PossessionSegment,
          $$PossessionSegmentsTableFilterComposer,
          $$PossessionSegmentsTableOrderingComposer,
          $$PossessionSegmentsTableAnnotationComposer,
          $$PossessionSegmentsTableCreateCompanionBuilder,
          $$PossessionSegmentsTableUpdateCompanionBuilder,
          (PossessionSegment, $$PossessionSegmentsTableReferences),
          PossessionSegment,
          PrefetchHooks Function({
            bool matchId,
            bool startedAtEventId,
            bool endedAtEventId,
          })
        > {
  $$PossessionSegmentsTableTableManager(
    _$AppDatabase db,
    $PossessionSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PossessionSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PossessionSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PossessionSegmentsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> side = const Value.absent(),
                Value<String> startedAtEventId = const Value.absent(),
                Value<String?> endedAtEventId = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PossessionSegmentsCompanion(
                id: id,
                matchId: matchId,
                side: side,
                startedAtEventId: startedAtEventId,
                endedAtEventId: endedAtEventId,
                reason: reason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String matchId,
                required String side,
                required String startedAtEventId,
                Value<String?> endedAtEventId = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PossessionSegmentsCompanion.insert(
                id: id,
                matchId: matchId,
                side: side,
                startedAtEventId: startedAtEventId,
                endedAtEventId: endedAtEventId,
                reason: reason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PossessionSegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                matchId = false,
                startedAtEventId = false,
                endedAtEventId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (matchId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.matchId,
                                    referencedTable:
                                        $$PossessionSegmentsTableReferences
                                            ._matchIdTable(db),
                                    referencedColumn:
                                        $$PossessionSegmentsTableReferences
                                            ._matchIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (startedAtEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.startedAtEventId,
                                    referencedTable:
                                        $$PossessionSegmentsTableReferences
                                            ._startedAtEventIdTable(db),
                                    referencedColumn:
                                        $$PossessionSegmentsTableReferences
                                            ._startedAtEventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (endedAtEventId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.endedAtEventId,
                                    referencedTable:
                                        $$PossessionSegmentsTableReferences
                                            ._endedAtEventIdTable(db),
                                    referencedColumn:
                                        $$PossessionSegmentsTableReferences
                                            ._endedAtEventIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PossessionSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PossessionSegmentsTable,
      PossessionSegment,
      $$PossessionSegmentsTableFilterComposer,
      $$PossessionSegmentsTableOrderingComposer,
      $$PossessionSegmentsTableAnnotationComposer,
      $$PossessionSegmentsTableCreateCompanionBuilder,
      $$PossessionSegmentsTableUpdateCompanionBuilder,
      (PossessionSegment, $$PossessionSegmentsTableReferences),
      PossessionSegment,
      PrefetchHooks Function({
        bool matchId,
        bool startedAtEventId,
        bool endedAtEventId,
      })
    >;
typedef $$AuditLogsTableCreateCompanionBuilder =
    AuditLogsCompanion Function({
      required String id,
      required String matchId,
      required String targetId,
      required String action,
      required String beforeJson,
      required String afterJson,
      Value<String?> reason,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AuditLogsTableUpdateCompanionBuilder =
    AuditLogsCompanion Function({
      Value<String> id,
      Value<String> matchId,
      Value<String> targetId,
      Value<String> action,
      Value<String> beforeJson,
      Value<String> afterJson,
      Value<String?> reason,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AuditLogsTableReferences
    extends BaseReferences<_$AppDatabase, $AuditLogsTable, AuditLog> {
  $$AuditLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MatchesTable _matchIdTable(_$AppDatabase db) =>
      db.matches.createAlias('audit_logs__match_id__matches__id');

  $$MatchesTableProcessedTableManager get matchId {
    final $_column = $_itemColumn<String>('match_id')!;

    final manager = $$MatchesTableTableManager(
      $_db,
      $_db.matches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AuditLogsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MatchesTableFilterComposer get matchId {
    final $$MatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableFilterComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuditLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get afterJson => $composableBuilder(
    column: $table.afterJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MatchesTableOrderingComposer get matchId {
    final $$MatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableOrderingComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuditLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogsTable> {
  $$AuditLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get beforeJson => $composableBuilder(
    column: $table.beforeJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get afterJson =>
      $composableBuilder(column: $table.afterJson, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MatchesTableAnnotationComposer get matchId {
    final $$MatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchId,
      referencedTable: $db.matches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.matches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuditLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogsTable,
          AuditLog,
          $$AuditLogsTableFilterComposer,
          $$AuditLogsTableOrderingComposer,
          $$AuditLogsTableAnnotationComposer,
          $$AuditLogsTableCreateCompanionBuilder,
          $$AuditLogsTableUpdateCompanionBuilder,
          (AuditLog, $$AuditLogsTableReferences),
          AuditLog,
          PrefetchHooks Function({bool matchId})
        > {
  $$AuditLogsTableTableManager(_$AppDatabase db, $AuditLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> matchId = const Value.absent(),
                Value<String> targetId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> beforeJson = const Value.absent(),
                Value<String> afterJson = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion(
                id: id,
                matchId: matchId,
                targetId: targetId,
                action: action,
                beforeJson: beforeJson,
                afterJson: afterJson,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String matchId,
                required String targetId,
                required String action,
                required String beforeJson,
                required String afterJson,
                Value<String?> reason = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AuditLogsCompanion.insert(
                id: id,
                matchId: matchId,
                targetId: targetId,
                action: action,
                beforeJson: beforeJson,
                afterJson: afterJson,
                reason: reason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AuditLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({matchId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (matchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.matchId,
                                referencedTable: $$AuditLogsTableReferences
                                    ._matchIdTable(db),
                                referencedColumn: $$AuditLogsTableReferences
                                    ._matchIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AuditLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogsTable,
      AuditLog,
      $$AuditLogsTableFilterComposer,
      $$AuditLogsTableOrderingComposer,
      $$AuditLogsTableAnnotationComposer,
      $$AuditLogsTableCreateCompanionBuilder,
      $$AuditLogsTableUpdateCompanionBuilder,
      (AuditLog, $$AuditLogsTableReferences),
      AuditLog,
      PrefetchHooks Function({bool matchId})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String valueJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> valueJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueJson => $composableBuilder(
    column: $table.valueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueJson =>
      $composableBuilder(column: $table.valueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueJson,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                valueJson: valueJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db, _db.matches);
  $$MatchEventsTableTableManager get matchEvents =>
      $$MatchEventsTableTableManager(_db, _db.matchEvents);
  $$ShotLocationsTableTableManager get shotLocations =>
      $$ShotLocationsTableTableManager(_db, _db.shotLocations);
  $$PlayersTableTableManager get players =>
      $$PlayersTableTableManager(_db, _db.players);
  $$RuleTemplatesTableTableManager get ruleTemplates =>
      $$RuleTemplatesTableTableManager(_db, _db.ruleTemplates);
  $$PossessionSegmentsTableTableManager get possessionSegments =>
      $$PossessionSegmentsTableTableManager(_db, _db.possessionSegments);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db, _db.auditLogs);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
