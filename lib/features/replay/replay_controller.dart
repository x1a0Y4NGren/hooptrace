import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

enum ReplayEventKind { score, foul, miss, other }

enum ReplayKindFilter { all, scores, fouls }

enum ReplaySideFilter { all, red, blue }

class ReplayEventData {
  const ReplayEventData({
    required this.id,
    required this.kind,
    required this.side,
    required this.elapsed,
    this.points = 0,
    this.note,
    this.shotPoint,
  });

  final String id;
  final ReplayEventKind kind;
  final TeamSide? side;
  final int points;
  final Duration elapsed;
  final String? note;
  final CourtPoint? shotPoint;
}

class ReplayMatchData {
  ReplayMatchData({
    required this.matchId,
    required this.redName,
    required this.blueName,
    required this.redScore,
    required this.blueScore,
    required this.duration,
    required List<ReplayEventData> events,
    this.isFinished = true,
  }) : events = List.unmodifiable(events);

  final String matchId;
  final String redName;
  final String blueName;
  final int redScore;
  final int blueScore;
  final Duration duration;
  final bool isFinished;
  final List<ReplayEventData> events;
}

class ReplayController extends ChangeNotifier {
  ReplayController({required this.data});

  final ReplayMatchData data;
  ReplayKindFilter _kindFilter = ReplayKindFilter.all;
  ReplaySideFilter _sideFilter = ReplaySideFilter.all;

  ReplayKindFilter get kindFilter => _kindFilter;
  ReplaySideFilter get sideFilter => _sideFilter;

  UnmodifiableListView<ReplayEventData> get visibleEvents {
    return UnmodifiableListView(
      data.events.where(_matchesFilters).toList(growable: false),
    );
  }

  UnmodifiableListView<ScoringShotLocation> get shotLocations {
    final locations = <ScoringShotLocation>[];
    for (final event in data.events) {
      final point = event.shotPoint;
      final side = event.side;
      if (event.kind != ReplayEventKind.score ||
          point == null ||
          side == null) {
        continue;
      }
      locations.add(
        ScoringShotLocation(
          id: 'replay-shot-${event.id}',
          eventId: event.id,
          side: side,
          points: event.points,
          point: point,
          isLocked: true,
        ),
      );
    }
    return UnmodifiableListView(locations);
  }

  int get scoreEventCount =>
      data.events.where((event) => event.kind == ReplayEventKind.score).length;

  int get foulEventCount =>
      data.events.where((event) => event.kind == ReplayEventKind.foul).length;

  int get locatedShotCount => shotLocations.length;

  void setKindFilter(ReplayKindFilter value) {
    if (_kindFilter == value) return;
    _kindFilter = value;
    notifyListeners();
  }

  void setSideFilter(ReplaySideFilter value) {
    if (_sideFilter == value) return;
    _sideFilter = value;
    notifyListeners();
  }

  bool _matchesFilters(ReplayEventData event) {
    final matchesKind = switch (_kindFilter) {
      ReplayKindFilter.all => true,
      ReplayKindFilter.scores => event.kind == ReplayEventKind.score,
      ReplayKindFilter.fouls => event.kind == ReplayEventKind.foul,
    };
    final matchesSide = switch (_sideFilter) {
      ReplaySideFilter.all => true,
      ReplaySideFilter.red => event.side == TeamSide.red,
      ReplaySideFilter.blue => event.side == TeamSide.blue,
    };
    return matchesKind && matchesSide;
  }
}
