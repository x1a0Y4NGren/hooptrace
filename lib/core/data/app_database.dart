// ignore_for_file: depend_on_referenced_packages

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

/// Raised before Drift can run a migration when a pre-1.0 database is found.
class LegacySchemaDetectedException implements Exception {
  const LegacySchemaDetectedException(this.version);

  final int version;

  @override
  String toString() =>
      'LegacySchemaDetectedException: schema v$version is incompatible with '
      'HoopTrace schema v2; start with a clean database.';
}

class Matches extends Table {
  TextColumn get id => text()();
  TextColumn get lifecycle => text().withDefault(const Constant('draft'))();
  TextColumn get recordingMode =>
      text().withDefault(const Constant('simple'))();
  TextColumn get trackingCoverage =>
      text().withDefault(const Constant('scoresOnly'))();
  TextColumn get ruleTemplateJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  BoolColumn get timerEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (lifecycle IN ('draft', 'active', 'finished', 'archived', 'abandoned'))",
    "CHECK (recording_mode IN ('simple', 'detailed'))",
    "CHECK (tracking_coverage IN ('none', 'scoresOnly', 'shotAttempts', 'locations', 'full'))",
  ];
}

class MatchParticipants extends Table {
  TextColumn get id => text()();
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  TextColumn get side => text()();
  TextColumn get nameSnapshot => text()();
  TextColumn get playerProfileId =>
      text().nullable().references(Players, #id, onDelete: KeyAction.setNull)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (side IN ('red', 'blue'))",
    'CHECK (length(trim(name_snapshot)) > 0)',
  ];
}

class MatchClocks extends Table {
  TextColumn get id => text()();
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  TextColumn get mode => text().withDefault(const Constant('countUp'))();
  TextColumn get phase => text().withDefault(const Constant('regulation'))();
  IntColumn get accumulatedSeconds =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get runningSinceUtc => dateTime().nullable()();
  IntColumn get regulationSeconds => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (mode IN ('countUp', 'countdown'))",
    "CHECK (phase IN ('regulation', 'regulationExpired', 'overtime'))",
    'CHECK (accumulated_seconds >= 0)',
    'CHECK (regulation_seconds IS NULL OR regulation_seconds >= 0)',
  ];
}

class ActiveSessions extends Table {
  TextColumn get id => text().withDefault(const Constant('active'))();
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get claimedAtUtc =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ["CHECK (id = 'active')"];
}

@DataClassName('MatchEventRow')
class MatchEvents extends Table {
  TextColumn get id => text()();
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  TextColumn get side => text().nullable()();
  IntColumn get points => integer().withDefault(const Constant(0))();
  TextColumn get outcome => text().nullable()();
  IntColumn get matchClockPositionSeconds => integer().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get customLabel => text().nullable()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (type IN ('score', 'fieldGoal', 'freeThrow', 'miss', 'foul', 'reward', 'pause', 'interruption', 'note', 'custom', 'possession'))",
    "CHECK (side IS NULL OR side IN ('red', 'blue'))",
    "CHECK (type NOT IN ('score', 'fieldGoal', 'freeThrow') OR side IS NOT NULL)",
    'CHECK (type != \'score\' OR (side IS NOT NULL AND points > 0))',
    "CHECK (type != 'freeThrow' OR (outcome IS NOT NULL AND ((outcome = 'made' AND points > 0) OR (outcome = 'missed' AND points = 0))))",
    "CHECK (type != 'fieldGoal' OR (outcome IS NOT NULL AND ((outcome = 'made' AND points > 0) OR (outcome = 'missed' AND points = 0))))",
    "CHECK (type != 'miss' OR (side IS NOT NULL AND points = 0))",
    'CHECK (outcome IS NULL OR outcome IN (\'made\', \'missed\', \'notApplicable\'))',
    'CHECK (match_clock_position_seconds IS NULL OR match_clock_position_seconds >= 0)',
    'CHECK (points >= 0)',
  ];
}

