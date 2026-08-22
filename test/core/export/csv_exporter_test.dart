import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/csv_exporter.dart';

void main() {
  group('CsvExporter', () {
    test('exports match list with stable headers and escaped text', () {
      final encoded = CsvExporter.matchList([
        Matche(
          id: 'match-1',
          redName: 'Red, Prime',
          blueName: 'Blue "Wave"',
          status: 'finished',
          ruleTemplateJson: '{}',
          createdAt: DateTime.utc(2026, 7, 18, 8),
          startedAt: DateTime.utc(2026, 7, 18, 8, 1),
          endedAt: DateTime.utc(2026, 7, 18, 8, 9),
          timerEnabled: false,
          note: 'line one\nline two',
        ),
      ]);

      final rows = _decodeCsv(encoded);
      expect(rows.first, CsvExporter.matchHeaders);
      expect(rows.singleWhere((row) => row.first == 'match-1'), [
        'match-1',
        'Red, Prime',
        'Blue "Wave"',
        'finished',
        '2026-07-18T08:00:00.000Z',
        '2026-07-18T08:01:00.000Z',
        '2026-07-18T08:09:00.000Z',
        'false',
        'line one\nline two',
      ]);
      expect(encoded, contains('"Red, Prime"'));
      expect(encoded, contains('"Blue ""Wave"""'));
      expect(encoded, contains('"line one\nline two"'));
    });

    test('exports required event fields with stable headers', () {
      final encoded = CsvExporter.eventList([
        MatchEventRow(
          id: 'event-1',
          matchId: 'match-1',
          type: 'score',
          side: 'red',
          points: 3,
          occurredAt: DateTime.utc(2026, 7, 18, 8, 2, 3),
          note: 'deep, corner',
          customEventType: null,
          isDeleted: false,
        ),
      ]);

      final rows = _decodeCsv(encoded);
      expect(rows.first, CsvExporter.eventHeaders);
      expect(rows[1].take(6), [
        'match-1',
        'event-1',
        'score',
        'red',
        3,
        '2026-07-18T08:02:03.000Z',
      ]);
      expect(rows[1][6], 'deep, corner');
    });

    test('exports player statistics with stable headers', () {
      final encoded = CsvExporter.playerStatistics([
        const PlayerStatisticsRow(
          playerId: 'player-1',
          playerName: 'A, Ace',
          matchesPlayed: 4,
          wins: 3,
          points: 28,
          madeShots: 12,
          attemptedShots: 20,
        ),
      ]);

      final rows = _decodeCsv(encoded);
      expect(rows.first, CsvExporter.playerStatisticsHeaders);
      expect(rows[1], [
        'player-1',
        'A, Ace',
        4,
        3,
        28,
        12,
        20,
        60.0,
      ]);
      expect(encoded, endsWith(',60.00'));
    });
  });
}

List<List<dynamic>> _decodeCsv(String encoded) {
  return Csv(
    dynamicTyping: true,
    decoderTransform: (field, _, _) =>
        field is bool ? field.toString() : field,
  ).decode(encoded);
}
