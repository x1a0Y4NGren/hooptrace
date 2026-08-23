import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/domain/rules/rule_engine.dart';
import 'package:hooptrace/core/domain/scoring/score_state.dart';
import 'package:hooptrace/core/domain/scoring/scoring_reducer.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';

class PendingShotLocation {
  const PendingShotLocation({
    required this.eventId,
    required this.side,
    required this.points,
    required this.point,
    this.isExplicit = false,
  });

  final String eventId;
  final TeamSide side;
  final int points;
  final CourtPoint point;
  final bool isExplicit;

  PendingShotLocation copyWith({CourtPoint? point}) {
    return PendingShotLocation(
      eventId: eventId,
      side: side,
      points: points,
      point: point ?? this.point,
      isExplicit: isExplicit,
    );
  }
}

class ScoringShotLocation {
  const ScoringShotLocation({
    required this.id,
    required this.eventId,
    required this.side,
    required this.points,
    required this.point,
    required this.isLocked,
  });

  final String id;
  final String eventId;
  final TeamSide side;
  final int points;
  final CourtPoint point;
  final bool isLocked;
}

/// A court-first detailed-mode shot that has not been committed yet.
///
/// This object is deliberately local-only. It is promoted to a persisted
/// [RecordMatchEventCommand] only when [ScoringController.commitDetailedShot]
/// is called.
class DetailedShotDraft {
  const DetailedShotDraft({
    required this.point,
    this.side,
    this.outcome = ShotOutcome.made,
    this.points = 1,
  });

  final CourtPoint point;
  final TeamSide? side;
  final ShotOutcome outcome;
  final int points;

  DetailedShotDraft copyWith({
    CourtPoint? point,
    TeamSide? side,
    ShotOutcome? outcome,
    int? points,
  }) {
    return DetailedShotDraft(
      point: point ?? this.point,
      side: side ?? this.side,
      outcome: outcome ?? this.outcome,
      points: points ?? this.points,
    );
  }
}

class MatchScoringState {
  const MatchScoringState({
    required this.matchId,
    required this.redName,
    required this.blueName,
    required this.events,
    required this.score,
    required this.shotLocations,
    required this.ruleTemplate,
    this.recordingMode = RecordingMode.simple,
    this.trackingCoverage = TrackingCoverage.scoresOnly,
    this.timerEnabled = false,
    this.clock,
    this.currentPossession,
    this.pendingLocation,
    this.detailedShotDraft,
    this.redFouls = 0,
    this.blueFouls = 0,
    this.ruleHints = const [],
  });

  final String matchId;
  final String redName;
  final String blueName;
  final List<MatchEvent> events;
  final ScoreState score;
  final List<ScoringShotLocation> shotLocations;
  final RuleTemplate ruleTemplate;
  final RecordingMode recordingMode;
  final TrackingCoverage trackingCoverage;
  final bool timerEnabled;
  final ClockProjection? clock;
  final TeamSide? currentPossession;
  final PendingShotLocation? pendingLocation;
  final DetailedShotDraft? detailedShotDraft;
  final int redFouls;
  final int blueFouls;
  final List<RuleHint> ruleHints;

  MatchScoringState copyWith({
    List<MatchEvent>? events,
    ScoreState? score,
    List<ScoringShotLocation>? shotLocations,
    RuleTemplate? ruleTemplate,
    RecordingMode? recordingMode,
    TrackingCoverage? trackingCoverage,
    bool? timerEnabled,
    ClockProjection? clock,
    TeamSide? currentPossession,
    PendingShotLocation? pendingLocation,
    DetailedShotDraft? detailedShotDraft,
    bool clearDetailedShotDraft = false,
    bool clearPendingLocation = false,
    int? redFouls,
    int? blueFouls,
    List<RuleHint>? ruleHints,
  }) {
    return MatchScoringState(
      matchId: matchId,
      redName: redName,
      blueName: blueName,
      events: events ?? this.events,
      score: score ?? this.score,
      shotLocations: shotLocations ?? this.shotLocations,
      ruleTemplate: ruleTemplate ?? this.ruleTemplate,
      recordingMode: recordingMode ?? this.recordingMode,
      trackingCoverage: trackingCoverage ?? this.trackingCoverage,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      clock: clock ?? this.clock,
      currentPossession: currentPossession ?? this.currentPossession,
      pendingLocation: clearPendingLocation
          ? null
          : pendingLocation ?? this.pendingLocation,
      detailedShotDraft: clearDetailedShotDraft
          ? null
          : detailedShotDraft ?? this.detailedShotDraft,
      redFouls: redFouls ?? this.redFouls,
      blueFouls: blueFouls ?? this.blueFouls,
      ruleHints: ruleHints ?? this.ruleHints,
    );
  }
}

