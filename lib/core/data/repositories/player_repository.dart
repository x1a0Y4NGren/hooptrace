import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class PlayerRepository {
  PlayerRepository(this._database);

  final AppDatabase _database;

  Future<void> save(Player player) {
    return _database.into(_database.players).insertOnConflictUpdate(
          PlayersCompanion.insert(
            id: player.id,
            nickname: player.nickname,
            createdAt: player.createdAt,
            preferredSide: Value(player.preferredSide?.name),
            note: Value(player.note),
          ),
        );
  }

  Stream<List<Player>> watchAll() {
    final query = _database.select(_database.players)
      ..orderBy([(player) => OrderingTerm.asc(player.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return Player(
          id: row.id,
          nickname: row.nickname,
          createdAt: row.createdAt,
          preferredSide: row.preferredSide == null
              ? null
              : TeamSide.values.byName(row.preferredSide!),
          note: row.note,
        );
      }).toList();
    });
  }
}
