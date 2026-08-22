import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/features/players/player_editor_page.dart';
import 'package:hooptrace/features/players/player_list_page.dart';

import '../../test_helpers/test_database.dart';

void main() {
  testWidgets('player list exposes empty, create and edit flows',
      (tester) async {
    final database = createTestDatabase();
    final repository = PlayerRepository(database);
    var created = false;
    Player? edited;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerListPage(
          repository: repository,
          onCreate: () => created = true,
          onEdit: (player) => edited = player,
        ),
      ),
    );
    await _pumpDatabase(tester);
    expect(find.text('还没有保存的球员'), findsOneWidget);

    await tester.tap(find.byTooltip('新建球员'));
    expect(created, isTrue);

    await repository.save(
      Player(
        id: 'player-1',
        nickname: '小北',
        createdAt: DateTime.utc(2026, 7, 10),
        note: '外线投篮',
      ),
    );
    await _pumpDatabase(tester);
    await tester.tap(find.text('小北'));
    expect(edited?.id, 'player-1');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('player editor creates and updates persisted fields',
      (tester) async {
    final database = createTestDatabase();
    final repository = PlayerRepository(database);
    var saved = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayerEditorPage(
          repository: repository,
          idFactory: () => 'new-player',
          now: () => DateTime.utc(2026, 7, 10),
          onSaved: () => saved = true,
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('player-nickname')), '飞鱼');
    await tester.tap(find.text('蓝方'));
    await tester.enterText(find.byKey(const Key('player-note')), '惯用左手');
    await tester.tap(find.byTooltip('保存球员'));
    await _pumpDatabase(tester);

    final player = await repository.getById('new-player');
    expect(player?.nickname, '飞鱼');
    expect(player?.preferredSide?.name, 'blue');
    expect(player?.note, '惯用左手');
    expect(saved, isTrue);

    final updated = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerEditorPage(
          repository: repository,
          playerId: 'new-player',
          onSaved: updated.complete,
        ),
      ),
    );
    await _pumpUntilFound(tester, find.text('飞鱼'));
    await tester.enterText(find.byKey(const Key('player-nickname')), '飞鱼 2');
    await tester.tap(find.byTooltip('保存球员'));
    await tester.runAsync(
      () => updated.future.timeout(const Duration(seconds: 2)),
    );
    await tester.pump();
    expect((await repository.getById('new-player'))?.nickname, '飞鱼 2');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Future<void> _pumpDatabase(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for the expected widget.');
}