class ScoringController extends ChangeNotifier {
  ScoringController({
    String? matchId,
    MatchSetup? setup,
    MatchCommandService? commandService,
    MatchDetail? committedProjection,
  }) : _commandService = commandService,
       _state = committedProjection == null
           ? MatchScoringState(
               matchId: setup?.matchId ?? matchId ?? 'match-local',
               redName: setup?.redName ?? defaultRedPlayerName,
               blueName: setup?.blueName ?? defaultBluePlayerName,
               events: const [],
               score: const ScoreState.zero(),
               shotLocations: const [],
               ruleTemplate: _ruleTemplateFromSetup(setup),
               recordingMode: setup?.recordingMode ?? RecordingMode.simple,
               trackingCoverage:
                   setup?.trackingCoverage ?? TrackingCoverage.scoresOnly,
               timerEnabled: setup?.timerEnabled ?? false,
             )
           : _stateFromProjection(committedProjection);

  factory ScoringController.fromCommittedProjection(
    MatchDetail projection,
    MatchCommandService commandService,
  ) {
    return ScoringController(
      commandService: commandService,
      committedProjection: projection,
    );
  }

  final MatchCommandService? _commandService;
  final ScoringReducer _reducer = ScoringReducer();
  final RuleEngine _ruleEngine = RuleEngine();
  MatchScoringState _state;
  final Queue<_QueuedScoringCommand> _commandQueue =
      Queue<_QueuedScoringCommand>();
  bool _drainingQueue = false;
  bool _exclusiveBusy = false;
  bool _disposed = false;

  MatchScoringState get state => _state;

  RecordingMode get recordingMode => _state.recordingMode;

  TrackingCoverage get trackingCoverage => _state.trackingCoverage;

  ClockProjection? get clock => _state.clock;

  TeamSide? get currentPossession => _state.currentPossession;

  bool get timerEnabled => _state.timerEnabled;

  DetailedShotDraft? get detailedShotDraft => _state.detailedShotDraft;

  bool get isCommandBacked => _commandService != null;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  /// Records a fully specified event through the transactional command
  /// boundary. The command object is created before it enters the queue, so
  /// every rapid tap owns a stable command/event ID and can be retried as-is.
  Future<bool> recordEventCommitted(RecordMatchEventCommand command) {
    if (_disposed ||
        command.matchId != _state.matchId ||
        _exclusiveBusy ||
        _state.detailedShotDraft != null ||
        _state.pendingLocation != null) {
      return Future<bool>.value(false);
    }
    if (_isMissCommand(command) && !_allowsShotAttempts) {
      return Future<bool>.value(false);
    }
    if (command.shotLocation != null && !_allowsLocations) {
      return Future<bool>.value(false);
    }
    final service = _commandService;
    if (service == null) {
      return Future<bool>.value(_recordLocalCommand(command));
    }
    return _enqueueCommand(command, () => service.record(command));
  }

