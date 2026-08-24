import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/features/home/home_page.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

import '../test_helpers/test_database.dart';

void main() {
  testWidgets('scoring route keeps primary targets inside a 1920 viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await database.close();
    });
    final now = DateTime.utc(2026, 8, 25, 12);
    await MatchCommandService(database).start(
      StartMatchCommand(
        commandId: 'task5-layout-start',
        matchId: 'task5-layout',
        redName: 'Red',
        blueName: 'Blue',
        ruleTemplate: const RuleTemplate(
          id: 'free',
          name: 'Free',
          scoreButtons: [1, 2, 3],
        ),
        recordingMode: RecordingMode.simple,
        trackingCoverage: TrackingCoverage.scoresOnly,
        createdAt: now,
        startedAt: now,
      ),
    );

    await tester.pumpWidget(HoopTraceApp(database: database));
    await _pumpUntilFound(tester, find.byKey(const Key('home-resume')));
    await tester.tap(find.byKey(const Key('home-resume')));
    await _pumpUntilFound(tester, find.byType(ScoringPage));
    await tester.pumpAndSettle();

    final viewport = tester.binding.renderViews.first.size;
    for (final key in [
      const Key('blue-score-1'),
      const Key('blue-score-2'),
      const Key('blue-score-3'),
      const Key('red-score-1'),
      const Key('red-score-2'),
      const Key('red-score-3'),
      const Key('scoring-undo'),
      const Key('scoring-more'),
    ]) {
      final rect = tester.getRect(find.byKey(key));
      expect(rect.left, greaterThanOrEqualTo(0), reason: '$key left');
      expect(
        rect.right,
        lessThanOrEqualTo(viewport.width),
        reason: '$key right',
      );
      expect(rect.top, greaterThanOrEqualTo(0), reason: '$key top');
      expect(
        rect.bottom,
        lessThanOrEqualTo(viewport.height),
        reason: '$key bottom',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unified scoring app flow persists actions and returns from final replay',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(3000, 1080));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final database = createTestDatabase();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await database.close();
      });

      await tester.pumpWidget(HoopTraceApp(database: database));
      await _pumpUntilFound(tester, find.byKey(homeStartScoringKey));
      await tester.tap(find.byKey(homeStartScoringKey));
      await _pumpUntilFound(tester, find.byType(PregamePage));

      // Starting a match must not require either of the removed recording
      // controls. Pick a target rule so the end-to-end flow can finish.
      expect(find.byKey(const Key('pregame-recording-simple')), findsNothing);
      expect(
        find.byKey(const Key('pregame-tracking-scores-only')),
        findsNothing,
      );
      await tester.tap(find.byKey(const Key('pregame-rule-template')));
      await tester.pumpAndSettle();
      final twentyOne = find.textContaining('21');
      expect(twentyOne, findsOneWidget);
      await tester.tap(twentyOne);
      await tester.pumpAndSettle();
      final startMatch = find.byKey(const Key('pregame-start-match'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.ensureVisible(startMatch);
      await tester.pump();
      await tester.tap(startMatch);
      await _pumpUntilFound(tester, find.byType(ScoringPage));

      // Score-first: score, attach a court point, then undo the location and
      // the score as two separate actions.
      _invoke(tester, find.byKey(const Key('red-score-2')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('red-score-2-location')),
      );
      final courtRect = tester.getRect(find.byKey(const Key('scoring-court')));
      await tester.tapAt(
        courtRect.topLeft +
            Offset(courtRect.width * 0.25, courtRect.height * 0.25),
      );
      await _pumpUntil(
        tester,
        () async => await _confirmedLocationCount(database) == 1,
      );
      await tester.tap(find.byKey(const Key('scoring-undo')));
      await _pumpUntil(
        tester,
        () async => await _confirmedLocationCount(database) == 0,
      );
      expect(await _activeScoringEventCount(database), 1);
      await tester.tap(find.byKey(const Key('scoring-undo')));
      await _pumpUntil(
        tester,
        () async => await _activeScoringEventCount(database) == 0,
      );

      // Court-first: a gray point is selected before choosing the scoring
      // side, and the committed event/location is one atomic action.
      await tester.tapAt(
        tester.getCenter(find.byKey(const Key('scoring-court'))),
      );
      await _pumpUntilFound(tester, find.text('请选择蓝方或红方得分'));
      _invoke(tester, find.byKey(const Key('red-score-2')));
      await _pumpUntil(
        tester,
        () async =>
            await _activeScoringEventCount(database) == 1 &&
            await _confirmedLocationCount(database) == 1,
      );

      // Foul and every grouped More action must be reachable while the
      // normal score-first supplement is not blocking ordinary actions.
      _invoke(tester, find.byKey(const Key('red-foul')));
      await _pumpUntil(
        tester,
        () async => await _activeScoringEventCount(database) == 2,
      );
      await tester.tap(find.byKey(const Key('scoring-more')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );
      _invoke(tester, find.byKey(const Key('more-blue-miss')));
      await _pumpUntilMissing(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );

      await tester.tap(find.byKey(const Key('scoring-more')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );
      _invoke(tester, find.byKey(const Key('more-red-free-throw-miss')));
      await _pumpUntilMissing(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );

      await tester.tap(find.byKey(const Key('scoring-more')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );
      _invoke(tester, find.byKey(const Key('more-possession-blue')));
      await _pumpUntilMissing(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );

      await tester.tap(find.byKey(const Key('scoring-more')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );
      _invoke(tester, find.byKey(const Key('more-note')));
      await _pumpUntilFound(tester, find.byKey(const Key('text-entry-field')));
      await tester.enterText(
        find.byKey(const Key('text-entry-field')),
        'task5',
      );
      await tester.tap(find.byKey(const Key('text-entry-confirm')));
      await _pumpUntilMissing(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );

      // Reach 20 without triggering the target decision, then resolve the
      // latest supplement before the final made free throw reaches 21.
      var expectedEvents = await _activeScoringEventCount(database);
      for (var index = 0; index < 6; index++) {
        _invoke(tester, find.byKey(const Key('red-score-3')));
        expectedEvents++;
        final expected = expectedEvents;
        await _pumpUntil(
          tester,
          () async => await _activeScoringEventCount(database) == expected,
        );
      }
      final finalCourt = tester.getRect(find.byKey(const Key('scoring-court')));
      await tester.tapAt(
        finalCourt.topLeft +
            Offset(finalCourt.width * 0.75, finalCourt.height * 0.25),
      );
      await _pumpUntil(
        tester,
        () async => await _confirmedLocationCount(database) == 2,
      );

      await tester.tap(find.byKey(const Key('scoring-more')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-more-sheet')),
      );
      _invoke(tester, find.byKey(const Key('more-red-free-throw-made')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-decision-finish')),
      );
      await tester.tap(find.byKey(const Key('scoring-decision-finish')));
      await _pumpUntilFound(
        tester,
        find.byKey(const Key('scoring-finish-confirm')),
      );
      await tester.tap(find.byKey(const Key('scoring-finish-confirm')));
      await _pumpUntilFound(tester, find.byType(ReplayPage));
      await _pumpUntilFound(tester, find.text('终场'));

      final match = await database.select(database.matches).getSingle();
      expect(match.lifecycle, 'finished');

      await tester.binding.handlePopRoute();
      await _pumpUntilFound(tester, find.byType(HomePage));
    },
  );
}

void _invoke(WidgetTester tester, Finder finder) {
  final widget = tester.widget<Widget>(finder);
  if (widget is FilledButton) {
    widget.onPressed!();
  } else if (widget is OutlinedButton) {
    widget.onPressed!();
  } else if (widget is IconButton) {
    widget.onPressed!();
  } else if (widget is ListTile) {
    widget.onTap!();
  } else {
    fail('Unsupported action widget: ${widget.runtimeType}');
  }
}

Future<int> _activeScoringEventCount(dynamic database) async {
  final rows = await database.select(database.matchEvents).get();
  return rows.where((row) => row.isDeleted == false).length;
}

Future<int> _confirmedLocationCount(dynamic database) async {
  final rows = await database.select(database.shotLocations).get();
  return rows.where((row) => row.isConfirmed == true).length;
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  await _pumpUntil(tester, () async => finder.evaluate().isNotEmpty);
}

Future<void> _pumpUntilMissing(WidgetTester tester, Finder finder) async {
  await _pumpUntil(tester, () async => finder.evaluate().isEmpty);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Future<bool> Function() predicate,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.pump(const Duration(milliseconds: 25));
    if (await predicate()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  fail('Timed out waiting for integration condition.');
}
