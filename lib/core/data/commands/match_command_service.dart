import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/match.dart' as domain_match;
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/clock/clock_engine.dart';
import 'package:hooptrace/core/domain/entities/clock_state.dart';
import 'package:hooptrace/core/domain/entities/shot_location.dart' as domain;
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:uuid/uuid.dart';

export 'package:hooptrace/core/domain/clock/clock_engine.dart'
    show ClockEngine, ClockProjection, ClockRecoveryReason, MatchClockEngine;
export 'package:hooptrace/core/domain/entities/match_detail.dart'
    show
        MatchDecisionKind,
        MatchDecisionReason,
        MatchDecision,
        MatchRuleWarning;

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
      ruleTemplate: _copyRuleTemplate(ruleTemplate),
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

class ConfirmShotLocationCommand extends MatchCommand {
  ConfirmShotLocationCommand({
    super.commandId,
    required this.matchId,
    required this.eventId,
    required this.point,
    String? shotLocationId,
    String? auditId,
  }) : shotLocationId = shotLocationId ?? _newUuid(),
       auditId = auditId ?? _newUuid();

  @override
  final String matchId;
  final String eventId;
  final CourtPoint point;
  final String shotLocationId;
  final String auditId;

  @override
  String get commandType => 'confirmShotLocation';

  @override
  Map<String, Object?> get payload => <String, Object?>{
    'commandId': commandId,
    'matchId': matchId,
    'eventId': eventId,
    'shotLocationId': shotLocationId,
    'x': point.x,
    'y': point.y,
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
  }) : eventId =
           eventId ?? (commandId == null ? _newUuid() : '$commandId:event'),
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
  }) : eventId =
           eventId ?? (commandId == null ? _newUuid() : '$commandId:event'),
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

/// Acknowledges a blocking target/clock decision and resumes target play or
/// starts overtime. The persisted decision marker makes this command safe to
/// retry and prevents the same score projection from prompting repeatedly.
class ContinueMatchCommand extends MatchCommand {
  ContinueMatchCommand({
    super.commandId,
    required this.matchId,
    required DateTime occurredAt,
    String? eventId,
  }) : eventId =
           eventId ?? (commandId == null ? _newUuid() : '$commandId:event'),
       occurredAt = occurredAt.toUtc();

  @override
  final String matchId;
  final String eventId;
  final DateTime occurredAt;

  @override
  String get commandType => 'continue';

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
typedef ConfirmLocationCommand = ConfirmShotLocationCommand;
typedef ConfirmShotCommand = ConfirmShotLocationCommand;
typedef CorrectCommand = CorrectMatchEventCommand;
typedef CorrectEventCommand = CorrectMatchEventCommand;
typedef UndoCommand = UndoMatchEventCommand;
typedef UndoEventCommand = UndoMatchEventCommand;
typedef PauseCommand = PauseMatchCommand;
typedef ResumeCommand = ResumeMatchCommand;
typedef ContinueCommand = ContinueMatchCommand;
typedef ContinuePlayCommand = ContinueMatchCommand;
typedef ContinueOvertimeCommand = ContinueMatchCommand;
typedef AcknowledgeDecisionCommand = ContinueMatchCommand;
typedef MatchClockService = MatchCommandService;
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

class EndConditionFailure extends CommandValidationFailure {
  EndConditionFailure({
    required super.command,
    required this.decision,
    super.projectionMatchId,
  }) : super(message: decision.message);

  final MatchDecision decision;
}

class ClockRecoveryFailure extends CommandValidationFailure {
  ClockRecoveryFailure({
    required super.command,
    required this.recoveryMessage,
    super.projectionMatchId,
  }) : super(message: recoveryMessage);

  final String recoveryMessage;
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

  /// Reconstructs a clock from persisted seconds plus its UTC anchor. A
  /// backward wall-clock move and a countdown expiry are normalized in one
  /// transaction so the same recovery state is not reported repeatedly.
  Future<ClockProjection?> readClock(String matchId, {DateTime? at}) async {
    return _database.transaction(() async {
      final row = await _clockRow(matchId);
      if (row == null) return null;
      final projection = ClockEngine().project(
        state: _clockState(row),
        now: (at ?? _now()).toUtc(),
      );
      if (projection.requiresPersistence) {
        await _persistClockProjection(projection);
      }
      return projection;
    });
  }

  Future<ClockProjection?> getClock(String matchId, {DateTime? at}) =>
      readClock(matchId, at: at);

  Future<ClockProjection?> clock(String matchId, {DateTime? at}) =>
      readClock(matchId, at: at);

