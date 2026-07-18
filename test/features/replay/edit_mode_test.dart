import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';

void main() {
  testWidgets('replay remains read-only until edit mode is explicitly enabled',
      (
    tester,
  ) async {
    final controller = ReplayController(
      data: ReplayMatchData(
        matchId: 'match-1',
        redName: '红方',
        blueName: '蓝方',
        redScore: 2,
        blueScore: 0,
        duration: const Duration(minutes: 1),
        events: [
          ReplayEventData(
            id: 'event-1',
            locationId: 'location-1',
            kind: ReplayEventKind.score,
            side: TeamSide.red,
            points: 2,
            elapsed: Duration(seconds: 3),
            shotPoint: CourtPoint(x: 0.4, y: 0.6),
          ),
        ],
      ),
      onMoveShotLocation: (_, __, ___) async {},
    );
    await tester.pumpWidget(
      MaterialApp(home: ReplayPage(controller: controller)),
    );

    expect(controller.isEditing, isFalse);
    expect(
      tester.widget<CourtView>(find.byType(CourtView)).mode,
      CourtViewMode.readOnly,
    );
    expect(find.text('只读模式'), findsOneWidget);

    await tester.tap(find.byKey(const Key('replay-edit-toggle')));
    await tester.pump();

    expect(controller.isEditing, isTrue);
    expect(find.text('编辑模式'), findsOneWidget);
    expect(
      tester.widget<CourtView>(find.byType(CourtView)).mode,
      CourtViewMode.editable,
    );
  });
}
