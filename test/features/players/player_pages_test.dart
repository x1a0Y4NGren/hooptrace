import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/players/player_editor_page.dart';
import 'package:hooptrace/features/players/player_list_page.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';

import '../../test_helpers/test_database.dart';

void main() {
  testWidgets('players list and editor stay usable across visual matrix', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = PlayerRepository(database);
    const locales = [Locale('zh'), Locale('en')];
    const sizes = [Size(390, 844), Size(731, 411)];
    for (final brightness in Brightness.values) {
      for (final locale in locales) {
        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          final mediaQuery = MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: MaterialApp(
              theme: buildHoopTraceTheme(brightness: brightness),
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: PlayerListPage(
                repository: repository,
                onCreate: () {},
                onEdit: (_) {},
              ),
            ),
          );
          await tester.pumpWidget(mediaQuery);
          await _pumpDatabase(tester);
          expect(tester.takeException(), isNull);
          expect(find.byType(DoodleTitle), findsOneWidget);
          expect(
            tester.getSize(find.byType(DoodlePress)).height,
            greaterThanOrEqualTo(48),
          );

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: MaterialApp(
                theme: buildHoopTraceTheme(brightness: brightness),
                locale: locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                home: PlayerEditorPage(repository: repository, onSaved: () {}),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byKey(const Key('player-nickname'))).height,
            greaterThanOrEqualTo(48),
          );
        }
      }
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('player row has one semantic action owner', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = PlayerRepository(database);
    await repository.save(
      Player(
        id: 'semantic-player',
        nickname: '小北',
        createdAt: DateTime.utc(2026, 7, 10),
      ),
    );
    var edits = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: PlayerListPage(
          repository: repository,
          onCreate: () {},
          onEdit: (_) => edits++,
        ),
      ),
    );
    await _pumpDatabase(tester);

    final row = find.byKey(const ValueKey('player-row-semantic-player'));
    expect(row, findsOneWidget);
    expect(
      tester
          .getSemantics(row)
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(row);
    expect(edits, 1);
    semanticsHandle.dispose();
  });

  testWidgets('player editor save has one semantic action owner', (
    tester,
  ) async {
    final semanticsHandle = tester.ensureSemantics();
    final database = createTestDatabase();
    addTearDown(database.close);
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: PlayerEditorPage(
          repository: PlayerRepository(database),
          onSaved: () => saved = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('player-save'));
    expect(save, findsOneWidget);
    expect(
      tester
          .getSemantics(save)
          .getSemanticsData()
          .hasAction(ui.SemanticsAction.tap),
      isTrue,
    );
    await tester.enterText(find.byKey(const Key('player-nickname')), '小北');
    await tester.tap(save);
    await _pumpDatabase(tester);
    expect(saved, isTrue);
    semanticsHandle.dispose();
  });

  testWidgets('player avatar foreground meets normal-text contrast', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = PlayerRepository(database);
    final variants = <String, TeamSide?>{
      'red': TeamSide.red,
      'blue': TeamSide.blue,
      'neutral': null,
    };
    for (final entry in variants.entries) {
      await repository.save(
        Player(
          id: 'contrast-${entry.key}',
          nickname: entry.key,
          createdAt: DateTime.utc(2026, 7, 10),
          preferredSide: entry.value,
        ),
      );
    }
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildHoopTraceTheme(brightness: brightness),
          home: PlayerListPage(
            repository: repository,
            onCreate: () {},
            onEdit: (_) {},
          ),
        ),
      );
      await _pumpDatabase(tester);
      for (final id in variants.keys) {
        final avatar = tester.widget<CircleAvatar>(
          find.byKey(ValueKey('player-avatar-contrast-$id')),
        );
        expect(
          _contrastRatio(avatar.foregroundColor!, avatar.backgroundColor!),
          greaterThanOrEqualTo(4.5),
          reason: '$brightness $id avatar contrast',
        );
      }
    }
  });

  testWidgets('player list exposes empty, create and edit flows', (
    tester,
  ) async {
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
    expect(find.byType(DoodleTitle), findsOneWidget);
    expect(find.byType(DoodleSurface), findsOneWidget);
    expect(find.byType(DoodlePress), findsOneWidget);

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

  testWidgets('player editor creates and updates persisted fields', (
    tester,
  ) async {
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
    expect(find.byType(DoodleSurface), findsOneWidget);
    expect(find.byType(DoodleDivider), findsOneWidget);
    expect(find.byType(DoodlePress), findsOneWidget);
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

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