class ShotLocations extends Table {
  TextColumn get id => text()();
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  TextColumn get eventId =>
      text().references(MatchEvents, #id, onDelete: KeyAction.cascade)();
  RealColumn get x => real()();
  RealColumn get y => real()();
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (x >= 0 AND x <= 1 AND y >= 0 AND y <= 1)',
  ];
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
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
  TextColumn get side => text()();
  @ReferenceName('startedPossessionSegments')
  TextColumn get startedAtEventId =>
      text().references(MatchEvents, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('endedPossessionSegments')
  TextColumn get endedAtEventId => text().nullable().references(
    MatchEvents,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get reason => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (side IN ('red', 'blue'))",
    "CHECK (source IN ('manual', 'suggested'))",
  ];
}

class AuditLogs extends Table {
  TextColumn get id => text()();
  TextColumn get matchId =>
      text().references(Matches, #id, onDelete: KeyAction.cascade)();
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
    MatchParticipants,
    MatchClocks,
    ActiveSessions,
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

  AppDatabase.inMemory() : super(NativeDatabase.memory());

  /// Used by tests and bootstrap code to explicitly check an opened executor.
  Future<void> assertCompatible() async {
    final row = await customSelect('PRAGMA user_version').getSingle();
    final version = row.read<int>('user_version');
    if (version == firstReleaseSchemaVersion) {
      throw LegacySchemaDetectedException(version);
    }
  }

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _createSchemaIndexes();
      await _createShotLocationTriggers();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (!details.wasCreated) {
        final row = await customSelect('PRAGMA user_version').getSingle();
        final version = row.read<int>('user_version');
        if (version == firstReleaseSchemaVersion) {
          throw LegacySchemaDetectedException(version);
        }
      }
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        throw LegacySchemaDetectedException(from);
      }
    },
  );

  Future<void> _createSchemaIndexes() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS match_participants_match_side '
      'ON match_participants(match_id, side)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS match_participants_player_profile '
      'ON match_participants(player_profile_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS match_clocks_match '
      'ON match_clocks(match_id)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS shot_locations_event '
      'ON shot_locations(event_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS match_events_match_clock '
      'ON match_events(match_id, match_clock_position_seconds)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS match_events_match_occurred '
      'ON match_events(match_id, occurred_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS matches_lifecycle_history '
      'ON matches(lifecycle, ended_at, created_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS match_events_match_deleted '
      'ON match_events(match_id, is_deleted)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS possession_segments_match_started '
      'ON possession_segments(match_id, started_at_event_id)',
    );
  }

  Future<void> _createShotLocationTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS shot_locations_field_goal_only
      BEFORE INSERT ON shot_locations
      BEGIN
        SELECT CASE WHEN
          (SELECT type FROM match_events WHERE id = NEW.event_id)
            NOT IN ('fieldGoal', 'score', 'miss')
          THEN RAISE(ABORT, 'shot location requires a field-goal event') END;
        SELECT CASE WHEN
          (SELECT match_id FROM match_events WHERE id = NEW.event_id) != NEW.match_id
          THEN RAISE(ABORT, 'shot location match does not match event') END;
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS shot_locations_field_goal_only_update
      BEFORE UPDATE OF event_id, match_id ON shot_locations
      BEGIN
        SELECT CASE WHEN
          (SELECT type FROM match_events WHERE id = NEW.event_id)
            NOT IN ('fieldGoal', 'score', 'miss')
          THEN RAISE(ABORT, 'shot location requires a field-goal event') END;
        SELECT CASE WHEN
          (SELECT match_id FROM match_events WHERE id = NEW.event_id) != NEW.match_id
          THEN RAISE(ABORT, 'shot location match does not match event') END;
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS match_events_shot_type_update
      BEFORE UPDATE OF type, match_id ON match_events
      WHEN EXISTS (SELECT 1 FROM shot_locations WHERE event_id = OLD.id)
      BEGIN
        SELECT CASE WHEN NEW.type NOT IN ('fieldGoal', 'score', 'miss')
          THEN RAISE(ABORT, 'located event must remain a field-goal event') END;
        SELECT CASE WHEN NEW.match_id != OLD.match_id
          THEN RAISE(ABORT, 'located event cannot change match') END;
      END
    ''');
  }
}

const firstReleaseSchemaVersion = 1;
