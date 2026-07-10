import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/features/history/history_controller.dart';

void main() {
  test('orders recent matches and derives winner and completeness', () {
    final controller = HistoryController(
      matches: [
        HistoryMatchSummary(
          matchId: 'older',
          playedAt: DateTime(2026, 7, 1),
          redName: '红 A',
          blueName: '蓝 A',
          redScore: 5,
          blueScore: 5,
          ruleName: '自由计分',
          duration: const Duration(minutes: 5),
          locatedShots: 0,
          scoringEvents: 0,
        ),
        HistoryMatchSummary(
          matchId: 'newer',
          playedAt: DateTime(2026, 7, 2),
          redName: '红 B',
          blueName: '蓝 B',
          redScore: 11,
          blueScore: 8,
          ruleName: '11 分制',
          duration: const Duration(minutes: 9),
          locatedShots: 8,
          scoringEvents: 10,
        ),
      ],
    );

    expect(controller.matches.first.matchId, 'newer');
    expect(controller.matches.first.winnerName, '红 B');
    expect(controller.matches.first.locationCompleteness, 0.8);
    expect(controller.matches.last.winnerName, isNull);
    expect(controller.matches.last.locationCompleteness, 0);
  });
}
