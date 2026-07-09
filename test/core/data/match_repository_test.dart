import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/domain/entities/match_event.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

void main() {
  test('match repository stores and reads score events', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);

    final repository = MatchRepository(database);
    await repository.createMinimalMatch(
      id: 'match-1',
      redName: 'Red',
      blueName: 'Blue',
      createdAt: DateTime.utc(2026),
    );
    await repository.addEvent(
      MatchEvent.score(
        id: 'event-1',
        matchId: 'match-1',
        side: TeamSide.red,
        points: 2,
        occurredAt: DateTime.utc(2026),
      ),
    );

    final events = await repository.watchEvents('match-1').first;
    expect(events.single.points, 2);
    expect(events.single.side, TeamSide.red);
  });
}
