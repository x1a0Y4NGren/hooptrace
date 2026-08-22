import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:uuid/uuid.dart';

/// A test-only hook which is intentionally absent from the default service.
/// Hooks run after the business rows have been written but before the Drift
/// transaction callback returns, making rollback behavior observable without
/// weakening production error handling.
typedef MatchCommandFailureInjector =
    FutureOr<void> Function(MatchCommandFailurePoint point);

enum MatchCommandFailurePoint {
  afterMatchWritten,
  afterEventWritten,
  afterAuditWritten,
  afterLifecycleWritten,
  beforeCommit,
}

/// Immutable input shared by every command. IDs are generated when a command
/// is constructed, before a transaction is entered, so the same object can be
/// retried after a transient failure.
abstract class MatchCommand {
  MatchCommand({String? commandId}) : commandId = commandId ?? _newUuid();

  final String commandId;

  String get commandType;

  String get matchId;

  Map<String, Object?> get payload;

  String get fingerprint =>
      _fingerprint(<String, Object?>{'commandType': commandType, ...payload});
}

class StartMatchCommand extends MatchCommand {
  factory StartMatchCommand({
    String? commandId,
    String? matchId,
    required String redName,
    required String blueName,
    required RuleTemplate ruleTemplate,
    RecordingMode recordingMode = RecordingMode.simple,
    TrackingCoverage trackingCoverage = TrackingCoverage.scoresOnly,
    ClockMode clockMode = ClockMode.countUp,
    int? regulationSeconds,
    bool timerEnabled = false,
    DateTime? createdAt,
    DateTime? startedAt,
    String? note,
    String? redParticipantId,
    String? blueParticipantId,
    String? redPlayerProfileId,
    String? bluePlayerProfileId,
    String? clockId,
  }) {
    final created = (createdAt ?? DateTime.now()).toUtc();
    return StartMatchCommand._(
      commandId: commandId,
      matchId: matchId,
      redName: redName,
      blueName: blueName,
      ruleTemplate: ruleTemplate,
      recordingMode: recordingMode,
      trackingCoverage: trackingCoverage,
      clockMode: clockMode,
      regulationSeconds: regulationSeconds,
      timerEnabled: timerEnabled,
      createdAt: created,
      startedAt: (startedAt ?? created).toUtc(),
      note: note,
      redParticipantId: redParticipantId,
      blueParticipantId: blueParticipantId,
      redPlayerProfileId: redPlayerProfileId,
      bluePlayerProfileId: bluePlayerProfileId,
      clockId: clockId,
    );
  }

  StartMatchCommand._({
    super.commandId,
    String? matchId,
    required this.redName,
    required this.blueName,
    required this.ruleTemplate,
    required this.recordingMode,
    required this.trackingCoverage,
    required this.clockMode,
    required this.regulationSeconds,
    required this.timerEnabled,
    required this.createdAt,
    required this.startedAt,
    required this.note,
    String? redParticipantId,
    String? blueParticipantId,
    this.redPlayerProfileId,
    this.bluePlayerProfileId,
    String? clockId,
  }) : matchId = matchId ?? _newUuid(),
       redParticipantId = redParticipantId ?? _newUuid(),
       blueParticipantId = blueParticipantId ?? _newUuid(),
       clockId = clockId ?? _newUuid();

  @override
  final String matchId;
  final String redName;
  final String blueName;
  final RuleTemplate ruleTemplate;
  final RecordingMode recordingMode;
  final TrackingCoverage trackingCoverage;
  final ClockMode clockMode;
  final int? regulationSeconds;
  final bool timerEnabled;
  final DateTime createdAt;
  final DateTime startedAt;
  final String? note;
  final String redParticipantId;
  final String blueParticipantId;
  final String? redPlayerProfileId;
  final String? bluePlayerProfileId;
  final String clockId;

  @override
  String get commandType => 'start';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'redName': redName,
    'blueName': blueName,
    'ruleTemplate': _ruleTemplateJson(ruleTemplate),
    'recordingMode': recordingMode.name,
    'trackingCoverage': trackingCoverage.name,
    'clockMode': clockMode.name,
    'regulationSeconds': regulationSeconds,
    'timerEnabled': timerEnabled,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'startedAt': startedAt.toUtc().toIso8601String(),
    'note': note,
    'redParticipantId': redParticipantId,
    'blueParticipantId': blueParticipantId,
    'redPlayerProfileId': redPlayerProfileId,
    'bluePlayerProfileId': bluePlayerProfileId,
    'clockId': clockId,
  };
}

