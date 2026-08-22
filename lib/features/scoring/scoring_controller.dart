import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
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
  });

  final String eventId;
  final TeamSide side;
  final int points;
  final CourtPoint point;

  PendingShotLocation copyWith({CourtPoint? point}) {
    return PendingShotLocation(
      eventId: eventId,
      side: side,
      points: points,
      point: point ?? this.point,
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

class MatchScoringState {
  const MatchScoringState({
    required this.matchId,
    required this.redName,
    required this.blueName,
    required this.events,
    required this.score,
    required this.shotLocations,
    required this.ruleTemplate,
    this.pendingLocation,
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
  final PendingShotLocation? pendingLocation;
  final int redFouls;
  final int blueFouls;
  final List<RuleHint> ruleHints;

  MatchScoringState copyWith({
    List<MatchEvent>? events,
    ScoreState? score,
    List<ScoringShotLocation>? shotLocations,
    RuleTemplate? ruleTemplate,
    PendingShotLocation? pendingLocation,
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
      pendingLocation: clearPendingLocation
          ? null
          : pendingLocation ?? this.pendingLocation,
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

  MatchScoringState get state => _state;

  bool get isCommandBacked => _commandService != null;

  Future<bool> recordScoreCommitted({
    required TeamSide side,
    required int points,
  }) async {
    final service = _commandService;
    if (service == null) {
      return addScore(side: side, points: points);
    }
    if (_state.pendingLocation != null) {
      return false;
    }
    final command = RecordMatchEventCommand(
      matchId: _state.matchId,
      type: EventKind.fieldGoal,
      side: side,
      points: points,
      outcome: ShotOutcome.made,
      occurredAt: DateTime.now().toUtc(),
    );
    final projection = await service.record(command);
    _replaceFromProjection(
      projection,
      pendingLocation: PendingShotLocation(
        eventId: command.eventId,
        side: side,
        points: points,
        point: CourtPoint(x: 0.5, y: 0.58),
      ),
    );
    notifyListeners();
    return true;
  }

  Future<void> recordFoulCommitted(TeamSide side) async {
    final service = _commandService;
    if (service == null) {
      addFoul(side);
      return;
    }
    final projection = await service.record(
      RecordMatchEventCommand(
        matchId: _state.matchId,
        type: EventKind.foul,
        side: side,
        points: 0,
        occurredAt: DateTime.now().toUtc(),
      ),
    );
    _replaceFromProjection(projection);
    notifyListeners();
  }

  Future<void> undoLastEventCommitted() async {
    final service = _commandService;
    if (service == null) {
      undoLastEvent();
      return;
    }
    if (_state.events.isEmpty) return;
    final projection = await service.undo(
      UndoMatchEventCommand(
        matchId: _state.matchId,
        eventId: _state.events.last.id,
        reason: 'Scoring UI undo',
      ),
    );
    _replaceFromProjection(projection);
    notifyListeners();
  }

  bool addScore({required TeamSide side, required int points}) {
    if (isCommandBacked) {
      unawaited(recordScoreCommitted(side: side, points: points));
      return true;
    }
    if (_state.pendingLocation != null) {
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
    final pending = _state.pendingLocation;
    if (pending == null) {
      return;
    }
    _state = _state.copyWith(pendingLocation: pending.copyWith(point: point));
    notifyListeners();
  }

  Future<void> confirmPendingLocation([CourtPoint? point]) async {
    final pending = _state.pendingLocation;
    if (pending == null) {
      return;
    }
    final confirmedPoint = point ?? pending.point;
    final service = _commandService;
    if (service != null) {
      final projection = await service.confirmShotLocation(
        ConfirmShotLocationCommand(
          matchId: _state.matchId,
          eventId: pending.eventId,
          point: confirmedPoint,
        ),
      );
      _replaceFromProjection(projection);
      notifyListeners();
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

  void skipPendingLocation() {
    if (_state.pendingLocation == null) {
      return;
    }
    _state = _state.copyWith(clearPendingLocation: true);
    notifyListeners();
  }

  void undoLastEvent() {
    if (_state.events.isEmpty) {
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
      redFouls: projection.redFouls,
      blueFouls: projection.blueFouls,
    );
  }

  void _replaceFromProjection(
    MatchDetail projection, {
    PendingShotLocation? pendingLocation,
  }) {
    _state = _stateFromProjection(projection);
    if (pendingLocation != null) {
      _state = _state.copyWith(pendingLocation: pendingLocation);
    }
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
