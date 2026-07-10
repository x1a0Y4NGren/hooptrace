import 'dart:collection';

class HistoryMatchSummary {
  const HistoryMatchSummary({
    required this.matchId,
    required this.playedAt,
    required this.redName,
    required this.blueName,
    required this.redScore,
    required this.blueScore,
    required this.ruleName,
    required this.duration,
    required this.locatedShots,
    required this.scoringEvents,
  })  : assert(locatedShots >= 0),
        assert(scoringEvents >= 0);

  final String matchId;
  final DateTime playedAt;
  final String redName;
  final String blueName;
  final int redScore;
  final int blueScore;
  final String ruleName;
  final Duration duration;
  final int locatedShots;
  final int scoringEvents;

  String? get winnerName {
    if (redScore == blueScore) return null;
    return redScore > blueScore ? redName : blueName;
  }

  double get locationCompleteness {
    if (scoringEvents == 0) return 0;
    return (locatedShots / scoringEvents).clamp(0, 1);
  }
}

class HistoryController {
  HistoryController({required List<HistoryMatchSummary> matches})
      : _matches = List.of(matches)
          ..sort((a, b) => b.playedAt.compareTo(a.playedAt));

  final List<HistoryMatchSummary> _matches;

  UnmodifiableListView<HistoryMatchSummary> get matches =>
      UnmodifiableListView(_matches);
}
