import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/entry/entry_feedback.dart';
import 'package:hooptrace/app/entry/hoop_trace_entry_gate.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';

void main() {
  testWidgets('standard entry emits feedback once and reveals its child', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    var hapticCount = 0;
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.standard,
        haptic: () async => hapticCount++,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byKey(hoopTraceEntryOverlayKey), findsOneWidget);
    expect(feedback.prepareCount, 1);

    await tester.pump(const Duration(milliseconds: 619));
    expect(feedback.playCount, 0);
    expect(hapticCount, 0);

    await tester.pump(const Duration(milliseconds: 2));
    expect(feedback.playCount, 1);
    expect(hapticCount, 1);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(find.byKey(const Key('entry-child')), findsOneWidget);
    expect(feedback.disposeCount, 1);
  });

  testWidgets('standard entry defers the covered page until its final mark', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.standard,
      ),
    );

    expect(find.byKey(const Key('entry-child')), findsNothing);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('entry-child')), findsNothing);

    await tester.pump(const Duration(milliseconds: 621));
    await tester.pump();
    expect(find.byKey(const Key('entry-child')), findsOneWidget);
  });

  testWidgets('standard entry stages the page behind the opaque final mark', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.standard,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 1159));
    expect(find.byKey(const Key('entry-child')), findsNothing);

    await tester.pump(const Duration(milliseconds: 2));
    expect(find.byKey(const Key('entry-child')), findsOneWidget);
    expect(find.byKey(hoopTraceEntryOverlayKey), findsOneWidget);
  });

  testWidgets('standard entry keeps playing beyond the old one-second cut', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.standard,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.byKey(hoopTraceEntryOverlayKey), findsOneWidget);
  });

  testWidgets('tap before the swish completes the mark without feedback', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    var childTapCount = 0;
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.standard,
        onChildTap: () => childTapCount++,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(hoopTraceEntryOverlayKey));
    expect(childTapCount, 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 121));
    await tester.pump();

    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(feedback.playCount, 0);
    expect(feedback.disposeCount, 1);
  });

  testWidgets('reduced preference uses a short silent crossfade', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    var hapticCount = 0;
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.reduced,
        haptic: () async => hapticCount++,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 141));

    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(feedback.prepareCount, 0);
    expect(feedback.playCount, 0);
    expect(hapticCount, 0);
  });

  testWidgets('system disabled animations bypass the overlay immediately', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        media: const MediaQueryData(disableAnimations: true),
      ),
    );

    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(find.byKey(const Key('entry-child')), findsOneWidget);
    expect(feedback.prepareCount, 0);
  });

  testWidgets(
    'standard entry keeps its authored duration when semantics state is stale',
    (tester) async {
      debugSemanticsDisableAnimations = true;
      addTearDown(() => debugSemanticsDisableAnimations = null);
      final feedback = _FakeEntryFeedbackPlayer();

      await tester.pumpWidget(
        _harness(
          feedback: feedback,
          preferenceLoader: () async => MotionPreference.standard,
          media: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(hoopTraceEntryOverlayKey), findsOneWidget);
      expect(feedback.playCount, 0);
    },
  );

  testWidgets('standard timeline begins after the aligned handoff frame', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(_harness(feedback: feedback));
    expect(feedback.prepareCount, 0);

    await tester.pump(const Duration(milliseconds: 700));

    final frame = tester.widget<HoopTraceEntryFrame>(
      find.byKey(hoopTraceEntrySceneKey),
    );
    expect(frame.progress, 0);
    expect(feedback.playCount, 0);
  });

  testWidgets('accessible navigation selects reduced motion', (tester) async {
    final feedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        media: const MediaQueryData(accessibleNavigation: true),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 141));

    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(feedback.prepareCount, 0);
    expect(feedback.playCount, 0);
  });

  testWidgets('a preference timeout safely falls back to reduced motion', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    final pending = Completer<MotionPreference>();
    await tester.pumpWidget(
      _harness(feedback: feedback, preferenceLoader: () => pending.future),
    );
    await tester.pump(const Duration(milliseconds: 81));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 141));

    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(feedback.prepareCount, 0);
    expect(feedback.playCount, 0);
  });

  testWidgets('lifecycle changes do not restart an active entry', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.standard,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(feedback.playCount, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 671));
    await tester.pump();

    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(feedback.playCount, 1);
  });

  testWidgets('leaving the foreground suppresses pending entry feedback', (
    tester,
  ) async {
    final feedback = _FakeEntryFeedbackPlayer();
    var hapticCount = 0;
    await tester.pumpWidget(
      _harness(
        feedback: feedback,
        preferenceLoader: () async => MotionPreference.standard,
        haptic: () async => hapticCount++,
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 550));

    expect(feedback.playCount, 0);
    expect(hapticCount, 0);
  });

  testWidgets('a process session does not replay after widget recreation', (
    tester,
  ) async {
    final session = EntryPlaybackSession();
    final firstFeedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(feedback: firstFeedback, playbackSession: session),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1321));
    await tester.pump();
    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    final secondFeedback = _FakeEntryFeedbackPlayer();
    await tester.pumpWidget(
      _harness(feedback: secondFeedback, playbackSession: session),
    );
    await tester.pump();

    expect(find.byKey(hoopTraceEntryOverlayKey), findsNothing);
    expect(secondFeedback.prepareCount, 0);
    expect(secondFeedback.playCount, 0);
  });

  testWidgets('entry frame remains centered on compact landscape screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: const MediaQuery(
          data: MediaQueryData(size: Size(320, 240)),
          child: HoopTraceEntryFrame(
            key: hoopTraceEntrySceneKey,
            mode: EntryMotionMode.standard,
            progress: 0.5,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(hoopTraceEntrySceneKey), findsOneWidget);
  });

  testWidgets('entry crossfades without allocating opacity layers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: const MediaQuery(
          data: MediaQueryData(size: Size(390, 844)),
          child: HoopTraceEntryFrame(
            mode: EntryMotionMode.standard,
            progress: 0.6,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      tester.layers.whereType<OpacityLayer>().where(
        (layer) => (layer.alpha ?? 255) < 255,
      ),
      isEmpty,
    );
  });

  testWidgets('opening flight enters through the left screen edge', (
    tester,
  ) async {
    const captureKey = Key('entry-flight-capture');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildHoopTraceTheme(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: RepaintBoundary(
            key: captureKey,
            child: HoopTraceEntryFrame(
              mode: EntryMotionMode.standard,
              progress: 300 / HoopTraceEntryTimeline.total.inMilliseconds,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    final orangePixelsAtEdge = await tester.runAsync(() async {
      final image = await boundary.toImage();
      try {
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (bytes == null) return null;
        var count = 0;
        final rgba = bytes.buffer.asUint8List();
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < 12; x++) {
            final offset = (y * image.width + x) * 4;
            final red = rgba[offset];
            final green = rgba[offset + 1];
            final blue = rgba[offset + 2];
            if (red > 220 && green > 50 && green < 130 && blue < 80) {
              count++;
            }
          }
        }
        return count;
      } finally {
        image.dispose();
      }
    });
    expect(orangePixelsAtEdge, isNotNull);
    expect(orangePixelsAtEdge!, greaterThan(5));
  });
}

Widget _harness({
  required _FakeEntryFeedbackPlayer feedback,
  EntryMotionPreferenceLoader? preferenceLoader,
  EntryHapticFeedback? haptic,
  VoidCallback? onChildTap,
  MediaQueryData media = const MediaQueryData(size: Size(390, 844)),
  EntryPlaybackSession? playbackSession,
}) {
  return MaterialApp(
    theme: buildHoopTraceTheme(),
    home: MediaQuery(
      data: media,
      child: HoopTraceEntryGate(
        feedbackPlayer: feedback,
        playbackSession: playbackSession,
        motionPreferenceLoader: preferenceLoader,
        hapticFeedback: haptic,
        child: GestureDetector(
          key: const Key('entry-child'),
          behavior: HitTestBehavior.opaque,
          onTap: onChildTap,
          child: const ColoredBox(color: Colors.blue),
        ),
      ),
    ),
  );
}

class _FakeEntryFeedbackPlayer implements EntryFeedbackPlayer {
  int prepareCount = 0;
  int playCount = 0;
  int disposeCount = 0;

  @override
  Future<void> prepare() async => prepareCount++;

  @override
  Future<void> playSwish() async => playCount++;

  @override
  Future<void> dispose() async => disposeCount++;
}
