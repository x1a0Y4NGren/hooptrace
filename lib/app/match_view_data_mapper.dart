import 'package:hooptrace/core/domain/entities/match.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics_calculator.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/entities/match_history_entry.dart';
import 'package:hooptrace/features/history/history_controller.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';

ReplayMatchData replayDataFromDetail(MatchDetail detail) {
  final locationsByEvent = {
    for (final location in detail.shotLocations)
      if (location.isConfirmed) location.eventId: location,
  };
  final startedAt = detail.match.startedAt ?? detail.match.createdAt;
  final elapsedByEvent = {
    for (final event in detail.events)
      if (!event.isDeleted)
        event.id: _nonNegativeDifference(event.occurredAt, startedAt),
  };
  final possessionSegments = <ReplayPossessionSegmentData>[];
  for (final segment in detail.possessionSegments) {
    final segmentStartedAt = elapsedByEvent[segment.startedAtEventId];
    if (segmentStartedAt == null) continue;
    final segmentEndedAt = segment.endedAtEventId == null
        ? null
        : elapsedByEvent[segment.endedAtEventId];
    if (segment.endedAtEventId != null && segmentEndedAt == null) continue;
    if (segmentEndedAt != null && segmentEndedAt < segmentStartedAt) continue;
    possessionSegments.add(
      ReplayPossessionSegmentData(
        id: segment.id,
        side: segment.side,
        startedAtEventId: segment.startedAtEventId,
        startedAt: segmentStartedAt,
        endedAtEventId: segment.endedAtEventId,
        endedAt: segmentEndedAt,
        reason: segment.reason,
        source: segment.source,
      ),
    );
  }

  return ReplayMatchData(
    matchId: detail.match.id,
    redName: detail.match.redName,
    blueName: detail.match.blueName,
    redScore: detail.redScore,
    blueScore: detail.blueScore,
    duration: detail.duration ?? _elapsedSince(startedAt),
    analytics: MatchAnalyticsCalculator().calculate(
      detail.events,
      targetScore: detail.match.ruleTemplateSnapshot.targetScore,
      winByTwo: detail.match.ruleTemplateSnapshot.winByTwo,
    ),
    possessionSegments: possessionSegments,
    isFinished:
        detail.match.status == MatchStatus.finished ||
        detail.match.status == MatchStatus.archived,
    events: [
      for (final event in detail.events)
        if (!event.isDeleted)
          ReplayEventData(
            id: event.id,
            kind: _replayKind(event),
            side: event.side,
            points: event.points,
            elapsed: _nonNegativeDifference(event.occurredAt, startedAt),
            note: event.note,
            locationId: locationsByEvent[event.id]?.id,
            shotPoint: locationsByEvent[event.id]?.point,
          ),
    ],
  );
}

HistoryMatchSummary historySummaryFromEntry(MatchHistoryEntry entry) {
  return HistoryMatchSummary(
    matchId: entry.id,
    playedAt: entry.playedAt.toLocal(),
    redName: entry.redName,
    blueName: entry.blueName,
    redScore: entry.redScore,
    blueScore: entry.blueScore,
    ruleName: entry.ruleName,
    duration: entry.duration ?? Duration.zero,
    locatedShots: entry.locatedShotCount,
    scoringEvents: entry.shotAttemptCount,
  );
}

ReplayEventKind _replayKind(MatchEvent event) {
  return switch (event.type) {
    MatchEventType.score => ReplayEventKind.score,
    MatchEventType.fieldGoal || MatchEventType.freeThrow =>
      event.outcome == ShotOutcome.made
          ? ReplayEventKind.score
          : ReplayEventKind.miss,
    MatchEventType.foul => ReplayEventKind.foul,
    MatchEventType.miss => ReplayEventKind.miss,
    _ => ReplayEventKind.other,
  };
}

Duration _nonNegativeDifference(DateTime value, DateTime origin) {
  final difference = value.difference(origin);
  return difference.isNegative ? Duration.zero : difference;
}

Duration _elapsedSince(DateTime startedAt) {
  return _nonNegativeDifference(DateTime.now(), startedAt);
}
