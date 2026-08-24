import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/scoring/widgets/court_painter.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/score_side_panel.dart';

void main() {
  testWidgets('court prompt is announced while a score location is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtView(
            shotLocations: const [],
            locationPrompt: '补充红方 +2 落点 · 8 秒',
          ),
        ),
      ),
    );

    expect(find.text('补充红方 +2 落点 · 8 秒'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
  });

  test('half court geometry preserves FIBA half-court aspect ratio', () {
    final court = HalfCourtGeometry.courtRectForSize(const Size(700, 360));

    expect(court.width / court.height, closeTo(15 / 14, 0.001));
    expect(court.height, 360);
  });

  test('pointFromLocal maps through the visible court rectangle', () {
    const size = Size(700, 360);
    final court = HalfCourtGeometry.courtRectForSize(size);
    final center = pointFromLocal(court.center, size);

    expect(center.x, closeTo(0.5, 0.001));
    expect(center.y, closeTo(0.5, 0.001));
  });

  test('pointFromLocal clamps positions into normalized court bounds', () {
    final point = pointFromLocal(const Offset(250, -20), const Size(200, 100));

    expect(point.x, 1);
    expect(point.y, 0);
  });

  testWidgets('court prompt remains usable in narrow layouts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: CourtView(
              shotLocations: const [],
              locationPrompt: '补充红方 +2 落点 · 8 秒',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('补充红方 +2 落点 · 8 秒'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
  });

  testWidgets('editable court exposes an accessible center-point tap', (
    tester,
  ) async {
    CourtPoint? tappedPoint;
    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 280,
              child: CourtView(
                key: const Key('accessible-court'),
                shotLocations: const [],
                onCourtPointTap: (point) => tappedPoint = point,
                mode: CourtViewMode.editable,
              ),
            ),
          ),
        ),
      );
      final editableCourt = find.semantics.byLabel('篮球场落点编辑区');
      final semantics = tester.getSemantics(
        find.descendant(
          of: find.byKey(const Key('accessible-court')),
          matching: find.byType(Semantics),
        ),
      );
      expect(
        semantics.getSemanticsData().hasAction(ui.SemanticsAction.tap),
        isTrue,
      );

      tester.semantics.tap(editableCourt);
      expect(tappedPoint, isNotNull);
      expect(tappedPoint!.x, closeTo(0.5, 0.01));
      expect(tappedPoint!.y, closeTo(0.5, 0.01));
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets('accessible court tap updates a pending location', (
    tester,
  ) async {
    CourtPoint? updatedPoint;
    final semanticsHandle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 280,
              child: CourtView(
                key: const Key('accessible-pending-court'),
                shotLocations: const [],
                pendingLocation: PendingShotLocation(
                  eventId: 'pending',
                  side: TeamSide.blue,
                  points: 2,
                  point: CourtPoint(x: 0.2, y: 0.2),
                ),
                onPendingLocationChanged: (point) => updatedPoint = point,
                mode: CourtViewMode.editable,
              ),
            ),
          ),
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('篮球场落点编辑区'));
      expect(updatedPoint, isNotNull);
      expect(updatedPoint!.x, closeTo(0.5, 0.01));
      expect(updatedPoint!.y, closeTo(0.5, 0.01));
    } finally {
      semanticsHandle.dispose();
    }
  });

  testWidgets(
    'score side panel does not overflow at 200 percent in a narrow column',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SizedBox(
                width: 88,
                height: 411,
                child: ScoreSidePanel(
                  side: TeamSide.blue,
                  name: 'Blue',
                  score: 12,
                  fouls: 1,
                  onScore: (_) {},
                  onFoul: () {},
                  missEnabled: true,
                  onMiss: () {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
