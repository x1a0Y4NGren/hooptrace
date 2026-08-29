import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/entry/hoop_trace_entry_gate.dart';

void main() {
  for (final frame in <String, int>{
    'handoff': 0,
    'flight': 300,
    'swish': 680,
    'lock': 860,
    'brand': 1160,
  }.entries) {
    testWidgets('entry animation ${frame.key} frame', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildHoopTraceTheme(),
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: RepaintBoundary(
              key: const Key('entry-golden'),
              child: HoopTraceEntryFrame(
                mode: EntryMotionMode.standard,
                progress:
                    frame.value / HoopTraceEntryTimeline.total.inMilliseconds,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('entry-golden')),
        matchesGoldenFile('goldens/entry_${frame.key}.png'),
      );
    });
  }
}