  Future<MatchDetail> start(StartMatchCommand command) {
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
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
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> record(RecordMatchEventCommand command) async {
    // Normalize clock boundaries before opening the event transaction. A
    // countdown expiry or wall-clock recovery must remain persisted even
    // though the attempted score is rejected.
    if (await _receipt(command.commandId) == null) {
      final precondition = await _preflightRecord(command);
      if (precondition != null) {
        precondition.lastCommittedProjection = await _projection(
          command.matchId,
        );
        throw precondition;
      }
    }
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
        await _requireActiveMatch(command);
        await _guardInputClock(command);
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
        await _applyPostEventRules(command);
        await _inject(MatchCommandFailurePoint.afterEventWritten);
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> confirmShotLocation(ConfirmShotLocationCommand command) {
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
        await _requireActiveMatch(command);
        final event = await _eventRow(command.eventId);
        if (event == null || event.matchId != command.matchId) {
          throw CommandValidationFailure(
            command: command,
            message: 'Missing event ${command.eventId}.',
            projectionMatchId: command.matchId,
          );
        }
        if (event.isDeleted ||
            event.type != EventKind.fieldGoal.name ||
            event.outcome != ShotOutcome.made.name) {
          throw CommandValidationFailure(
            command: command,
            message: 'Only a committed made field goal can receive a location.',
            projectionMatchId: command.matchId,
          );
        }
        final existing = await _shotLocationForEvent(command.eventId);
        if (existing != null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Event ${command.eventId} already has a shot location.',
            projectionMatchId: command.matchId,
          );
        }
        await _database
            .into(_database.shotLocations)
            .insert(
              ShotLocationsCompanion.insert(
                id: command.shotLocationId,
                matchId: command.matchId,
                eventId: command.eventId,
                x: command.point.x,
                y: command.point.y,
                isConfirmed: const Value(true),
              ),
            );
        await _writeAudit(
          id: command.auditId,
          matchId: command.matchId,
          targetId: command.eventId,
          action: 'locate',
          before: const <String, Object?>{},
          after: <String, Object?>{
            'eventId': command.eventId,
            'shotLocationId': command.shotLocationId,
            'x': command.point.x,
            'y': command.point.y,
            'isConfirmed': true,
          },
        );
        await _inject(MatchCommandFailurePoint.afterEventWritten);
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> correct(CorrectMatchEventCommand command) {
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
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
        final beforeProjection = await _projectionInTransaction(
          command.matchId,
        );
        await _guardEventMutation(command, before);
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
        if (replacement.type == EventKind.score &&
            replacement.outcome != null &&
            replacement.outcome != ShotOutcome.made) {
          throw CommandValidationFailure(
            command: command,
            message: 'Score events must have a made outcome.',
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
        final afterProjection = await _projectionInTransaction(command.matchId);
        await _applyPostScoreRules(
          command.matchId,
          scoreChanged: _scoresChanged(beforeProjection, afterProjection),
          decisionEventId: '${command.commandId}:decision',
        );
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> undo(UndoMatchEventCommand command) {
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
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
        final beforeProjection = await _projectionInTransaction(
          command.matchId,
        );
        await _guardEventMutation(command, before);
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
        final afterProjection = await _projectionInTransaction(command.matchId);
        await _applyPostScoreRules(
          command.matchId,
          scoreChanged: _scoresChanged(beforeProjection, afterProjection),
          decisionEventId: '${command.commandId}:decision',
        );
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> pause(PauseMatchCommand command) async {
    final failure = await _preflightSemantic(command, label: 'pause');
    if (failure != null) {
      failure.lastCommittedProjection = await _projection(command.matchId);
      throw failure;
    }
    return _recordSemantic(command, label: 'pause');
  }

  Future<MatchDetail> resume(ResumeMatchCommand command) async {
    final failure = await _preflightSemantic(command, label: 'resume');
    if (failure != null) {
      failure.lastCommittedProjection = await _projection(command.matchId);
      throw failure;
    }
    return _recordSemantic(command, label: 'resume');
  }

  Future<MatchDetail> continueMatch(ContinueMatchCommand command) {
    return _continueDecision(command);
  }

  Future<MatchDetail> continuePlay(ContinueMatchCommand command) {
    return continueMatch(command);
  }

  Future<MatchDetail> acknowledgeDecision(ContinueMatchCommand command) {
    return continueMatch(command);
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

  Future<MatchDetail> confirmLocation(ConfirmShotLocationCommand command) =>
      confirmShotLocation(command);

  Future<MatchDetail> correctEvent(CorrectMatchEventCommand command) =>
      correct(command);

  Future<MatchDetail> undoEvent(UndoMatchEventCommand command) => undo(command);

  Future<MatchDetail> pauseMatch(PauseMatchCommand command) => pause(command);

  Future<MatchDetail> resumeMatch(ResumeMatchCommand command) =>
      resume(command);

  Future<MatchDetail> continueMatchPlay(ContinueMatchCommand command) =>
      continueMatch(command);

  Future<MatchDetail> finishMatch(FinishMatchCommand command) =>
      finish(command);

  Future<MatchDetail> abandonMatch(AbandonMatchCommand command) =>
      abandon(command);

  Future<MatchDetail> _recordSemantic(
    MatchCommand command, {
    required String label,
  }) {
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
        await _requireActiveMatch(command);
        final row = await _clockRow(command.matchId);
        if (row == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Missing match clock for ${command.matchId}.',
            projectionMatchId: command.matchId,
          );
        }
        final now = _now().toUtc();
        final matchRow = await _matchRow(command.matchId);
        final timerEnabled = matchRow?.timerEnabled ?? false;
        final clockProjection = ClockEngine().project(
          state: _clockState(row),
          now: now,
        );
        if (clockProjection.requiresPersistence) {
          await _persistClockProjection(clockProjection);
        }
        final latestSemantic = await _latestSemanticLabel(command.matchId);
        final isPaused = latestSemantic == 'pause';
        final detail = await _projectionInTransaction(command.matchId);
        final pendingDecision = detail?.decision;
        if (pendingDecision != null) {
          throw EndConditionFailure(
            command: command,
            decision: pendingDecision,
            projectionMatchId: command.matchId,
          );
        }
        if ((label == 'pause' && isPaused) ||
            (label == 'resume' && !isPaused)) {
          throw CommandValidationFailure(
            command: command,
            message: label == 'pause'
                ? 'Match ${command.matchId} is already paused.'
                : 'Match ${command.matchId} is not paused.',
            projectionMatchId: command.matchId,
          );
        }
        if (timerEnabled &&
            label == 'pause' &&
            clockProjection.runningSinceUtc == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Match ${command.matchId} is not running.',
            projectionMatchId: command.matchId,
          );
        }
        if (timerEnabled &&
            label == 'resume' &&
            clockProjection.runningSinceUtc != null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Match ${command.matchId} is already running.',
            projectionMatchId: command.matchId,
          );
        }
        if (label == 'resume' &&
            clockProjection.phase == ClockPhase.regulationExpired) {
          final detail = await _projectionInTransaction(command.matchId);
          final decision =
              detail?.decision ??
              _decisionForScores(
                reason: MatchDecisionReason.regulationExpired,
                detail: detail,
              );
          throw EndConditionFailure(
            command: command,
            decision: decision,
            projectionMatchId: command.matchId,
          );
        }
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
        final beforeClock = _clockJson(_clockState(row));
        final nextClock = label == 'pause' || !timerEnabled
            ? clockProjection.normalizedState.copyWith(runningSinceUtc: null)
            : clockProjection.normalizedState.copyWith(runningSinceUtc: now);
        await _updateClock(nextClock);
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
        await _writeAudit(
          id: _newUuid(),
          matchId: command.matchId,
          targetId: row.id,
          action: 'edit',
          before: beforeClock,
          after: _clockJson(nextClock),
          reason: 'clock-$label',
        );
        await _inject(MatchCommandFailurePoint.afterEventWritten);
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> _continueDecision(ContinueMatchCommand command) {
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
        await _requireActiveMatch(command);
        final row = await _clockRow(command.matchId);
        if (row == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Missing match clock for ${command.matchId}.',
            projectionMatchId: command.matchId,
          );
        }

        final now = _now().toUtc();
        final matchRow = await _matchRow(command.matchId);
        final timerEnabled = matchRow?.timerEnabled ?? false;
        final clockProjection = ClockEngine().project(
          state: _clockState(row),
          now: now,
        );
        if (clockProjection.requiresPersistence) {
          await _persistClockProjection(clockProjection);
        }
        final detail = await _projectionInTransaction(command.matchId);
        final decision =
            detail?.decision ??
            _decisionFromLabel(
              await _latestDecisionLabel(command.matchId),
              redScore: detail?.redScore ?? 0,
              blueScore: detail?.blueScore ?? 0,
            );
        if (decision == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'There is no pending match decision to continue.',
            projectionMatchId: command.matchId,
          );
        }

        final beforeClock = _clockJson(clockProjection.normalizedState);
        final ClockState nextClock;
        final String semanticLabel;
        if (decision.reason == MatchDecisionReason.regulationExpired ||
            clockProjection.phase == ClockPhase.regulationExpired) {
          nextClock = clockProjection.normalizedState.copyWith(
            phase: ClockPhase.overtime,
            accumulatedSeconds: 0,
            runningSinceUtc: timerEnabled ? now : null,
          );
          semanticLabel = 'continueOvertime';
        } else {
          nextClock = clockProjection.normalizedState.copyWith(
            runningSinceUtc: timerEnabled ? now : null,
          );
          semanticLabel = 'continueTarget';
        }
        await _updateClock(nextClock);
        await _database
            .into(_database.matchEvents)
            .insert(
              MatchEventsCompanion.insert(
                id: command.eventId,
                matchId: command.matchId,
                type: EventKind.pause.name,
                points: const Value(0),
                occurredAt: command.occurredAt,
                customLabel: Value(semanticLabel),
              ),
            );
        await _writeAudit(
          id: _newUuid(),
          matchId: command.matchId,
          targetId: row.id,
          action: 'edit',
          before: beforeClock,
          after: _clockJson(nextClock),
          reason: semanticLabel,
        );
        await _inject(MatchCommandFailurePoint.afterEventWritten);
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> _complete(
    MatchCommand command,
    MatchLifecycle lifecycle,
  ) {
    return _execute(command, () {
      return _database.transaction(() async {
        final duplicate = await _returnForDuplicate(command);
        if (duplicate != null) return duplicate;
        final row = await _matchRow(command.matchId);
        if (row == null) {
          throw CommandValidationFailure(
            command: command,
            message: 'Missing match ${command.matchId}.',
          );
        }
        if (row.lifecycle != MatchLifecycle.active.name) {
          throw CommandValidationFailure(
            command: command,
            message: 'Only an active match can become terminal.',
            projectionMatchId: command.matchId,
          );
        }
        final active = await _activeRow();
        if (active?.matchId != command.matchId) {
          throw ActiveMatchConflictFailure(
            command: command,
            projectionMatchId: active?.matchId ?? command.matchId,
          );
        }
        if (lifecycle == MatchLifecycle.finished) {
          final detail = await _projectionInTransaction(command.matchId);
          final decision = detail?.decision;
          if (decision != null && !decision.canFinish) {
            throw EndConditionFailure(
              command: command,
              decision: decision,
              projectionMatchId: command.matchId,
            );
          }
        }
        final endedAt = switch (command) {
          FinishMatchCommand(:final endedAt) => endedAt,
          AbandonMatchCommand(:final endedAt) => endedAt,
          _ => _now().toUtc(),
        };
        final clockRow = await _clockRow(command.matchId);
        if (clockRow != null) {
          final beforeClock = _clockState(clockRow);
          final clockProjection = ClockEngine().project(
            state: beforeClock,
            now: _now().toUtc(),
          );
          final nextClock = clockProjection.normalizedState.copyWith(
            runningSinceUtc: null,
          );
          await _updateClock(nextClock);
          await _writeAudit(
            id: _newUuid(),
            matchId: command.matchId,
            targetId: clockRow.id,
            action: 'edit',
            before: _clockJson(beforeClock),
            after: _clockJson(nextClock),
            reason: 'clock-$lifecycle',
          );
        }
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
        final result = await _writeReceipt(command);
        await _inject(MatchCommandFailurePoint.afterAuditWritten);
        await _inject(MatchCommandFailurePoint.beforeCommit);
        return result;
      });
    });
  }

  Future<MatchDetail> _execute(
    MatchCommand command,
    Future<MatchDetail> Function() operation,
  ) async {
    try {
      return await operation();
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

  Future<MatchDetail?> _returnForDuplicate(MatchCommand command) async {
    final receipt = await _receipt(command.commandId);
    if (receipt == null) return null;
    final before = _decodeObject(receipt.beforeJson);
    final storedFingerprint = before['fingerprint'];
    if (storedFingerprint != command.fingerprint) {
      throw CommandConflictFailure(
        command: command,
        projectionMatchId: before['matchId'] as String?,
      );
    }
    final after = _decodeObject(receipt.afterJson);
    final storedProjection = after['projection'];
    if (storedProjection is Map) {
      return _projectionFromJson(storedProjection.cast<String, Object?>());
    }
    // Receipts written by the pre-projection kernel remain readable. They do
    // not have an immutable result, so use the current committed projection
    // only as a compatibility fallback for those legacy rows.
    return _projection(command.matchId);
  }

  Future<MatchDetail> _writeReceipt(MatchCommand command) async {
    final projection = await _projectionInTransaction(command.matchId);
    if (projection == null) {
      throw StateError('Command committed without a readable projection.');
    }
    await _database
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
              'projection': _projectionJson(projection),
            }),
            reason: const Value.absent(),
            createdAt: _now().toUtc(),
          ),
        );
    return projection;
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

  Future<ShotLocation?> _shotLocationForEvent(String eventId) {
    final query = _database.select(_database.shotLocations)
      ..where((row) => row.eventId.equals(eventId));
    return query.getSingleOrNull();
  }

  Future<PlayerRow?> _playerRow(String id) {
    final query = _database.select(_database.players)
      ..where((row) => row.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<MatchDetail?> _projection(String matchId) {
    return _projectionInTransaction(matchId);
  }

  Future<MatchDetail?> _projectionInTransaction(String matchId) async {
    final match = await _matchRow(matchId);
    if (match == null) return null;
    final events =
        await (_database.select(_database.matchEvents)
              ..where((event) => event.matchId.equals(matchId))
              ..orderBy([(event) => OrderingTerm.asc(event.occurredAt)]))
            .get();
    final locations = await (_database.select(
      _database.shotLocations,
    )..where((location) => location.matchId.equals(matchId))).get();
    final participants = await (_database.select(
      _database.matchParticipants,
    )..where((participant) => participant.matchId.equals(matchId))).get();
    final detail = MatchRepository.buildDetail(
      match,
      events,
      locations,
      participantRows: participants,
    );
    final clockRow = await _clockRow(matchId);
    final clock = clockRow == null
        ? null
        : ClockEngine().project(
            state: _clockState(clockRow),
            now: _now().toUtc(),
          );
    final decision =
        _decisionFromLabel(
          await _latestDecisionLabel(matchId),
          redScore: detail.redScore,
          blueScore: detail.blueScore,
        ) ??
        (clock?.phase == ClockPhase.regulationExpired
            ? _decisionForScores(
                reason: MatchDecisionReason.regulationExpired,
                detail: detail,
              )
            : null);
    return detail.copyWith(
      clock: clock,
      decision: decision,
      warnings: _warningsFor(detail),
    );
  }

  Future<MatchClock?> _clockRow(String matchId) {
    final query = _database.select(_database.matchClocks)
      ..where((clock) => clock.matchId.equals(matchId));
    return query.getSingleOrNull();
  }

  ClockState _clockState(MatchClock row) {
    return ClockState(
      id: row.id,
      matchId: row.matchId,
      mode: ClockMode.values.byName(row.mode),
      phase: ClockPhase.values.byName(row.phase),
      accumulatedSeconds: row.accumulatedSeconds,
      runningSinceUtc: row.runningSinceUtc?.toUtc(),
      regulationSeconds: row.regulationSeconds,
    );
  }

  Future<void> _updateClock(ClockState state) {
    return (_database.update(
      _database.matchClocks,
    )..where((clock) => clock.id.equals(state.id))).write(
      MatchClocksCompanion(
        phase: Value(state.phase.name),
        accumulatedSeconds: Value(state.accumulatedSeconds),
        runningSinceUtc: Value(state.runningSinceUtc),
      ),
    );
  }

  Future<void> _persistClockProjection(ClockProjection projection) {
    return _updateClock(projection.normalizedState);
  }

  Future<String?> _latestSemanticLabel(String matchId) async {
    final rows =
        await (_database.select(_database.matchEvents)
              ..where(
                (event) =>
                    event.matchId.equals(matchId) &
                    event.type.equals(EventKind.pause.name) &
                    event.isDeleted.equals(false),
              )
              ..orderBy([
                (_) => OrderingTerm.desc(const CustomExpression<int>('rowid')),
              ]))
            .get();
    return rows.isEmpty ? null : rows.first.customLabel;
  }

  Future<String?> _latestDecisionLabel(String matchId) async {
    final latest = await _latestSemanticLabel(matchId);
    return latest != null && latest.startsWith('decision:') ? latest : null;
  }

  Future<void> _guardInputClock(MatchCommand command) async {
    final row = await _clockRow(command.matchId);
    if (row == null) return;
    final clock = ClockEngine().project(
      state: _clockState(row),
      now: _now().toUtc(),
    );
    if (clock.requiresPersistence) {
      await _persistClockProjection(clock);
    }
    final detail = await _projectionInTransaction(command.matchId);
    final decision = detail?.decision;
    if (decision != null) {
      throw EndConditionFailure(
        command: command,
        decision: decision,
        projectionMatchId: command.matchId,
      );
    }
  }

  Future<void> _guardEventMutation(
    MatchCommand command,
    MatchEventRow event,
  ) async {
    if (event.type == EventKind.pause.name && event.customLabel != null) {
      throw CommandValidationFailure(
        command: command,
        message: 'System semantic events cannot be corrected or undone.',
        projectionMatchId: command.matchId,
      );
    }
    final detail = await _projectionInTransaction(command.matchId);
    final decision = detail?.decision;
    if (decision != null) {
      throw EndConditionFailure(
        command: command,
        decision: decision,
        projectionMatchId: command.matchId,
      );
    }
  }

  Future<MatchCommandFailure?> _preflightRecord(
    RecordMatchEventCommand command,
  ) async {
    final row = await _clockRow(command.matchId);
    if (row == null) return null;
    final projection = ClockEngine().project(
      state: _clockState(row),
      now: _now().toUtc(),
    );
    if (projection.requiresPersistence) {
      await _database.transaction(() => _persistClockProjection(projection));
    }
    if (projection.recoveryReason != null) {
      return ClockRecoveryFailure(
        command: command,
        recoveryMessage:
            projection.recoveryMessage ??
            'The clock was paused because the device clock moved backward.',
        projectionMatchId: command.matchId,
      );
    }
    final detail = await _projection(command.matchId);
    final decision = detail?.decision;
    if (decision != null) {
      return EndConditionFailure(
        command: command,
        decision: decision,
        projectionMatchId: command.matchId,
      );
    }
    return null;
  }

  Future<MatchCommandFailure?> _preflightSemantic(
    MatchCommand command, {
    required String label,
  }) async {
    if (await _receipt(command.commandId) != null) return null;
    final row = await _clockRow(command.matchId);
    if (row == null) return null;
    final projection = ClockEngine().project(
      state: _clockState(row),
      now: _now().toUtc(),
    );
    if (projection.requiresPersistence) {
      await _database.transaction(() => _persistClockProjection(projection));
    }
    if (projection.recoveryReason != null) {
      return ClockRecoveryFailure(
        command: command,
        recoveryMessage:
            projection.recoveryMessage ??
            'The clock was paused because the device clock moved backward.',
        projectionMatchId: command.matchId,
      );
    }
    final detail = await _projection(command.matchId);
    final decision = detail?.decision;
    if (decision != null) {
      return EndConditionFailure(
        command: command,
        decision: decision,
        projectionMatchId: command.matchId,
      );
    }
    if (label == 'resume' && projection.recoveryReason != null) {
      return ClockRecoveryFailure(
        command: command,
        recoveryMessage:
            projection.recoveryMessage ??
            'The clock was paused because the device clock moved backward.',
        projectionMatchId: command.matchId,
      );
    }
    return null;
  }

  Future<void> _applyPostEventRules(RecordMatchEventCommand command) {
    return _applyPostScoreRules(
      command.matchId,
      scoreChanged: _isMadeScore(command),
      decisionEventId: '${command.commandId}:decision',
    );
  }

  Future<void> _applyPostScoreRules(
    String matchId, {
    required bool scoreChanged,
    required String decisionEventId,
  }) async {
    final detail = await _projectionInTransaction(matchId);
    if (detail == null) return;
    final row = await _clockRow(matchId);
    if (row == null) return;
    final beforeClock = _clockState(row);
    final now = _now().toUtc();
    final clock = ClockEngine().project(state: _clockState(row), now: now);
    if (clock.requiresPersistence) {
      await _persistClockProjection(clock);
    }

    MatchDecisionReason? reason;
    if (clock.phase == ClockPhase.regulationExpired) {
      reason = MatchDecisionReason.regulationExpired;
    } else if (scoreChanged) {
      final template = detail.match.ruleTemplateSnapshot;
      final target = template.targetScore;
      if (target != null) {
        final leading = detail.redScore >= detail.blueScore
            ? detail.redScore
            : detail.blueScore;
        final trailing = detail.redScore < detail.blueScore
            ? detail.redScore
            : detail.blueScore;
        if (leading >= target) {
          reason = template.winByTwo && leading - trailing < 2
              ? MatchDecisionReason.winByTwoRequired
              : MatchDecisionReason.targetReached;
        }
      }
    }
    if (reason == null) return;

    final existingDecision = await _latestDecisionLabel(matchId);
    if (existingDecision != null) return;
    final nextClock = clock.normalizedState.copyWith(runningSinceUtc: null);
    await _updateClock(nextClock);
    await _writeAudit(
      id: _newUuid(),
      matchId: matchId,
      targetId: row.id,
      action: 'edit',
      before: _clockJson(beforeClock),
      after: _clockJson(nextClock),
      reason: 'decision-clock',
    );
    await _database
        .into(_database.matchEvents)
        .insert(
          MatchEventsCompanion.insert(
            id: decisionEventId,
            matchId: matchId,
            type: EventKind.pause.name,
            points: const Value(0),
            occurredAt: now,
            customLabel: Value('decision:${reason.name}'),
          ),
        );
  }

  static bool _scoresChanged(MatchDetail? before, MatchDetail? after) {
    if (before == null || after == null) return false;
    return before.redScore != after.redScore ||
        before.blueScore != after.blueScore;
  }

  static bool _isMadeScore(RecordMatchEventCommand command) {
    if (command.type == EventKind.score) return command.points > 0;
    return (command.type == EventKind.fieldGoal ||
            command.type == EventKind.freeThrow) &&
        command.outcome == ShotOutcome.made &&
        command.points > 0;
  }

  MatchDecision? _decisionFromLabel(
    String? label, {
    required int redScore,
    required int blueScore,
  }) {
    if (label == null || !label.startsWith('decision:')) return null;
    final reasonName = label.substring('decision:'.length);
    MatchDecisionReason? reason;
    for (final value in MatchDecisionReason.values) {
      if (value.name == reasonName) {
        reason = value;
        break;
      }
    }
    return reason == null
        ? null
        : _decisionForScores(
            reason: reason,
            redScore: redScore,
            blueScore: blueScore,
          );
  }

  MatchDecision _decisionForScores({
    required MatchDecisionReason reason,
    MatchDetail? detail,
    int? redScore,
    int? blueScore,
  }) {
    final resolvedRed = redScore ?? detail?.redScore ?? 0;
    final resolvedBlue = blueScore ?? detail?.blueScore ?? 0;
    final message = switch (reason) {
      MatchDecisionReason.targetReached =>
        'Target score reached. Finish or continue?',
      MatchDecisionReason.winByTwoRequired =>
        'Target reached, but a two-point lead is required. Continue?',
      MatchDecisionReason.regulationExpired =>
        'Regulation time expired. Finish or continue in overtime?',
    };
    return MatchDecision(
      kind: MatchDecisionKind.finishOrContinue,
      reason: reason,
      redScore: resolvedRed,
      blueScore: resolvedBlue,
      canFinish: reason != MatchDecisionReason.winByTwoRequired,
      message: message,
    );
  }

  List<MatchRuleWarning> _warningsFor(MatchDetail detail) {
    final limit = detail.match.ruleTemplateSnapshot.foulLimit;
    if (limit == null || limit <= 0) return const <MatchRuleWarning>[];
    final warnings = <MatchRuleWarning>[];
    if (detail.redFouls >= limit) {
      warnings.add(
        MatchRuleWarning(
          kind: MatchWarningKind.foulLimit,
          side: TeamSide.red,
          count: detail.redFouls,
          limit: limit,
          message: 'Red foul limit reached.',
        ),
      );
    }
    if (detail.blueFouls >= limit) {
      warnings.add(
        MatchRuleWarning(
          kind: MatchWarningKind.foulLimit,
          side: TeamSide.blue,
          count: detail.blueFouls,
          limit: limit,
          message: 'Blue foul limit reached.',
        ),
      );
    }
    return List.unmodifiable(warnings);
  }

  static Map<String, Object?> _clockJson(ClockState state) => <String, Object?>{
    'id': state.id,
    'matchId': state.matchId,
    'mode': state.mode.name,
    'phase': state.phase.name,
    'accumulatedSeconds': state.accumulatedSeconds,
    'runningSinceUtc': state.runningSinceUtc?.toUtc().toIso8601String(),
    'regulationSeconds': state.regulationSeconds,
  };

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
    if (command.type == EventKind.score &&
        command.outcome != null &&
        command.outcome != ShotOutcome.made) {
      throw CommandValidationFailure(
        command: command,
        message: 'Score events must have a made outcome.',
        projectionMatchId: command.matchId,
      );
    }
    if (command.shotLocation != null) {
      if (command.type != EventKind.fieldGoal) {
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

Map<String, Object?> _projectionJson(MatchDetail detail) {
  return <String, Object?>{
    'match': <String, Object?>{
      'id': detail.match.id,
      'createdAt': detail.match.createdAt.toUtc().toIso8601String(),
      'startedAt': detail.match.startedAt?.toUtc().toIso8601String(),
      'endedAt': detail.match.endedAt?.toUtc().toIso8601String(),
      'lifecycle': detail.match.lifecycle.name,
      'recordingMode': detail.match.recordingMode.name,
      'trackingCoverage': detail.match.trackingCoverage.name,
      'timerEnabled': detail.match.timerEnabled,
      'note': detail.match.note,
      'ruleTemplate': _ruleTemplateJson(detail.match.ruleTemplateSnapshot),
      'participants': [
        for (final participant in detail.match.participants)
          <String, Object?>{
            'id': participant.id,
            'matchId': participant.matchId,
            'side': participant.side.name,
            'nameSnapshot': participant.nameSnapshot,
            'playerProfileId': participant.playerProfileId,
          },
      ],
    },
    'events': detail.events
        .map(MatchCommandService._eventJsonFromEvent)
        .toList(),
    'shotLocations': [
      for (final location in detail.shotLocations)
        <String, Object?>{
          'id': location.id,
          'matchId': location.matchId,
          'eventId': location.eventId,
          'x': location.point.x,
          'y': location.point.y,
          'isConfirmed': location.isConfirmed,
        },
    ],
    'redScore': detail.redScore,
    'blueScore': detail.blueScore,
    'redFouls': detail.redFouls,
    'blueFouls': detail.blueFouls,
    'shotAttemptCount': detail.shotAttemptCount,
    'locatedShotCount': detail.locatedShotCount,
    if (detail.clock != null)
      'clock': <String, Object?>{
        ...MatchCommandService._clockJson(detail.clock!.normalizedState),
        'elapsedSeconds': detail.clock!.elapsedSeconds,
        'displaySeconds': detail.clock!.displaySeconds,
        'remainingSeconds': detail.clock!.remainingSeconds,
        'recoveryReason': detail.clock!.recoveryReason?.name,
        'recoveryMessage': detail.clock!.recoveryMessage,
        'requiresPersistence': detail.clock!.requiresPersistence,
        'nowUtc': detail.clock!.nowUtc.toUtc().toIso8601String(),
      },
    if (detail.decision != null)
      'decision': <String, Object?>{
        'kind': detail.decision!.kind.name,
        'reason': detail.decision!.reason.name,
        'redScore': detail.decision!.redScore,
        'blueScore': detail.decision!.blueScore,
        'canFinish': detail.decision!.canFinish,
        'canContinue': detail.decision!.canContinue,
        'message': detail.decision!.message,
      },
    'warnings': [
      for (final warning in detail.warnings)
        <String, Object?>{
          'kind': warning.kind.name,
          'side': warning.side.name,
          'count': warning.count,
          'limit': warning.limit,
          'message': warning.message,
        },
    ],
  };
}

MatchDetail _projectionFromJson(Map<String, Object?> json) {
  final matchJson = (json['match'] as Map).cast<String, Object?>();
  final participantJson =
      (matchJson['participants'] as List<Object?>?) ?? const <Object?>[];
  final participants = participantJson
      .map((raw) {
        final value = (raw as Map).cast<String, Object?>();
        return domain_match.MatchParticipant(
          id: value['id'] as String,
          matchId: value['matchId'] as String,
          side: TeamSide.values.byName(value['side'] as String),
          nameSnapshot: value['nameSnapshot'] as String,
          playerProfileId: value['playerProfileId'] as String?,
        );
      })
      .toList(growable: false);
  final ruleJson = (matchJson['ruleTemplate'] as Map).cast<String, Object?>();
  final match = domain_match.Match(
    id: matchJson['id'] as String,
    createdAt: DateTime.parse(matchJson['createdAt'] as String).toUtc(),
    startedAt: _dateFromJson(matchJson['startedAt']),
    endedAt: _dateFromJson(matchJson['endedAt']),
    lifecycle: MatchLifecycle.values.byName(matchJson['lifecycle'] as String),
    participants: participants,
    recordingMode: RecordingMode.values.byName(
      matchJson['recordingMode'] as String,
    ),
    trackingCoverage: TrackingCoverage.values.byName(
      matchJson['trackingCoverage'] as String,
    ),
    ruleTemplateSnapshot: _ruleTemplateFromMap(ruleJson),
    timerEnabled: matchJson['timerEnabled'] as bool? ?? false,
    note: matchJson['note'] as String?,
  );

  final eventJson = (json['events'] as List<Object?>?) ?? const <Object?>[];
  final events = eventJson
      .map((raw) {
        final value = (raw as Map).cast<String, Object?>();
        return MatchEvent(
          id: value['id'] as String,
          matchId: value['matchId'] as String,
          type: EventKind.values.byName(value['type'] as String),
          side: value['side'] == null
              ? null
              : TeamSide.values.byName(value['side'] as String),
          points: (value['points'] as num).toInt(),
          occurredAt: DateTime.parse(value['occurredAt'] as String).toUtc(),
          note: value['note'] as String?,
          customLabel: value['customLabel'] as String?,
          outcome: value['outcome'] == null
              ? null
              : ShotOutcome.values.byName(value['outcome'] as String),
          matchClockPositionSeconds:
              (value['matchClockPositionSeconds'] as num?)?.toInt(),
          isDeleted: value['isDeleted'] as bool? ?? false,
        );
      })
      .toList(growable: false);

  final locationJson =
      (json['shotLocations'] as List<Object?>?) ?? const <Object?>[];
  final locations = locationJson
      .map((raw) {
        final value = (raw as Map).cast<String, Object?>();
        return domain.ShotLocation(
          id: value['id'] as String,
          matchId: value['matchId'] as String,
          eventId: value['eventId'] as String,
          point: CourtPoint(
            x: (value['x'] as num).toDouble(),
            y: (value['y'] as num).toDouble(),
          ),
          isConfirmed: value['isConfirmed'] as bool,
        );
      })
      .toList(growable: false);

  ClockProjection? clock;
  final clockJson = json['clock'];
  if (clockJson is Map) {
    final value = clockJson.cast<String, Object?>();
    final normalizedState = ClockState(
      id: value['id'] as String,
      matchId: value['matchId'] as String,
      mode: ClockMode.values.byName(value['mode'] as String),
      phase: ClockPhase.values.byName(value['phase'] as String),
      accumulatedSeconds: (value['accumulatedSeconds'] as num).toInt(),
      runningSinceUtc: _dateFromJson(value['runningSinceUtc']),
      regulationSeconds: (value['regulationSeconds'] as num?)?.toInt(),
    );
    final recoveryName = value['recoveryReason'] as String?;
    clock = ClockProjection(
      state: normalizedState,
      normalizedState: normalizedState,
      nowUtc: DateTime.parse(value['nowUtc'] as String).toUtc(),
      elapsedSeconds: (value['elapsedSeconds'] as num).toInt(),
      displaySeconds: (value['displaySeconds'] as num).toInt(),
      phase: ClockPhase.values.byName(value['phase'] as String),
      remainingSeconds: (value['remainingSeconds'] as num?)?.toInt(),
      recoveryReason: recoveryName == null
          ? null
          : ClockRecoveryReason.values.byName(recoveryName),
      recoveryMessage: value['recoveryMessage'] as String?,
      requiresPersistence: value['requiresPersistence'] as bool? ?? false,
    );
  }
  MatchDecision? decision;
  final decisionJson = json['decision'];
  if (decisionJson is Map) {
    final value = decisionJson.cast<String, Object?>();
    decision = MatchDecision(
      kind: MatchDecisionKind.values.byName(value['kind'] as String),
      reason: MatchDecisionReason.values.byName(value['reason'] as String),
      redScore: (value['redScore'] as num).toInt(),
      blueScore: (value['blueScore'] as num).toInt(),
      canFinish: value['canFinish'] as bool? ?? true,
      canContinue: value['canContinue'] as bool? ?? true,
      message: value['message'] as String? ?? '',
    );
  }
  final warningJson = (json['warnings'] as List<Object?>?) ?? const [];
  final warnings = warningJson
      .map((raw) {
        final value = (raw as Map).cast<String, Object?>();
        return MatchRuleWarning(
          kind: MatchWarningKind.values.byName(value['kind'] as String),
          side: TeamSide.values.byName(value['side'] as String),
          count: (value['count'] as num).toInt(),
          limit: (value['limit'] as num).toInt(),
          message: value['message'] as String? ?? '',
        );
      })
      .toList(growable: false);

  return MatchDetail(
    match: match,
    events: List.unmodifiable(events),
    shotLocations: List.unmodifiable(locations),
    redScore: (json['redScore'] as num).toInt(),
    blueScore: (json['blueScore'] as num).toInt(),
    redFouls: (json['redFouls'] as num).toInt(),
    blueFouls: (json['blueFouls'] as num).toInt(),
    shotAttemptCount: (json['shotAttemptCount'] as num).toInt(),
    locatedShotCount: (json['locatedShotCount'] as num).toInt(),
    clock: clock,
    decision: decision,
    warnings: List.unmodifiable(warnings),
  );
}

DateTime? _dateFromJson(Object? value) {
  return value == null ? null : DateTime.parse(value as String).toUtc();
}

RuleTemplate _ruleTemplateFromMap(Map<String, Object?> json) {
  return RuleTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    scoreButtons: ((json['scoreButtons'] as List<Object?>?) ?? const [])
        .map((value) => (value as num).toInt())
        .toList(growable: false),
    targetScore: (json['targetScore'] as num?)?.toInt(),
    timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
    winByTwo: json['winByTwo'] as bool? ?? false,
    foulLimit: (json['foulLimit'] as num?)?.toInt(),
    possessionHintEnabled: json['possessionHintEnabled'] as bool? ?? false,
    possessionPolicy: json['possessionPolicy'] == null
        ? PossessionPolicy.manual
        : PossessionPolicy.values.byName(json['possessionPolicy'] as String),
    customEventTypes: ((json['customEventTypes'] as List<Object?>?) ?? const [])
        .cast<String>(),
  );
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

RuleTemplate _copyRuleTemplate(RuleTemplate template) {
  return RuleTemplate(
    id: template.id,
    name: template.name,
    scoreButtons: List.unmodifiable(template.scoreButtons),
    targetScore: template.targetScore,
    timeLimitSeconds: template.timeLimitSeconds,
    winByTwo: template.winByTwo,
    foulLimit: template.foulLimit,
    possessionHintEnabled: template.possessionHintEnabled,
    possessionPolicy: template.possessionPolicy,
    customEventTypes: List.unmodifiable(template.customEventTypes),
  );
}

String _fingerprint(Map<String, Object?> payload) =>
    sha256.convert(utf8.encode(jsonEncode(payload))).toString();

String _newUuid() => const Uuid().v4();