class MatchShotLocationInput {
  const MatchShotLocationInput({required this.x, required this.y, this.id});

  final double x;
  final double y;
  final String? id;

  Map<String, Object?> toJson({String? resolvedId}) => <String, Object?>{
    'id': resolvedId ?? id,
    'x': x,
    'y': y,
  };
}

class RecordMatchEventCommand extends MatchCommand {
  RecordMatchEventCommand({
    super.commandId,
    required this.matchId,
    String? eventId,
    this.type = EventKind.score,
    required this.side,
    required this.points,
    required DateTime occurredAt,
    this.outcome,
    this.note,
    this.customLabel,
    this.matchClockPositionSeconds,
    this.shotLocation,
    String? shotLocationId,
    String? auditId,
  }) : eventId = eventId ?? _newUuid(),
       occurredAt = occurredAt.toUtc(),
       shotLocationId = shotLocation == null
           ? null
           : (shotLocationId ?? shotLocation.id ?? _newUuid()),
       auditId = auditId ?? _newUuid();

  @override
  final String matchId;
  final String eventId;
  final EventKind type;
  final TeamSide? side;
  final int points;
  final DateTime occurredAt;
  final ShotOutcome? outcome;
  final String? note;
  final String? customLabel;
  final int? matchClockPositionSeconds;
  final MatchShotLocationInput? shotLocation;
  final String? shotLocationId;
  final String auditId;

  @override
  String get commandType => 'record';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'eventId': eventId,
    'type': type.name,
    'side': side?.name,
    'points': points,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'outcome': outcome?.name,
    'note': note,
    'customLabel': customLabel,
    'matchClockPositionSeconds': matchClockPositionSeconds,
    'shotLocation': shotLocation?.toJson(resolvedId: shotLocationId),
    'auditId': auditId,
  };
}

class CorrectMatchEventCommand extends MatchCommand {
  CorrectMatchEventCommand({
    super.commandId,
    required this.matchId,
    required this.eventId,
    this.type,
    this.side,
    this.points,
    this.outcome,
    this.note,
    this.customLabel,
    this.matchClockPositionSeconds,
    this.reason,
    String? auditId,
  }) : auditId = auditId ?? _newUuid();

  @override
  final String matchId;
  final String eventId;
  final EventKind? type;
  final TeamSide? side;
  final int? points;
  final ShotOutcome? outcome;
  final String? note;
  final String? customLabel;
  final int? matchClockPositionSeconds;
  final String? reason;
  final String auditId;

  @override
  String get commandType => 'correct';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'eventId': eventId,
    'type': type?.name,
    'side': side?.name,
    'points': points,
    'outcome': outcome?.name,
    'note': note,
    'customLabel': customLabel,
    'matchClockPositionSeconds': matchClockPositionSeconds,
    'reason': reason,
    'auditId': auditId,
  };
}

class UndoMatchEventCommand extends MatchCommand {
  UndoMatchEventCommand({
    super.commandId,
    required this.matchId,
    required this.eventId,
    this.reason,
    String? auditId,
  }) : auditId = auditId ?? _newUuid();

  @override
  final String matchId;
  final String eventId;
  final String? reason;
  final String auditId;

  @override
  String get commandType => 'undo';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'eventId': eventId,
    'reason': reason,
    'auditId': auditId,
  };
}

class PauseMatchCommand extends MatchCommand {
  PauseMatchCommand({
    super.commandId,
    required this.matchId,
    required DateTime occurredAt,
    String? eventId,
  }) : eventId = eventId ?? _newUuid(),
       occurredAt = occurredAt.toUtc();

  @override
  final String matchId;
  final String eventId;
  final DateTime occurredAt;

  @override
  String get commandType => 'pause';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'eventId': eventId,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };
}

class ResumeMatchCommand extends MatchCommand {
  ResumeMatchCommand({
    super.commandId,
    required this.matchId,
    required DateTime occurredAt,
    String? eventId,
  }) : eventId = eventId ?? _newUuid(),
       occurredAt = occurredAt.toUtc();

  @override
  final String matchId;
  final String eventId;
  final DateTime occurredAt;

  @override
  String get commandType => 'resume';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'eventId': eventId,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };
}

