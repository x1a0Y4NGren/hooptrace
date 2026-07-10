import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/domain/entities/match.dart';
import 'package:hooptrace/core/domain/entities/shot_location.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

class MatchSessionCoordinator extends ChangeNotifier {
  MatchSessionCoordinator(this._repository);

  final MatchRepository _repository;
  final Map<String, _ActiveSession> _sessions = {};
  final Set<String> _finishedMatches = {};

  MatchRepository get repository => _repository;

  ScoringController beginMatch(MatchSetup setup) {
    final existing = _sessions[setup.matchId];
    if (existing != null) {
      return existing.controller;
    }

    final startedAt = DateTime.now();
    final controller = ScoringController(setup: setup);
    final session = _ActiveSession(
      setup: setup,
      startedAt: startedAt,
      controller: controller,
    );
    _sessions[setup.matchId] = session;
    session.writeQueue = _repository.saveMatch(
      Match(
        id: setup.matchId,
        createdAt: startedAt,
        startedAt: startedAt,
        status: MatchStatus.active,
        redName: setup.redName,
        blueName: setup.blueName,
        ruleTemplateSnapshot: controller.state.ruleTemplate,
        timerEnabled: setup.timerEnabled,
      ),
    );
    controller.addListener(() => _scheduleSnapshot(session));
    return controller;
  }

  ScoringController? controllerFor(String matchId) {
    return _sessions[matchId]?.controller;
  }

  bool isActive(String matchId) {
    return _sessions.containsKey(matchId) &&
        !_finishedMatches.contains(matchId);
  }

  Future<void> saveCurrent(String matchId) async {
    final session = _sessions[matchId];
    if (session == null) {
      return;
    }
    _scheduleSnapshot(session);
    await session.writeQueue;
  }

  Future<void> finishMatch(String matchId) async {
    final session = _sessions[matchId];
    if (session != null) {
      _scheduleSnapshot(session);
      await session.writeQueue;
    }
    await _repository.finishMatch(matchId, endedAt: DateTime.now());
    _finishedMatches.add(matchId);
    notifyListeners();
  }

  void _scheduleSnapshot(_ActiveSession session) {
    final state = session.controller.state;
    final locations = [
      for (final location in state.shotLocations)
        ShotLocation(
          id: location.id,
          matchId: state.matchId,
          eventId: location.eventId,
          point: location.point,
          isConfirmed: location.isLocked,
        ),
    ];
    session.writeQueue = session.writeQueue.then(
      (_) => _repository.replaceMatchSnapshot(
        state.matchId,
        events: List.of(state.events),
        shotLocations: locations,
      ),
    );
  }

  @override
  void dispose() {
    for (final session in _sessions.values) {
      session.controller.dispose();
    }
    _sessions.clear();
    _finishedMatches.clear();
    super.dispose();
  }
}

class _ActiveSession {
  _ActiveSession({
    required this.setup,
    required this.startedAt,
    required this.controller,
  });

  final MatchSetup setup;
  final DateTime startedAt;
  final ScoringController controller;
  Future<void> writeQueue = Future.value();
}
