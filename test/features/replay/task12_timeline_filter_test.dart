import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/design_system/design_system.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/widgets/replay_timeline.dart';

void main() {
  testWidgets(
    'compact landscape shows first event and a 48dp filter action on first paint',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(731, 411));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = ReplayController(
        data: ReplayMatchData(
          matchId: 'compact-first-event',
          redName: 'Red',
          blueName: 'Blue',
          redScore: 2,
          blueScore: 0,
          duration: const Duration(minutes: 1),
          events: [
            ReplayEventData(
              id: 'first',
              side: TeamSide.red,
              kind: ReplayEventKind.score,
              points: 2,
              outcome: ShotOutcome.made,
              elapsed: Duration.zero,
              occurredAt: DateTime.utc(2026, 8, 1),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildHoopTraceTheme(brightness: Brightness.dark),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ReplayTimelinePanel(
                controller: controller,
                onEventTap: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pane = tester.getRect(
        find.byKey(const Key('replay-timeline-pane')),
      );
      final first = tester.getRect(find.byKey(const Key('replay-event-first')));
      final filters = tester.getRect(
        find.byKey(const Key('replay-compact-filter-action')),
      );
      expect(first.overlaps(pane), isTrue);
      expect(first.top, greaterThanOrEqualTo(pane.top));
      expect(first.bottom, lessThanOrEqualTo(pane.bottom));
      expect(filters.width, greaterThanOrEqualTo(48));
      expect(filters.height, greaterThanOrEqualTo(48));
      final context = tester.element(
        find.byKey(const Key('replay-timeline-pane')),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.timeline)).color,
        editorialThemeOf(context).arenaAccent,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('outcome and point chips can be tapped again to clear filters', (
    tester,
  ) async {
    final controller = ReplayController(
      data: ReplayMatchData(
        matchId: 'filter-clear',
        redName: 'Red',
        blueName: 'Blue',
        redScore: 2,
        blueScore: 0,
        duration: Duration.zero,
        events: [
          ReplayEventData(
            id: 'event',
            side: TeamSide.red,
            kind: ReplayEventKind.score,
            points: 2,
            outcome: ShotOutcome.made,
            elapsed: Duration.zero,
            occurredAt: DateTime.utc(2026, 8, 1),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReplayTimelinePanel(
              controller: controller,
              embedded: true,
              onEventTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final madeChip = find.widgetWithText(ChoiceChip, '命中');
    await tester.tap(madeChip);
    expect(controller.eventFilter.outcomes, {ShotOutcome.made});
    await tester.tap(madeChip);
    expect(controller.eventFilter.outcomes, isEmpty);

    final pointChip = find.widgetWithText(ChoiceChip, '分值 2');
    await tester.tap(pointChip);
    expect(controller.eventFilter.points, {2});
    await tester.tap(pointChip);
    expect(controller.eventFilter.points, isEmpty);
  });

  testWidgets('other chip includes every non shot score or foul event', (
    tester,
  ) async {
    final events = <ReplayEventData>[
      for (final kind in const [
        EventKind.reward,
        EventKind.pause,
        EventKind.interruption,
        EventKind.note,
        EventKind.custom,
        EventKind.possession,
      ])
        ReplayEventData(
          id: kind.name,
          side: null,
          kind: ReplayEventKind.other,
          rawKind: kind,
          elapsed: Duration.zero,
          occurredAt: DateTime.utc(2026, 8, 1),
        ),
      ReplayEventData(
        id: 'score',
        side: TeamSide.red,
        kind: ReplayEventKind.score,
        rawKind: EventKind.fieldGoal,
        points: 2,
        outcome: ShotOutcome.made,
        elapsed: Duration.zero,
        occurredAt: DateTime.utc(2026, 8, 1),
      ),
    ];
    final controller = ReplayController(
      data: ReplayMatchData(
        matchId: 'filter-other',
        redName: 'Red',
        blueName: 'Blue',
        redScore: 2,
        blueScore: 0,
        duration: Duration.zero,
        events: events,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReplayTimelinePanel(
              controller: controller,
              embedded: true,
              onEventTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('replay-kind-other')));
    await tester.pump();

    expect(controller.visibleEvents.map((event) => event.id), [
      'reward',
      'pause',
      'interruption',
      'note',
      'custom',
      'possession',
    ]);
  });
}
