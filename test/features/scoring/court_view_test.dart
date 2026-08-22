import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/features/scoring/widgets/court_painter.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';
import 'package:hooptrace/features/scoring/widgets/pending_location_bar.dart';

void main() {
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

  testWidgets('pending location bar wraps in narrow layouts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: PendingLocationBar(
              onConfirm: () {},
              onSkip: () {},
              onUndo: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(confirmLocationText), findsOneWidget);
    expect(find.text(skipLocationText), findsOneWidget);
    expect(find.text(undoText), findsOneWidget);
  });
}
