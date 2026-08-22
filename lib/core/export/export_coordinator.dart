import 'dart:convert';
import 'dart:typed_data';

import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/csv_exporter.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

class ExportArtifact {
  const ExportArtifact({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  factory ExportArtifact.text({
    required String fileName,
    required String mimeType,
    required String contents,
  }) {
    return ExportArtifact(
      fileName: fileName,
      mimeType: mimeType,
      bytes: Uint8List.fromList(utf8.encode(contents)),
    );
  }

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

abstract interface class ExportGateway {
  Future<void> share(List<ExportArtifact> artifacts, {required String subject});

  Future<ExportArtifact?> pickBackup();

  Future<BackupDirectorySelection?> pickDirectory();
}

class ExportCoordinator {
  ExportCoordinator(
    this.database,
    this.codec, {
    required this.gateway,
    required this.automaticBackup,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final AppDatabase database;
  final JsonBackupCodec codec;
  final ExportGateway gateway;
  final AutomaticBackupService automaticBackup;
  final DateTime Function() now;

  Future<void> shareJsonBackup() async {
    final timestamp = now().toUtc();
    final payload = await codec.export();
    await gateway.share([
      ExportArtifact.text(
        fileName: 'hooptrace-backup-${_fileTimestamp(timestamp)}.json',
        mimeType: 'application/json',
        contents: payload,
      ),
    ], subject: 'HoopTrace 完整本地备份');
  }

  Future<bool> restorePickedBackup() async {
    final artifact = await gateway.pickBackup();
    if (artifact == null) return false;
    final payload = utf8.decode(artifact.bytes, allowMalformed: false);
    await codec.restore(payload);
    await automaticBackup.resetAfterRestore();
    return true;
  }

  Future<void> shareCsvExports() async {
    final timestamp = now().toUtc();
    final matches = await database.select(database.matches).get();
    final events = await database.select(database.matchEvents).get();
    final players = await database.select(database.players).get();
    final statistics = _buildPlayerStatistics(matches, events, players);
    final suffix = _fileTimestamp(timestamp);
    await gateway.share([
      ExportArtifact.text(
        fileName: 'hooptrace-matches-$suffix.csv',
        mimeType: 'text/csv',
        contents: CsvExporter.matchList(matches),
      ),
      ExportArtifact.text(
        fileName: 'hooptrace-events-$suffix.csv',
        mimeType: 'text/csv',
        contents: CsvExporter.eventList(events),
      ),
      ExportArtifact.text(
        fileName: 'hooptrace-player-stats-$suffix.csv',
        mimeType: 'text/csv',
        contents: CsvExporter.playerStatistics(statistics),
      ),
    ], subject: 'HoopTrace CSV 数据导出');
  }

  Future<void> shareReplayImage(Uint8List bytes, {required String matchId}) {
    final safeMatchId = _safeFilePart(matchId);
    return gateway.share([
      ExportArtifact(
        fileName: 'hooptrace-replay-$safeMatchId.png',
        mimeType: 'image/png',
        bytes: bytes,
      ),
    ], subject: 'HoopTrace 比赛复盘');
  }

  Future<BackupDirectorySelection?> pickBackupDirectory() =>
      gateway.pickDirectory();

  static List<PlayerStatisticsRow> _buildPlayerStatistics(
    List<Matche> matches,
    List<MatchEventRow> events,
    List<PlayerRow> players,
  ) {
    final participants = <_Participant>[
      for (final player in players)
        _Participant(id: player.id, name: player.nickname),
    ];
    final registeredNames = players.map((player) => player.nickname).toSet();
    final unregisteredNames = <String>{
      for (final match in matches) match.redName,
      for (final match in matches) match.blueName,
    }..removeAll(registeredNames);
    final sortedUnregistered = unregisteredNames.toList()..sort();
    participants.addAll(
      sortedUnregistered.map((name) => _Participant(id: '', name: name)),
    );

    final eventsByMatch = <String, List<MatchEventRow>>{};
    for (final event in events.where((event) => !event.isDeleted)) {
      eventsByMatch.putIfAbsent(event.matchId, () => []).add(event);
    }

    return participants
        .map((participant) {
          var matchesPlayed = 0;
          var wins = 0;
          var points = 0;
          var madeShots = 0;
          var attemptedShots = 0;
          for (final match in matches) {
            final sides = <String>{
              if (match.redName == participant.name) 'red',
              if (match.blueName == participant.name) 'blue',
            };
            if (sides.isEmpty) continue;
            matchesPlayed++;
            final matchEvents = eventsByMatch[match.id] ?? const [];
            var redScore = 0;
            var blueScore = 0;
            for (final event in matchEvents) {
              if (event.type == 'score') {
                if (event.side == 'red') redScore += event.points;
                if (event.side == 'blue') blueScore += event.points;
              }
              if (!sides.contains(event.side)) continue;
              if (event.type == 'score') {
                points += event.points;
                madeShots++;
                attemptedShots++;
              } else if (event.type == 'miss') {
                attemptedShots++;
              }
            }
            if ((sides.contains('red') && redScore > blueScore) ||
                (sides.contains('blue') && blueScore > redScore)) {
              wins++;
            }
          }
          return PlayerStatisticsRow(
            playerId: participant.id,
            playerName: participant.name,
            matchesPlayed: matchesPlayed,
            wins: wins,
            points: points,
            madeShots: madeShots,
            attemptedShots: attemptedShots,
          );
        })
        .toList(growable: false);
  }

  static String _safeFilePart(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return sanitized.isEmpty ? 'match' : sanitized;
  }

  static String _fileTimestamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}'
        '${two(value.month)}${two(value.day)}-'
        '${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }
}

class _Participant {
  const _Participant({required this.id, required this.name});

  final String id;
  final String name;
}
