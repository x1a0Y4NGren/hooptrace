import 'package:csv/csv.dart';
import 'package:hooptrace/core/data/app_database.dart';

class PlayerStatisticsRow {
  const PlayerStatisticsRow({
    required this.playerId,
    required this.playerName,
    required this.matchesPlayed,
    required this.wins,
    required this.points,
    required this.madeShots,
    required this.attemptedShots,
  });

  final String playerId;
  final String playerName;
  final int matchesPlayed;
  final int wins;
  final int points;
  final int madeShots;
  final int attemptedShots;

  double get shootingPercentage =>
      attemptedShots == 0 ? 0 : madeShots / attemptedShots * 100;
}

class CsvExporter {
  const CsvExporter._();

  static final _csv = Csv(lineDelimiter: '\r\n');

  static const matchHeaders = [
    'match_id',
    'red_name',
    'blue_name',
    'status',
    'created_at',
    'started_at',
    'ended_at',
    'timer_enabled',
    'note',
  ];

  static const eventHeaders = [
    'match_id',
    'event_id',
    'event_type',
    'side',
    'points',
    'timestamp',
    'note',
    'custom_event_type',
    'is_deleted',
  ];

  static const playerStatisticsHeaders = [
    'player_id',
    'player_name',
    'matches_played',
    'wins',
    'points',
    'made_shots',
    'attempted_shots',
    'shooting_percentage',
  ];

  static String matchList(Iterable<Matche> matches) {
    final sorted = matches.toList()..sort((a, b) => a.id.compareTo(b.id));
    return _encode([
      matchHeaders,
      ...sorted.map(
        (match) => [
          match.id,
          match.redName,
          match.blueName,
          match.status,
          _timestamp(match.createdAt),
          _timestampOrEmpty(match.startedAt),
          _timestampOrEmpty(match.endedAt),
          match.timerEnabled,
          match.note ?? '',
        ],
      ),
    ]);
  }

  static String eventList(Iterable<MatchEventRow> events) {
    final sorted = events.toList()..sort((a, b) => a.id.compareTo(b.id));
    return _encode([
      eventHeaders,
      ...sorted.map(
        (event) => [
          event.matchId,
          event.id,
          event.type,
          event.side ?? '',
          event.points,
          _timestamp(event.occurredAt),
          event.note ?? '',
          event.customEventType ?? '',
          event.isDeleted,
        ],
      ),
    ]);
  }

  static String playerStatistics(Iterable<PlayerStatisticsRow> statistics) {
    final sorted = statistics.toList()
      ..sort((a, b) {
        if (a.playerId.isEmpty != b.playerId.isEmpty) {
          return a.playerId.isEmpty ? 1 : -1;
        }
        final idOrder = a.playerId.compareTo(b.playerId);
        return idOrder == 0 ? a.playerName.compareTo(b.playerName) : idOrder;
      });
    return _encode([
      playerStatisticsHeaders,
      ...sorted.map(
        (player) => [
          player.playerId,
          player.playerName,
          player.matchesPlayed,
          player.wins,
          player.points,
          player.madeShots,
          player.attemptedShots,
          player.shootingPercentage.toStringAsFixed(2),
        ],
      ),
    ]);
  }

  static String _encode(List<List<Object?>> rows) {
    return _csv.encode(rows);
  }

  static String _timestamp(DateTime value) => value.toUtc().toIso8601String();

  static String _timestampOrEmpty(DateTime? value) =>
      value == null ? '' : _timestamp(value);
}