class FinishMatchCommand extends MatchCommand {
  FinishMatchCommand({
    super.commandId,
    required this.matchId,
    required DateTime endedAt,
  }) : endedAt = endedAt.toUtc();

  @override
  final String matchId;
  final DateTime endedAt;

  @override
  String get commandType => 'finish';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'endedAt': endedAt.toUtc().toIso8601String(),
  };
}

class AbandonMatchCommand extends MatchCommand {
  AbandonMatchCommand({
    super.commandId,
    required this.matchId,
    required DateTime endedAt,
  }) : endedAt = endedAt.toUtc();

  @override
  final String matchId;
  final DateTime endedAt;

  @override
  String get commandType => 'abandon';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'endedAt': endedAt.toUtc().toIso8601String(),
  };
}

typedef StartCommand = StartMatchCommand;
typedef RecordCommand = RecordMatchEventCommand;
typedef RecordEventCommand = RecordMatchEventCommand;
typedef CorrectCommand = CorrectMatchEventCommand;
typedef CorrectEventCommand = CorrectMatchEventCommand;
typedef UndoCommand = UndoMatchEventCommand;
typedef UndoEventCommand = UndoMatchEventCommand;
typedef PauseCommand = PauseMatchCommand;
typedef ResumeCommand = ResumeMatchCommand;
typedef FinishCommand = FinishMatchCommand;
typedef AbandonCommand = AbandonMatchCommand;
typedef MatchProjection = MatchDetail;
typedef CommittedMatchProjection = MatchDetail;

/// Base typed failure returned by every command operation.
class MatchCommandFailure implements Exception {
  MatchCommandFailure({
    required this.command,
    required this.message,
    required this.canRetry,
    this.projectionMatchId,
    this.cause,
    this.stackTrace,
  });

  final MatchCommand command;
  final String message;
  final bool canRetry;
  final String? projectionMatchId;
  final Object? cause;
  final StackTrace? stackTrace;
  MatchDetail? lastCommittedProjection;
  Future<MatchDetail> Function()? _retryAction;

  MatchDetail? get projection => lastCommittedProjection;

  bool get retryable => canRetry;

  MatchCommand get immutableCommand => command;

  Future<MatchDetail> retry() {
    if (!canRetry || _retryAction == null) {
      return Future<MatchDetail>.error(
        StateError('Command ${command.commandId} is not retryable.'),
      );
    }
    return _retryAction!();
  }

  @override
  String toString() => '$runtimeType: $message';
}

class CommandConflictFailure extends MatchCommandFailure {
  CommandConflictFailure({required super.command, super.projectionMatchId})
    : super(
        message:
            'Command ${command.commandId} was already committed with a '
            'different payload.',
        canRetry: false,
      );
}

class ActiveMatchConflictFailure extends MatchCommandFailure {
  ActiveMatchConflictFailure({
    required super.command,
    required super.projectionMatchId,
  }) : super(message: 'Another match is already active.', canRetry: false);
}

class CommandValidationFailure extends MatchCommandFailure {
  CommandValidationFailure({
    required super.command,
    required super.message,
    super.projectionMatchId,
  }) : super(canRetry: false);
}

class CommandTransactionFailure extends MatchCommandFailure {
  CommandTransactionFailure({
    required super.command,
    required super.message,
    required super.cause,
    required super.stackTrace,
    super.projectionMatchId,
  }) : super(canRetry: true);
}

typedef MatchCommandException = MatchCommandFailure;
typedef CommandFailure = MatchCommandFailure;

class MatchCommandService {
  MatchCommandService(
    this._database, {
    MatchCommandFailureInjector? failureInjector,
    FutureOr<void> Function()? failureHook,
    DateTime Function()? now,
  }) : _failureInjector = failureInjector,
       _failureHook = failureHook,
       _now = now ?? DateTime.now;

  final AppDatabase _database;
  final MatchCommandFailureInjector? _failureInjector;
  final FutureOr<void> Function()? _failureHook;
  final DateTime Function() _now;
  late final MatchRepository _repository = MatchRepository(_database);

