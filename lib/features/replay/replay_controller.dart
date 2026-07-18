import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hooptrace/core/audit/audit_log_entry.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
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
    this.locationId,
    this.shotPoint,
  });

  final String id;
  final ReplayEventKind kind;
  final TeamSide? side;
  final int points;
  final Duration elapsed;
  final String? note;
  final String? locationId;
  final CourtPoint? shotPoint;

  ReplayEventData copyWith({String? note, CourtPoint? shotPoint}) {
    return ReplayEventData(
      id: id,
      kind: kind,
      side: side,
      elapsed: elapsed,
      points: points,
      note: note ?? this.note,
      locationId: locationId,
      shotPoint: shotPoint ?? this.shotPoint,
    );
  }
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
    this.analytics,
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
  final MatchAnalytics? analytics;
}

class ReplayController extends ChangeNotifier {
  ReplayController({
    required ReplayMatchData data,
    this.onMoveShotLocation,
    this.onSoftDeleteEvent,
    this.onUpdateEventNote,
    this.loadAuditLogs,
  }) : _data = data;

  ReplayMatchData _data;
  final Future<void> Function(
    String locationId,
    CourtPoint point,
    String? reason,
  )? onMoveShotLocation;
  final Future<void> Function(String eventId, String? reason)?
      onSoftDeleteEvent;
  final Future<void> Function(String eventId, String note, String? reason)?
      onUpdateEventNote;
  final Future<List<AuditLogEntry>> Function()? loadAuditLogs;
  ReplayKindFilter _kindFilter = ReplayKindFilter.all;
  ReplaySideFilter _sideFilter = ReplaySideFilter.all;
  bool _isEditing = false;
  String? _selectedEventId;
  CourtPoint? _pendingShotPoint;

  ReplayMatchData get data => _data;
  ReplayKindFilter get kindFilter => _kindFilter;
  ReplaySideFilter get sideFilter => _sideFilter;
  bool get isEditing => _isEditing;
  bool get canEdit =>
      onMoveShotLocation != null ||
      onSoftDeleteEvent != null ||
      onUpdateEventNote != null;
  String? get selectedEventId => _selectedEventId;
  ReplayEventData? get selectedEvent {
    final id = _selectedEventId;
    if (id == null) return null;
    return _data.events.where((event) => event.id == id).firstOrNull;
  }

  PendingShotLocation? get pendingShotLocation {
    final event = selectedEvent;
    final point = _pendingShotPoint;
    if (!_isEditing || event == null || point == null || event.side == null) {
      return null;
    }
    return PendingShotLocation(
      eventId: event.id,
      side: event.side!,
      points: event.points,
      point: point,
    );
  }

  UnmodifiableListView<ReplayEventData> get visibleEvents {
    return UnmodifiableListView(
      data.events.where(_matchesFilters).toList(growable: false),
    );
  }

  UnmodifiableListView<ScoringShotLocation> get shotLocations {
    final locations = <ScoringShotLocation>[];
    for (final event in _data.events) {
      final point = event.shotPoint;
      final side = event.side;
      if (event.kind != ReplayEventKind.score ||
          point == null ||
          side == null) {
        continue;
      }
      locations.add(
        ScoringShotLocation(
          id: event.locationId ?? 'replay-shot-${event.id}',
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
      _data.events.where((event) => event.kind == ReplayEventKind.score).length;

  int get foulEventCount =>
      _data.events.where((event) => event.kind == ReplayEventKind.foul).length;

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

  void setEditing(bool value) {
    if (value && !canEdit) return;
    if (_isEditing == value) return;
    _isEditing = value;
    if (!value) clearSelection(notify: false);
    notifyListeners();
  }

  void selectEvent(String eventId) {
    if (!_isEditing || !_data.events.any((event) => event.id == eventId)) {
      return;
    }
    _selectedEventId = eventId;
    _pendingShotPoint = selectedEvent?.shotPoint;
    notifyListeners();
  }

  void selectLocation(String locationId) {
    if (!_isEditing) return;
    final event =
        _data.events.where((item) => item.locationId == locationId).firstOrNull;
    if (event != null) selectEvent(event.id);
  }

  void updatePendingShotPoint(CourtPoint point) {
    if (!_isEditing || selectedEvent?.locationId == null) return;
    _pendingShotPoint = point;
    notifyListeners();
  }

  void clearSelection({bool notify = true}) {
    _selectedEventId = null;
    _pendingShotPoint = null;
    if (notify) notifyListeners();
  }

  Future<void> saveSelectedShot({String? reason}) async {
    final event = selectedEvent;
    final point = _pendingShotPoint;
    final locationId = event?.locationId;
    if (locationId == null || point == null || onMoveShotLocation == null) {
      return;
    }
    await onMoveShotLocation!(locationId, point, reason);
  }

  Future<void> updateSelectedNote(String note, {String? reason}) async {
    final eventId = _selectedEventId;
    if (eventId == null || onUpdateEventNote == null) return;
    await onUpdateEventNote!(eventId, note, reason);
  }

  Future<void> deleteSelectedEvent({String? reason}) async {
    final eventId = _selectedEventId;
    if (eventId == null || onSoftDeleteEvent == null) return;
    await onSoftDeleteEvent!(eventId, reason);
    clearSelection(notify: false);
  }

  void replaceData(ReplayMatchData data) {
    _data = data;
    final selected = selectedEvent;
    if (selected == null) {
      clearSelection(notify: false);
    } else {
      _pendingShotPoint = selected.shotPoint;
    }
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