  Future<bool> recordScoreCommitted({
    required TeamSide side,
    required int points,
  }) async {
    if (_disposed || _ordinaryActionBlocked) return false;
    if (points <= 0) return false;
    final service = _commandService;
    if (service == null) {
      return addScore(side: side, points: points);
    }
    return recordEventCommitted(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.fieldGoal,
        side: side,
        points: points,
        outcome: ShotOutcome.made,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> recordFieldGoalCommitted({
    required TeamSide side,
    required ShotOutcome outcome,
    int points = 0,
    CourtPoint? location,
  }) {
    if (outcome == ShotOutcome.made && points <= 0) return Future.value(false);
    if (outcome == ShotOutcome.missed && points != 0) {
      return Future.value(false);
    }
    if (outcome == ShotOutcome.notApplicable) return Future.value(false);
    if (outcome == ShotOutcome.missed && !_allowsShotAttempts) {
      return Future.value(false);
    }
    if (location != null && !_allowsLocations) return Future.value(false);
    return recordEventCommitted(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.fieldGoal,
        side: side,
        points: points,
        outcome: outcome,
        occurredAt: DateTime.now().toUtc(),
        shotLocation: location == null
            ? null
            : MatchShotLocationInput(x: location.x, y: location.y),
      ),
    );
  }

  Future<bool> recordMissCommitted({required TeamSide side}) {
    return recordFieldGoalCommitted(side: side, outcome: ShotOutcome.missed);
  }

  Future<bool> recordFreeThrowCommitted({
    required TeamSide side,
    required bool made,
    int points = 1,
  }) {
    if (!made && !_allowsShotAttempts) return Future<bool>.value(false);
    final resolvedPoints = made ? points : 0;
    if (made && resolvedPoints <= 0) return Future<bool>.value(false);
    return recordEventCommitted(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.freeThrow,
        side: side,
        points: resolvedPoints,
        outcome: made ? ShotOutcome.made : ShotOutcome.missed,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> recordPossessionCommitted(TeamSide side, {String? reason}) {
    return recordEventCommitted(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.possession,
        side: side,
        points: 0,
        note: reason,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> recordNoteCommitted(String note) {
    if (note.trim().isEmpty) return Future<bool>.value(false);
    return recordEventCommitted(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.note,
        side: null,
        points: 0,
        note: note,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> recordCustomCommitted({
    required String label,
    TeamSide? side,
    int points = 0,
  }) {
    if (label.trim().isEmpty || points < 0) return Future<bool>.value(false);
    return recordEventCommitted(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.custom,
        side: side,
        points: points,
        customLabel: label,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> recordFoulCommitted(TeamSide side) async {
    if (_disposed || _ordinaryActionBlocked) return false;
    final service = _commandService;
    if (service == null) {
      addFoul(side);
      return true;
    }
    return recordEventCommitted(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.foul,
        side: side,
        points: 0,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<bool> undoLastEventCommitted() async {
    if (_disposed || _state.detailedShotDraft != null) return false;
    final service = _commandService;
    if (service == null) {
      undoLastEvent();
      return true;
    }
    if (_state.events.isEmpty) {
      return false;
    }
    final event = _lastUndoableEvent;
    if (event == null) return false;
    final command = UndoMatchEventCommand(
      matchId: _state.matchId,
      eventId: event.id,
      reason: 'Scoring UI undo',
    );
    return _runExclusive(command, () => service.undo(command));
  }

  bool addScore({required TeamSide side, required int points}) {
    if (_disposed) return false;
    if (isCommandBacked) {
      unawaited(recordScoreCommitted(side: side, points: points));
      return true;
    }
    if (_ordinaryActionBlocked) {
      return false;
    }

    final eventId = '${_state.matchId}-event-${_state.events.length + 1}';
    final hints = _ruleEngine.evaluate(
      template: _state.ruleTemplate,
      score: _state.score,
      scoringSide: side,
      scoringPoints: points,
    );
    final event = MatchEvent.score(
      id: eventId,
      matchId: _state.matchId,
      side: side,
      points: points,
      occurredAt: DateTime.now(),
    );
    final events = [..._state.events, event];
    _state = _state.copyWith(
      events: events,
      score: _reducer.reduce(events),
      pendingLocation: PendingShotLocation(
        eventId: eventId,
        side: side,
        points: points,
        point: CourtPoint(x: 0.5, y: 0.58),
      ),
      ruleHints: hints,
    );
    notifyListeners();
    return true;
  }

  void updatePendingLocation(CourtPoint point) {
    if (_disposed || _exclusiveBusy) return;
    final pending = _state.pendingLocation;
    if (pending == null) {
      return;
    }
    _state = _state.copyWith(pendingLocation: pending.copyWith(point: point));
    notifyListeners();
  }

  Future<void> confirmPendingLocation([CourtPoint? point]) async {
    if (_disposed) return;
    final pending = _state.pendingLocation;
    if (pending == null) {
      return;
    }
    final confirmedPoint = point ?? pending.point;
    final service = _commandService;
    if (service != null) {
      if (_exclusiveBusy || _drainingQueue || _commandQueue.isNotEmpty) return;
      final command = ConfirmShotLocationCommand(
        matchId: _state.matchId,
        eventId: pending.eventId,
        point: confirmedPoint,
      );
      await _runExclusive(command, () => service.confirmShotLocation(command));
      return;
    }
    final marker = ScoringShotLocation(
      id: '${_state.matchId}-shot-${_state.shotLocations.length + 1}',
      eventId: pending.eventId,
      side: pending.side,
      points: pending.points,
      point: confirmedPoint,
      isLocked: true,
    );
    _state = _state.copyWith(
      shotLocations: [..._state.shotLocations, marker],
      clearPendingLocation: true,
    );
    notifyListeners();
  }

  /// Applies the committed projection returned by a retryable command
  /// failure. The original command object is retained by the failure, so a
  /// retry cannot accidentally allocate a second event or receipt.
  Future<bool> retryCommand(MatchCommandFailure failure) async {
    if (_disposed ||
        _exclusiveBusy ||
        _drainingQueue ||
        _commandQueue.isNotEmpty) {
      return false;
    }
    return _runExclusive(failure.command, failure.retry);
  }

  /// Starts an explicit, non-blocking location capture for the latest
  /// unlocated field-goal attempt. Scoring history remains untouched until a
  /// location confirmation command succeeds.
  bool beginLocateLastUnlocatedShot() {
    if (_disposed ||
        _exclusiveBusy ||
        _drainingQueue ||
        _commandQueue.isNotEmpty ||
        !_allowsLocations) {
      return false;
    }
    final candidate = _latestUnlocatedShot;
    if (candidate == null || candidate.side == null) return false;
    _state = _state.copyWith(
      pendingLocation: PendingShotLocation(
        eventId: candidate.id,
        side: candidate.side!,
        points: candidate.points,
        point: CourtPoint(x: 0.5, y: 0.58),
        isExplicit: true,
      ),
    );
    notifyListeners();
    return true;
  }

  bool cancelLocateLastUnlocatedShot() => skipPendingLocation();

  /// Starts a detailed-mode local draft. The current possession is used as
  /// the initial shooter when available, but remains explicitly correctable.
  bool beginDetailedShot(CourtPoint point, {TeamSide? side}) {
    if (_disposed ||
        recordingMode != RecordingMode.detailed ||
        _exclusiveBusy ||
        _drainingQueue ||
        _commandQueue.isNotEmpty ||
        _state.detailedShotDraft != null) {
      return false;
    }
    _state = _state.copyWith(
      detailedShotDraft: DetailedShotDraft(
        point: point,
        side: side ?? currentPossession,
      ),
    );
    notifyListeners();
    return true;
  }

  void updateDetailedShot({
    CourtPoint? point,
    TeamSide? side,
    ShotOutcome? outcome,
    int? points,
  }) {
    if (_disposed || _exclusiveBusy) return;
    final draft = _state.detailedShotDraft;
    if (draft == null) return;
    final nextOutcome = outcome ?? draft.outcome;
    final nextPoints = nextOutcome == ShotOutcome.missed
        ? 0
        : points ?? draft.points;
    _state = _state.copyWith(
      detailedShotDraft: DetailedShotDraft(
        point: point ?? draft.point,
        side: side ?? draft.side,
        outcome: nextOutcome,
        points: nextPoints,
      ),
    );
    notifyListeners();
  }

  Future<bool> commitDetailedShot() async {
    if (_disposed) return false;
    final draft = _state.detailedShotDraft;
    if (draft == null || draft.side == null) return false;
    if (draft.outcome == ShotOutcome.notApplicable) return false;
    if (draft.outcome == ShotOutcome.missed && !_allowsShotAttempts) {
      return false;
    }
    if (_commandService == null) {
      final accepted = _recordLocalCommand(
        RecordMatchEventCommand(
          matchId: _state.matchId,
          type: EventKind.fieldGoal,
          side: draft.side,
          points: draft.outcome == ShotOutcome.missed ? 0 : draft.points,
          outcome: draft.outcome,
          occurredAt: DateTime.now().toUtc(),
          shotLocation: MatchShotLocationInput(
            x: draft.point.x,
            y: draft.point.y,
          ),
        ),
      );
      if (accepted) {
        _state = _state.copyWith(clearDetailedShotDraft: true);
        notifyListeners();
      }
      return accepted;
    }
    if (_exclusiveBusy || _drainingQueue || _commandQueue.isNotEmpty) {
      return false;
    }
    final command = RecordMatchEventCommand(
      matchId: _state.matchId,
      type: EventKind.fieldGoal,
      side: draft.side,
      points: draft.outcome == ShotOutcome.missed ? 0 : draft.points,
      outcome: draft.outcome,
      occurredAt: DateTime.now().toUtc(),
      shotLocation: MatchShotLocationInput(x: draft.point.x, y: draft.point.y),
    );
    final accepted = await _runExclusive(
      command,
      () => _commandService.record(command),
    );
    if (accepted && !_disposed) {
      _state = _state.copyWith(clearDetailedShotDraft: true);
      notifyListeners();
    }
    return accepted;
  }

  bool cancelDetailedShot() {
    if (_disposed || _exclusiveBusy || _state.detailedShotDraft == null) {
      return false;
    }
    _state = _state.copyWith(clearDetailedShotDraft: true);
    notifyListeners();
    return true;
  }

  Future<bool> pauseCommitted() {
    if (_disposed ||
        _state.pendingLocation != null ||
        _state.detailedShotDraft != null) {
      return Future<bool>.value(false);
    }
    final service = _commandService;
    if (service == null) {
      return Future<bool>.value(_recordLocalSemantic('pause'));
    }
    final command = PauseMatchCommand(
      matchId: _state.matchId,
      occurredAt: DateTime.now().toUtc(),
    );
    return _runExclusive(command, () => service.pause(command));
  }

  Future<bool> resumeCommitted() {
    if (_disposed ||
        _state.pendingLocation != null ||
        _state.detailedShotDraft != null) {
      return Future<bool>.value(false);
    }
    final service = _commandService;
    if (service == null) {
      return Future<bool>.value(_recordLocalSemantic('resume'));
    }
    final command = ResumeMatchCommand(
      matchId: _state.matchId,
      occurredAt: DateTime.now().toUtc(),
    );
    return _runExclusive(command, () => service.resume(command));
  }

  Future<bool> pauseClockCommitted() => pauseCommitted();

  Future<bool> resumeClockCommitted() => resumeCommitted();

  bool skipPendingLocation() {
    if (_disposed ||
        _state.pendingLocation == null ||
        _exclusiveBusy ||
        _drainingQueue ||
        _commandQueue.isNotEmpty) {
      return false;
    }
    _state = _state.copyWith(clearPendingLocation: true);
    notifyListeners();
    return true;
  }

  void undoLastEvent() {
    if (_disposed || _state.events.isEmpty) {
      return;
    }
    final lastEvent = _state.events.last;
    final events = _state.events.take(_state.events.length - 1).toList();
    final locations = _state.shotLocations
        .where((location) => location.eventId != lastEvent.id)
        .toList();
    final fouls = _countFouls(events);
    _state = _state.copyWith(
      events: events,
      score: _reducer.reduce(events),
      shotLocations: locations,
      redFouls: fouls.red,
      blueFouls: fouls.blue,
      ruleHints: const [],
      clearPendingLocation: true,
    );
    notifyListeners();
  }

  void addFoul(TeamSide side) {
    if (_disposed || _ordinaryActionBlocked) return;
    if (isCommandBacked) {
      unawaited(recordFoulCommitted(side));
      return;
    }
    final event = MatchEvent(
      id: '${_state.matchId}-event-${_state.events.length + 1}',
      matchId: _state.matchId,
      type: MatchEventType.foul,
      side: side,
      points: 0,
      occurredAt: DateTime.now(),
    );
    final events = [..._state.events, event];
    final fouls = _countFouls(events);
    _state = _state.copyWith(
      events: events,
      redFouls: fouls.red,
      blueFouls: fouls.blue,
    );
    notifyListeners();
  }

  static RuleTemplate _ruleTemplateFromSetup(MatchSetup? setup) {
    return RuleTemplate(
      id: setup?.ruleTemplateId ?? 'free',
      name:
          setup?.ruleTemplateName ??
          switch (setup?.ruleTemplateId) {
            'eleven' || 'eleven_win_by_two' => '11 分制',
            'twenty_one' => '21 分制',
            'timed_ten' => '10 分钟计时',
            _ => '自由计分',
          },
      scoreButtons: setup?.scoreButtons ?? const [1, 2, 3],
      foulLimit: setup?.foulLimit,
      possessionHintEnabled: setup?.possessionHintEnabled ?? false,
      customEventTypes: setup?.customEventTypes ?? const [],
      targetScore: setup?.targetScore,
      timeLimitSeconds: setup?.timerEnabled == true
          ? setup!.timeLimitMinutes * 60
          : null,
      winByTwo: setup?.winByTwo ?? false,
    );
  }

  static MatchScoringState _stateFromProjection(MatchDetail projection) {
    final events = List<MatchEvent>.unmodifiable(projection.events);
    final locations = <ScoringShotLocation>[];
    for (final location in projection.shotLocations) {
      final event = events
          .where((item) => item.id == location.eventId)
          .firstOrNull;
      if (event?.side == null) continue;
      locations.add(
        ScoringShotLocation(
          id: location.id,
          eventId: location.eventId,
          side: event!.side!,
          points: event.points,
          point: location.point,
          isLocked: location.isConfirmed,
        ),
      );
    }
    return MatchScoringState(
      matchId: projection.match.id,
      redName: projection.match.redName,
      blueName: projection.match.blueName,
      events: events,
      score: ScoreState(
        redScore: projection.redScore,
        blueScore: projection.blueScore,
      ),
      shotLocations: List.unmodifiable(locations),
      ruleTemplate: projection.match.ruleTemplateSnapshot,
      recordingMode: projection.match.recordingMode,
      trackingCoverage: projection.match.trackingCoverage,
      timerEnabled: projection.match.timerEnabled,
      clock: projection.clock,
      currentPossession: _latestPossession(events),
      redFouls: projection.redFouls,
      blueFouls: projection.blueFouls,
    );
  }

  void _replaceFromProjection(
    MatchDetail projection, {
    PendingShotLocation? pendingLocation,
  }) {
    if (_disposed) return;
    final previousDraft = _state.detailedShotDraft;
    final previousPending = _state.pendingLocation;
    _state = _stateFromProjection(projection);
    final pending = pendingLocation ?? previousPending;
    if (pending != null &&
        projection.events.any(
          (event) => event.id == pending.eventId && !event.isDeleted,
        ) &&
        !projection.shotLocations.any(
          (location) => location.eventId == pending.eventId,
        )) {
      _state = _state.copyWith(pendingLocation: pending);
    }
    if (previousDraft != null) {
      _state = _state.copyWith(detailedShotDraft: previousDraft);
    }
  }

  /// Replaces the local view with a committed Drift projection received from
  /// the reactive composition root. This intentionally does not issue a
  /// command or retain any database rows in memory.
  void replaceCommittedProjection(MatchDetail projection) {
    if (_disposed) return;
    _replaceFromProjection(projection);
    notifyListeners();
  }

  Future<bool> _enqueueCommand(
    MatchCommand command,
    Future<MatchDetail> Function() operation,
  ) {
    if (_disposed || _exclusiveBusy) return Future<bool>.value(false);
    final completer = Completer<bool>();
    _commandQueue.add(
      _QueuedScoringCommand(
        command: command,
        operation: operation,
        completer: completer,
      ),
    );
    unawaited(_drainCommandQueue());
    return completer.future;
  }

  Future<void> _drainCommandQueue() async {
    if (_drainingQueue) return;
    _drainingQueue = true;
    try {
      while (_commandQueue.isNotEmpty) {
        final queued = _commandQueue.removeFirst();
        if (_disposed) {
          if (!queued.completer.isCompleted) queued.completer.complete(false);
          continue;
        }
        try {
          final projection = await queued.operation();
          if (_disposed) {
            queued.completer.complete(false);
            continue;
          }
          _replaceFromProjection(projection);
          notifyListeners();
          queued.completer.complete(true);
        } on Object catch (error, stackTrace) {
          if (!queued.completer.isCompleted) {
            queued.completer.completeError(error, stackTrace);
          }
        }
      }
    } finally {
      _drainingQueue = false;
    }
  }

  Future<bool> _runExclusive(
    MatchCommand command,
    Future<MatchDetail> Function() operation,
  ) async {
    if (_disposed ||
        _exclusiveBusy ||
        _drainingQueue ||
        _commandQueue.isNotEmpty) {
      return false;
    }
    _exclusiveBusy = true;
    try {
      final projection = await operation();
      if (_disposed) return false;
      _replaceFromProjection(projection);
      notifyListeners();
      return true;
    } finally {
      _exclusiveBusy = false;
    }
  }

  bool _recordLocalCommand(RecordMatchEventCommand command) {
    if (_disposed) return false;
    final event = MatchEvent(
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
    final events = [..._state.events, event];
    final locations = [..._state.shotLocations];
    if (command.shotLocation != null && command.type == EventKind.fieldGoal) {
      locations.add(
        ScoringShotLocation(
          id: command.shotLocationId!,
          eventId: event.id,
          side: command.side!,
          points: event.points,
          point: CourtPoint(
            x: command.shotLocation!.x,
            y: command.shotLocation!.y,
          ),
          isLocked: true,
        ),
      );
    }
    _state = _state.copyWith(
      events: List.unmodifiable(events),
      score: _reducer.reduce(events),
      shotLocations: List.unmodifiable(locations),
      currentPossession: _latestPossession(events),
      redFouls: _countFouls(events).red,
      blueFouls: _countFouls(events).blue,
    );
    notifyListeners();
    return true;
  }

  bool _recordLocalSemantic(String label) {
    return _recordLocalCommand(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.pause,
        side: null,
        points: 0,
        customLabel: label,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
  }

  bool get _allowsShotAttempts =>
      trackingCoverage.index >= TrackingCoverage.shotAttempts.index;

  bool get _allowsLocations =>
      trackingCoverage.index >= TrackingCoverage.locations.index ||
      recordingMode == RecordingMode.detailed;

  bool get _ordinaryActionBlocked =>
      _state.pendingLocation != null || _state.detailedShotDraft != null;

  static bool _isMissCommand(RecordMatchEventCommand command) {
    if (command.type == EventKind.miss) return true;
    return (command.type == EventKind.fieldGoal ||
            command.type == EventKind.freeThrow) &&
        command.outcome == ShotOutcome.missed;
  }

  MatchEvent? get _latestUnlocatedShot {
    final locatedIds = _state.shotLocations.map((item) => item.eventId).toSet();
    for (final event in _state.events.reversed) {
      if (event.isDeleted ||
          event.type != EventKind.fieldGoal ||
          event.side == null ||
          locatedIds.contains(event.id)) {
        continue;
      }
      return event;
    }
    return null;
  }

  MatchEvent? get _lastUndoableEvent {
    for (final event in _state.events.reversed) {
      if (!event.isDeleted) return event;
    }
    return null;
  }

  static TeamSide? _latestPossession(List<MatchEvent> events) {
    for (final event in events.reversed) {
      if (!event.isDeleted &&
          event.type == EventKind.possession &&
          event.side != null) {
        return event.side;
      }
    }
    return null;
  }

  static ({int red, int blue}) _countFouls(List<MatchEvent> events) {
    var red = 0;
    var blue = 0;
    for (final event in events) {
      if (event.isDeleted || event.type != MatchEventType.foul) {
        continue;
      }
      if (event.side == TeamSide.red) {
        red++;
      } else if (event.side == TeamSide.blue) {
        blue++;
      }
    }
    return (red: red, blue: blue);
  }
}

class _QueuedScoringCommand {
  _QueuedScoringCommand({
    required this.command,
    required this.operation,
    required this.completer,
  });

  final MatchCommand command;
  final Future<MatchDetail> Function() operation;
  final Completer<bool> completer;
}
