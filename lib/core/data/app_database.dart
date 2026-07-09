// ignore_for_file: depend_on_referenced_packages

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' show Sqlite3, sqlite3;

part 'app_database.g.dart';

class Matches extends Table {
  TextColumn get id => text()();
  TextColumn get redName => text()();
  TextColumn get blueName => text()();
  TextColumn get status => text()();
  TextColumn get ruleTemplateJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  BoolColumn get timerEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MatchEventRow')
class MatchEvents extends Table {
  TextColumn get id => text()();
  TextColumn get matchId => text().references(Matches, #id)();
  TextColumn get type => text()();
  TextColumn get side => text().nullable()();
  IntColumn get points => integer().withDefault(const Constant(0))();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get customEventType => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ShotLocations extends Table {
  TextColumn get id => text()();
  TextColumn get matchId => text().references(Matches, #id)();
  TextColumn get eventId => text().references(MatchEvents, #id)();
  RealColumn get x => real()();
  RealColumn get y => real()();
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PlayerRow')
class Players extends Table {
  TextColumn get id => text()();
  TextColumn get nickname => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get preferredSide => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RuleTemplateRow')
class RuleTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get scoreButtonsJson => text()();
  IntColumn get targetScore => integer().nullable()();
  IntColumn get timeLimitSeconds => integer().nullable()();
  BoolColumn get winByTwo => boolean().withDefault(const Constant(false))();
  IntColumn get foulLimit => integer().nullable()();
  TextColumn get customEventTypesJson =>
      text().withDefault(const Constant('[]'))();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PossessionSegments extends Table {
  TextColumn get id => text()();
  TextColumn get matchId => text().references(Matches, #id)();
  TextColumn get side => text()();
  @ReferenceName('startedPossessionSegments')
  TextColumn get startedAtEventId => text().references(MatchEvents, #id)();
  @ReferenceName('endedPossessionSegments')
  TextColumn get endedAtEventId =>
      text().nullable().references(MatchEvents, #id)();
  TextColumn get reason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get matchId => text().references(Matches, #id)();
  TextColumn get targetId => text()();
  TextColumn get action => text()();
  TextColumn get beforeJson => text()();
  TextColumn get afterJson => text()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Matches,
    MatchEvents,
    ShotLocations,
    Players,
    RuleTemplates,
    PossessionSegments,
    AuditLogs,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.inMemory() : super(NativeDatabase.memory(sqlite3: _sqlite3));

  @override
  int get schemaVersion => 1;
}

DynamicLibrary _openWindowsSqlite() {
  return DynamicLibrary.open(r'C:\Windows\System32\winsqlite3.dll');
}

Future<Sqlite3> _sqlite3() async {
  if (Platform.isWindows) {
    open.overrideFor(OperatingSystem.windows, _openWindowsSqlite);
  }

  return sqlite3;
}