  Future<MatchDetail> start(StartMatchCommand command) {
    return _execute(command, () async {
      await _database.transaction(() async {
        if (await _returnForDuplicate(command)) return;
        final active = await _activeRow();
        if (active != null) {
          throw ActiveMatchConflictFailure(
            command: command,
            projectionMatchId: active.matchId,
          );
        }
        final existing = await _matchRow(command.matchId);
        if (existing != null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Match ${command.matchId} already exists.',
            projectionMatchId: command.matchId,
          );
        }
        _validateStart(command);
        if (command.redPlayerProfileId != null &&
            await _playerRow(command.redPlayerProfileId!) == null) {
          throw CommandValidationFailure(
            command: command,
            message:
                'Missing red player profile ${command.redPlayerProfileId}.',
            projectionMatchId: command.matchId,
          );
        }
        if (command.bluePlayerProfileId != null &&
            await _playerRow(command.bluePlayerProfileId!) == null) {
          throw CommandValidationFailure(
            command: command,
            message:
                'Missing blue player profile ${command.bluePlayerProfileId}.',
            projectionMatchId: command.matchId,
          );
        }

        await _database
            .into(_database.matches)
            .insert(
              MatchesCompanion.insert(
                id: command.matchId,
                lifecycle: Value(MatchLifecycle.active.name),
                recordingMode: Value(command.recordingMode.name),
                trackingCoverage: Value(command.trackingCoverage.name),
                ruleTemplateJson: jsonEncode(
                  _ruleTemplateJson(command.ruleTemplate),
                ),
                createdAt: command.createdAt,
                startedAt: Value(command.startedAt),
                endedAt: const Value.absent(),
                timerEnabled: Value(command.timerEnabled),
                note: Value(command.note),
              ),
            );
        await _database
            .into(_database.matchParticipants)
            .insert(
              MatchParticipantsCompanion.insert(
                id: command.redParticipantId,
                matchId: command.matchId,
                side: TeamSide.red.name,
                nameSnapshot: command.redName.trim(),
                playerProfileId: Value(command.redPlayerProfileId),
              ),
            );
        await _database
            .into(_database.matchParticipants)
            .insert(
              MatchParticipantsCompanion.insert(
                id: command.blueParticipantId,
                matchId: command.matchId,
                side: TeamSide.blue.name,
                nameSnapshot: command.blueName.trim(),
                playerProfileId: Value(command.bluePlayerProfileId),
              ),
            );
        await _database
            .into(_database.matchClocks)
            .insert(
              MatchClocksCompanion.insert(
                id: command.clockId,
                matchId: command.matchId,
                mode: Value(command.clockMode.name),
                phase: Value(ClockPhase.regulation.name),
                accumulatedSeconds: const Value(0),
                runningSinceUtc: Value(
                  command.timerEnabled ? command.startedAt : null,
                ),
                regulationSeconds: Value(command.regulationSeconds),
              ),
            );
        await _database
            .into(_database.activeSessions)
            .insert(
              ActiveSessionsCompanion.insert(
                id: const Value('active'),
                matchId: command.matchId,
                claimedAtUtc: Value(command.startedAt),
              ),
            );
        await _inject(MatchCommandFailurePoint.afterMatchWritten);
        await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
      });
    });
  }

  Future<MatchDetail> record(RecordMatchEventCommand command) {
    return _execute(command, () async {
      await _database.transaction(() async {
        if (await _returnForDuplicate(command)) return;
        await _requireActiveMatch(command);
        _validateRecord(command);
        final existing = await _eventRow(command.eventId);
        if (existing != null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Event ${command.eventId} already exists.',
            projectionMatchId: command.matchId,
          );
        }
        final event = _eventFromCommand(command);
        await _database
            .into(_database.matchEvents)
            .insert(_eventCompanion(event));
        if (command.shotLocation != null) {
          await _database
              .into(_database.shotLocations)
              .insert(
                ShotLocationsCompanion.insert(
                  id: command.shotLocationId!,
                  matchId: command.matchId,
                  eventId: command.eventId,
                  x: command.shotLocation!.x,
                  y: command.shotLocation!.y,
                  isConfirmed: const Value(true),
                ),
              );
        }
        final after = <String, Object?>{
          ..._eventJsonFromEvent(event),
          if (command.shotLocation != null)
            'shotLocation': command.shotLocation!.toJson(
              resolvedId: command.shotLocationId,
            ),
        };
        await _writeAudit(
          id: command.auditId,
          matchId: command.matchId,
          targetId: command.eventId,
          action: 'create',
          before: const <String, Object?>{},
          after: after,
        );
        await _inject(MatchCommandFailurePoint.afterEventWritten);
        await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
      });
    });
  }

  Future<MatchDetail> correct(CorrectMatchEventCommand command) {
    return _execute(command, () async {
      await _database.transaction(() async {
        if (await _returnForDuplicate(command)) return;
        final before = await _eventRow(command.eventId);
        if (before == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Missing event ${command.eventId}.',
            projectionMatchId: command.matchId,
          );
        }
        if (before.matchId != command.matchId) {
          throw CommandValidationFailure(
            command: command,
            message: 'Event ${command.eventId} belongs to another match.',
            projectionMatchId: before.matchId,
          );
        }
        late final MatchEvent replacement;
        try {
          replacement = _correctedEvent(before, command);
        } on ArgumentError catch (error) {
          throw CommandValidationFailure(
            command: command,
            message: error.message?.toString() ?? error.toString(),
            projectionMatchId: command.matchId,
          );
        }
        final beforeJson = _eventJson(before);
        final afterJson = _eventJsonFromEvent(replacement);
        await (_database.update(_database.matchEvents)
              ..where((event) => event.id.equals(command.eventId)))
            .write(_eventCompanion(replacement, includeId: false));
        await _writeAudit(
          id: command.auditId,
          matchId: command.matchId,
          targetId: command.eventId,
          action: 'edit',
          before: beforeJson,
          after: afterJson,
          reason: command.reason,
        );
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.beforeCommit);
      });
    });
  }

  Future<MatchDetail> undo(UndoMatchEventCommand command) {
    return _execute(command, () async {
      await _database.transaction(() async {
        if (await _returnForDuplicate(command)) return;
        final before = await _eventRow(command.eventId);
        if (before == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Missing event ${command.eventId}.',
            projectionMatchId: command.matchId,
          );
        }
        if (before.matchId != command.matchId) {
          throw CommandValidationFailure(
            command: command,
            message: 'Event ${command.eventId} belongs to another match.',
            projectionMatchId: before.matchId,
          );
        }
        final beforeJson = _eventJson(before);
        final afterJson = <String, Object?>{...beforeJson, 'isDeleted': true};
        await (_database.update(_database.matchEvents)
              ..where((event) => event.id.equals(command.eventId)))
            .write(const MatchEventsCompanion(isDeleted: Value(true)));
        await _writeAudit(
          id: command.auditId,
          matchId: command.matchId,
          targetId: command.eventId,
          action: 'undo',
          before: beforeJson,
          after: afterJson,
          reason: command.reason,
        );
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.beforeCommit);
      });
    });
  }

  Future<MatchDetail> pause(PauseMatchCommand command) {
    return _recordSemantic(command, label: 'pause');
  }

  Future<MatchDetail> resume(ResumeMatchCommand command) {
    return _recordSemantic(command, label: 'resume');
  }

  Future<MatchDetail> finish(FinishMatchCommand command) {
    return _complete(command, MatchLifecycle.finished);
  }

  Future<MatchDetail> abandon(AbandonMatchCommand command) {
    return _complete(command, MatchLifecycle.abandoned);
  }

  // Named aliases keep the command boundary easy to discover for consumers
  // while all paths still execute through the same transactional methods.
  Future<MatchDetail> startMatch(StartMatchCommand command) => start(command);

  Future<MatchDetail> recordEvent(RecordMatchEventCommand command) =>
      record(command);

  Future<MatchDetail> correctEvent(CorrectMatchEventCommand command) =>
      correct(command);

  Future<MatchDetail> undoEvent(UndoMatchEventCommand command) => undo(command);

  Future<MatchDetail> pauseMatch(PauseMatchCommand command) => pause(command);

  Future<MatchDetail> resumeMatch(ResumeMatchCommand command) =>
      resume(command);

  Future<MatchDetail> finishMatch(FinishMatchCommand command) =>
      finish(command);

  Future<MatchDetail> abandonMatch(AbandonMatchCommand command) =>
      abandon(command);

  Future<MatchDetail> _recordSemantic(
    MatchCommand command, {
    required String label,
  }) {
    return _execute(command, () async {
      await _database.transaction(() async {
        if (await _returnForDuplicate(command)) return;
        await _requireActiveMatch(command);
        final eventId = switch (command) {
          PauseMatchCommand(:final eventId) => eventId,
          ResumeMatchCommand(:final eventId) => eventId,
          _ => throw StateError('Unsupported semantic command.'),
        };
        final occurredAt = switch (command) {
          PauseMatchCommand(:final occurredAt) => occurredAt,
          ResumeMatchCommand(:final occurredAt) => occurredAt,
          _ => _now().toUtc(),
        };
        await _database
            .into(_database.matchEvents)
            .insert(
              MatchEventsCompanion.insert(
                id: eventId,
                matchId: command.matchId,
                type: EventKind.pause.name,
                points: const Value(0),
                occurredAt: occurredAt,
                customLabel: Value(label),
              ),
            );
        await _inject(MatchCommandFailurePoint.afterEventWritten);
        await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
      });
    });
  }

  Future<MatchDetail> _complete(
    MatchCommand command,
    MatchLifecycle lifecycle,
  ) {
    return _execute(command, () async {
      await _database.transaction(() async {
        if (await _returnForDuplicate(command)) return;
        final row = await _matchRow(command.matchId);
        if (row == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Missing match ${command.matchId}.',
          );
        }
        final active = await _activeRow();
        if (row.lifecycle == MatchLifecycle.active.name &&
            active?.matchId != command.matchId) {
          throw ActiveMatchConflictFailure(
            command: command,
            projectionMatchId: active?.matchId ?? command.matchId,
          );
        }
        if (row.lifecycle == MatchLifecycle.abandoned.name &&
            lifecycle == MatchLifecycle.finished) {
          throw CommandValidationFailure(
            command: command,
            message: 'An abandoned match cannot be finished.',
            projectionMatchId: command.matchId,
          );
        }
        final endedAt = switch (command) {
          FinishMatchCommand(:final endedAt) => endedAt,
          AbandonMatchCommand(:final endedAt) => endedAt,
          _ => _now().toUtc(),
        };
        await (_database.update(
          _database.matches,
        )..where((match) => match.id.equals(command.matchId))).write(
          MatchesCompanion(
            lifecycle: Value(lifecycle.name),
            endedAt: Value(endedAt),
          ),
        );
        await (_database.delete(_database.activeSessions)..where(
              (session) =>
                  session.id.equals('active') &
                  session.matchId.equals(command.matchId),
            ))
            .go();
        await _inject(MatchCommandFailurePoint.afterLifecycleWritten);
        await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
      });
    });
  }

  Future<MatchDetail> _execute(
    MatchCommand command,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
      final projection = await _projection(command.matchId);
      if (projection == null) {
        throw CommandTransactionFailure(
          command: command,
          message: 'Command committed without a readable projection.',
          cause: StateError('Projection disappeared after command commit.'),
          stackTrace: StackTrace.current,
        );
      }
      return projection;
    } on MatchCommandFailure catch (failure) {
      failure.lastCommittedProjection = await _projection(
        failure.projectionMatchId ?? command.matchId,
      );
      if (failure.canRetry) {
        failure._retryAction ??= () => _execute(command, operation);
      }
      rethrow;
    } on Object catch (error, stackTrace) {
      final active = command is StartMatchCommand ? await _activeRow() : null;
      if (active != null && active.matchId != command.matchId) {
        final failure = ActiveMatchConflictFailure(
          command: command,
          projectionMatchId: active.matchId,
        );
        failure.lastCommittedProjection = await _projection(active.matchId);
        throw failure;
      }
      final failure = CommandTransactionFailure(
        command: command,
        message: 'Command ${command.commandId} rolled back: $error',
        cause: error,
        stackTrace: stackTrace,
        projectionMatchId: command.matchId,
      );
      failure.lastCommittedProjection = await _projection(command.matchId);
      failure._retryAction = () => _execute(command, operation);
      throw failure;
    }
  }

  Future<bool> _returnForDuplicate(MatchCommand command) async {
    final receipt = await _receipt(command.commandId);
    if (receipt == null) return false;
    final before = _decodeObject(receipt.beforeJson);
    final storedFingerprint = before['fingerprint'];
    if (storedFingerprint != command.fingerprint) {
      throw CommandConflictFailure(
        command: command,
        projectionMatchId: before['matchId'] as String?,
      );
    }
    return true;
  }

  Future<void> _writeReceipt(MatchCommand command) {
    return _database
        .into(_database.auditLogs)
        .insert(
          AuditLogsCompanion.insert(
            id: command.commandId,
            matchId: command.matchId,
            targetId: command.commandId,
            action: 'command',
            beforeJson: jsonEncode(<String, Object?>{
              'commandType': command.commandType,
              'commandId': command.commandId,
              'matchId': command.matchId,
              'fingerprint': command.fingerprint,
            }),
            afterJson: jsonEncode(<String, Object?>{
              'committed': true,
              'commandType': command.commandType,
              'matchId': command.matchId,
            }),
            reason: const Value.absent(),
            createdAt: _now().toUtc(),
          ),
        );
  }

  Future<void> _writeAudit({
    required String id,
    required String matchId,
    required String targetId,
    required String action,
    required Map<String, Object?> before,
    required Map<String, Object?> after,
    String? reason,
  }) {
    final normalized = reason?.trim();
    return _database
        .into(_database.auditLogs)
        .insert(
          AuditLogsCompanion.insert(
            id: id,
            matchId: matchId,
            targetId: targetId,
            action: action,
            beforeJson: jsonEncode(before),
            afterJson: jsonEncode(after),
            reason: Value(
              normalized == null || normalized.isEmpty ? null : normalized,
            ),
            createdAt: _now().toUtc(),
          ),
        );
  }

  Future<void> _requireActiveMatch(MatchCommand command) async {
    final row = await _matchRow(command.matchId);
    if (row == null) {
      throw CommandValidationFailure(
        command: command,
        message: 'Missing match ${command.matchId}.',
      );
    }
    final active = await _activeRow();
    if (row.lifecycle != MatchLifecycle.active.name ||
        active?.matchId != command.matchId) {
      throw CommandValidationFailure(
        command: command,
        message: 'Match ${command.matchId} is not the active match.',
        projectionMatchId: command.matchId,
      );
    }
  }

  Future<AuditLog?> _receipt(String commandId) async {
    final query = _database.select(_database.auditLogs)
      ..where((row) => row.id.equals(commandId));
    final row = await query.getSingleOrNull();
    if (row == null || row.action == 'command') return row;
    throw CommandConflictFailure(
      command: _UnknownCommand(commandId),
      projectionMatchId: row.matchId,
    );
  }

  Future<Matche?> _matchRow(String id) {
    final query = _database.select(_database.matches)
      ..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<ActiveSession?> _activeRow() {
    final query = _database.select(_database.activeSessions)
      ..where((row) => row.id.equals('active'));
    return query.getSingleOrNull();
  }

  Future<MatchEventRow?> _eventRow(String id) {
    final query = _database.select(_database.matchEvents)
      ..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<PlayerRow?> _playerRow(String id) {
    final query = _database.select(_database.players)
      ..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<MatchDetail?> _projection(String matchId) {
    return _repository.getMatchDetail(matchId);
  }

  Future<void> _inject(MatchCommandFailurePoint point) async {
    await _failureInjector?.call(point);
    await _failureHook?.call();
  }

  static void _validateStart(StartMatchCommand command) {
    if (command.redName.trim().isEmpty || command.blueName.trim().isEmpty) {
      throw CommandValidationFailure(
        command: command,
        message: 'Both participant names are required.',
      );
    }
    if (command.redPlayerProfileId != null &&
        command.redPlayerProfileId == command.bluePlayerProfileId) {
      throw CommandValidationFailure(
        command: command,
        message: 'A player profile cannot occupy both sides.',
      );
    }
    if (command.regulationSeconds != null && command.regulationSeconds! < 0) {
      throw CommandValidationFailure(
        command: command,
        message: 'Regulation duration cannot be negative.',
      );
    }
  }

  static void _validateRecord(RecordMatchEventCommand command) {
    if (command.points < 0) {
      throw CommandValidationFailure(
        command: command,
        message: 'Event points cannot be negative.',
      );
    }
    if (command.matchClockPositionSeconds != null &&
        command.matchClockPositionSeconds! < 0) {
      throw CommandValidationFailure(
        command: command,
        message: 'Match-clock positions cannot be negative.',
      );
    }
    if (command.shotLocation != null) {
      const locationEventTypes = <EventKind>{
        EventKind.score,
        EventKind.fieldGoal,
        EventKind.miss,
      };
      if (!locationEventTypes.contains(command.type)) {
        throw CommandValidationFailure(
          command: command,
          message: 'Shot locations require a field-goal event.',
        );
      }
      try {
        CourtPoint(x: command.shotLocation!.x, y: command.shotLocation!.y);
      } on Object catch (error) {
        throw CommandValidationFailure(
          command: command,
          message: 'Shot location is invalid: $error',
        );
      }
    }
    try {
      _eventFromCommand(command);
    } on ArgumentError catch (error) {
      throw CommandValidationFailure(
        command: command,
        message: error.message?.toString() ?? error.toString(),
      );
    }
  }

  static MatchEvent _eventFromCommand(RecordMatchEventCommand command) {
    return MatchEvent(
      id: command.eventId,
      matchId: command.matchId,
      type: command.type,
      side: command.side,
      points: command.points,
      occurredAt: command.occurredAt,
      outcome:
          command.outcome ??
          (command.type == EventKind.score ? ShotOutcome.made : null),
      note: command.note,
      customLabel: command.customLabel,
      matchClockPositionSeconds: command.matchClockPositionSeconds,
    );
  }

  static MatchEvent _correctedEvent(
    MatchEventRow before,
    CorrectMatchEventCommand command,
  ) {
    return MatchEvent(
      id: before.id,
      matchId: before.matchId,
      type: command.type ?? EventKind.values.byName(before.type),
      side:
          command.side ??
          (before.side == null ? null : TeamSide.values.byName(before.side!)),
      points: command.points ?? before.points,
      occurredAt: before.occurredAt.toUtc(),
      outcome:
          command.outcome ??
          (before.outcome == null
              ? null
              : ShotOutcome.values.byName(before.outcome!)),
      note: command.note ?? before.note,
      customLabel: command.customLabel ?? before.customLabel,
      matchClockPositionSeconds:
          command.matchClockPositionSeconds ?? before.matchClockPositionSeconds,
      isDeleted: before.isDeleted,
    );
  }

  static MatchEventsCompanion _eventCompanion(
    MatchEvent event, {
    bool includeId = true,
  }) {
    return MatchEventsCompanion(
      id: includeId ? Value(event.id) : const Value.absent(),
      matchId: Value(event.matchId),
      type: Value(event.type.name),
      side: Value(event.side?.name),
      points: Value(event.points),
      outcome: Value(event.outcome?.name),
      matchClockPositionSeconds: Value(event.matchClockPositionSeconds),
      occurredAt: Value(event.occurredAt),
      note: Value(event.note),
      customLabel: Value(event.customLabel),
      isDeleted: Value(event.isDeleted),
    );
  }

  static Map<String, Object?> _eventJson(MatchEventRow row) =>
      <String, Object?>{
        'id': row.id,
        'matchId': row.matchId,
        'type': row.type,
        'side': row.side,
        'points': row.points,
        'occurredAt': row.occurredAt.toUtc().toIso8601String(),
        'note': row.note,
        'customLabel': row.customLabel,
        'outcome': row.outcome,
        'matchClockPositionSeconds': row.matchClockPositionSeconds,
        'isDeleted': row.isDeleted,
      };

  static Map<String, Object?> _eventJsonFromEvent(MatchEvent event) =>
      <String, Object?>{
        'id': event.id,
        'matchId': event.matchId,
        'type': event.type.name,
        'side': event.side?.name,
        'points': event.points,
        'occurredAt': event.occurredAt.toUtc().toIso8601String(),
        'note': event.note,
        'customLabel': event.customLabel,
        'outcome': event.outcome?.name,
        'matchClockPositionSeconds': event.matchClockPositionSeconds,
        'isDeleted': event.isDeleted,
      };
}

class _UnknownCommand extends MatchCommand {
  _UnknownCommand(String commandId) : super(commandId: commandId);

  @override
  String get commandType => 'unknown';

  @override
  String get matchId => '';

  @override
  Map<String, Object?> get payload => const <String, Object?>{};
}

Map<String, Object?> _decodeObject(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! Map) return const <String, Object?>{};
  return decoded.cast<String, Object?>();
}

Map<String, Object?> _ruleTemplateJson(RuleTemplate template) =>
    <String, Object?>{
      'id': template.id,
      'name': template.name,
      'scoreButtons': template.scoreButtons,
      'targetScore': template.targetScore,
      'timeLimitSeconds': template.timeLimitSeconds,
      'winByTwo': template.winByTwo,
      'foulLimit': template.foulLimit,
      'possessionHintEnabled': template.possessionHintEnabled,
      'possessionPolicy': template.possessionPolicy.name,
      'customEventTypes': template.customEventTypes,
    };

String _fingerprint(Map<String, Object?> payload) =>
    sha256.convert(utf8.encode(jsonEncode(payload))).toString();

String _newUuid() => const Uuid().v4();
