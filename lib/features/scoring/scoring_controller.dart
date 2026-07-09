import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
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
  final PendingShotLocation? pendingLocation;
  final int redFouls;
  final int blueFouls;
  final List<String> ruleHints;

  MatchScoringState copyWith({
    List<MatchEvent>? events,
    ScoreState? score,
    List<ScoringShotLocation>? shotLocations,
    PendingShotLocation? pendingLocation,
    bool clearPendingLocation = false,
    int? redFouls,
    int? blueFouls,
    List<String>? ruleHints,
  }) {
    return MatchScoringState(
      matchId: matchId,
      redName: redName,
      blueName: blueName,
      events: events ?? this.events,
      score: score ?? this.score,
      shotLocations: shotLocations ?? this.shotLocations,
      pendingLocation:
          clearPendingLocation ? null : pendingLocation ?? this.pendingLocation,
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
  }) : _state = MatchScoringState(
          matchId: setup?.matchId ?? matchId ?? 'match-local',
          redName: setup?.redName ?? defaultRedPlayerName,
          blueName: setup?.blueName ?? defaultBluePlayerName,
          events: const [],
          score: const ScoreState.zero(),
          shotLocations: const [],
        );

  final ScoringReducer _reducer = ScoringReducer();
  MatchScoringState _state;

  MatchScoringState get state => _state;

  void addScore({required TeamSide side, required int points}) {
    final eventId = 'event-${_state.events.length + 1}';
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
      ruleHints: const [],
    );
    notifyListeners();
  }

  void updatePendingLocation(CourtPoint point) {
    final pending = _state.pendingLocation;
    if (pending == null) {
      return;
    }
    _state = _state.copyWith(pendingLocation: pending.copyWith(point: point));
    notifyListeners();
  }

  void confirmPendingLocation([CourtPoint? point]) {
    final pending = _state.pendingLocation;
    if (pending == null) {
      return;
    }
    final confirmedPoint = point ?? pending.point;
    final marker = ScoringShotLocation(
      id: 'shot-${_state.shotLocations.length + 1}',
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
    _state = _state.copyWith(
      events: events,
      score: _reducer.reduce(events),
      shotLocations: locations,
      clearPendingLocation: true,
    );
    notifyListeners();
  }

  void addFoul(TeamSide side) {
    _state = _state.copyWith(
      redFouls: side == TeamSide.red ? _state.redFouls + 1 : null,
      blueFouls: side == TeamSide.blue ? _state.blueFouls + 1 : null,
    );
    notifyListeners();
  }
}
