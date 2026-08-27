import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/features/home/home_page.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('completes the local scoring and replay loop', (tester) async {
    final runId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final redName = '集成红-$runId';
    final blueName = '集成蓝-$runId';
    final database = AppDatabase.inMemory();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.runAsync(database.close);
    });

    await tester.pumpWidget(HoopTraceApp(database: database));
    await _pumpUntilFound(
      tester,
      find.byKey(homeStartScoringKey),
      description: 'the Home start-scoring action',
    );

    await _tapWhenHitTestable(
      tester,
      find.byKey(homeStartScoringKey),
      description: 'the Home start-scoring action',
    );
    await _pumpUntilFound(
      tester,
      find.byType(PregamePage),
      description: 'PregamePage after starting a match',
    );

    await tester.enterText(find.byKey(const Key('pregame-red-name')), redName);
    await tester.enterText(
      find.byKey(const Key('pregame-blue-name')),
      blueName,
    );
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('pregame-start-match')));
    await _tapWhenHitTestable(
      tester,
      find.byKey(const Key('pregame-start-match')),
      description: 'the Pregame start-match action',
    );
    await _pumpUntilFound(
      tester,
      find.byType(ScoringPage),
      description: 'ScoringPage after confirming pregame',
    );
    await _pumpUntilLandscape(tester);

    await tester.tap(find.byKey(const Key('red-score-2')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2 $redName'), findsOneWidget);
    expect(find.text('$blueName 0'), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(find.byKey(const Key('scoring-court'))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scoring-finish')));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('match-controls-pause')),
      description: 'the scoring match controls',
    );
    await tester.tap(find.byKey(const Key('match-controls-pause')));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('scoring-paused-panel')),
      description: 'the blocking paused-match panel',
    );
    expect(find.byKey(const Key('paused-return-home')), findsOneWidget);
    expect(find.byKey(const Key('paused-continue')), findsOneWidget);
    expect(find.byKey(const Key('paused-finish')), findsOneWidget);
    await tester.tap(find.byKey(const Key('paused-continue')));
    await _pumpUntilGone(
      tester,
      find.byKey(const Key('scoring-paused-panel')),
      description: 'the paused-match panel after continuing',
    );

    await tester.tap(find.byKey(const Key('scoring-finish')));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('match-controls-finish')),
      description: 'the scoring finish action',
    );
    await tester.tap(find.byKey(const Key('match-controls-finish')));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('scoring-finish-confirm')),
      description: 'the scoring finish confirmation',
    );
    await tester.tap(find.byKey(const Key('scoring-finish-confirm')));
    await _pumpUntilFound(
      tester,
      find.byType(ReplayPage),
      description: 'ReplayPage after finishing from ScoringPage',
    );
    final finishedReplayL10n = AppLocalizations.of(
      tester.element(find.byType(ReplayPage)),
    )!;
    expect(find.text(redName), findsAtLeastNWidgets(1));
    expect(find.text(blueName), findsAtLeastNWidgets(1));
    expect(find.text(finishedReplayL10n.replayFinished), findsOneWidget);
    expect(find.text(redName), findsAtLeastNWidgets(1));
    expect(find.text(blueName), findsAtLeastNWidgets(1));
    expect(find.byKey(const Key('replay-finish-match')), findsNothing);

    await tester.binding.handlePopRoute();
    await _pumpUntilFound(
      tester,
      find.byType(HomePage),
      description: 'HomePage after leaving Replay',
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(ReplayPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilLandscape(
  WidgetTester tester, {
  int attempts = 150,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    final physicalSize = tester.view.physicalSize;
    if (physicalSize.width > physicalSize.height) {
      await tester.pump(const Duration(milliseconds: 250));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Timed out waiting for the scoring view to enter landscape.');
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  String? description,
  int attempts = 150,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Timed out waiting for ${description ?? finder} ($finder).');
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  String? description,
  int attempts = 150,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 250));
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail(
    'Timed out waiting for ${description ?? finder} to disappear ($finder).',
  );
}

Future<void> _tapWhenHitTestable(
  WidgetTester tester,
  Finder finder, {
  required String description,
  int attempts = 150,
}) async {
  final hitTestableFinder = finder.hitTestable();
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (hitTestableFinder.evaluate().isNotEmpty) {
      await tester.tap(hitTestableFinder);
      await tester.pump();
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
  fail('Timed out waiting for $description to become hit-testable ($finder).');
}
