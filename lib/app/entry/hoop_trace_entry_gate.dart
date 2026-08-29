import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooptrace/app/design_system/editorial_motion.dart';
import 'package:hooptrace/app/design_system/editorial_tokens.dart';
import 'package:hooptrace/app/entry/entry_feedback.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';

const hoopTraceEntryOverlayKey = Key('hooptrace-entry-overlay');
const hoopTraceEntrySceneKey = Key('hooptrace-entry-scene');

enum EntryMotionMode { standard, reduced, disabled }

abstract final class HoopTraceEntryTimeline {
  static const total = Duration(milliseconds: 1320);
  static const handoffEnd = Duration(milliseconds: 80);
  static const flightRevealEnd = Duration(milliseconds: 170);
  static const flightEnd = Duration(milliseconds: 620);
  static const swishEnd = Duration(milliseconds: 760);
  static const lockEnd = Duration(milliseconds: 960);
  static const scalePeak = Duration(milliseconds: 1090);
  static const scaleEnd = Duration(milliseconds: 1160);
}

typedef EntryMotionPreferenceLoader = Future<MotionPreference> Function();
typedef EntryHapticFeedback = Future<void> Function();

class EntryPlaybackSession {
  bool _claimed = false;

  bool claim() {
    if (_claimed) return false;
    _claimed = true;
    return true;
  }
}

class HoopTraceEntryGate extends StatefulWidget {
  const HoopTraceEntryGate({
    required this.child,
    this.motionPreferenceLoader,
    this.feedbackPlayer,
    this.hapticFeedback,
    this.playbackSession,
    super.key,
  });

  final Widget child;
  final EntryMotionPreferenceLoader? motionPreferenceLoader;
  final EntryFeedbackPlayer? feedbackPlayer;
  final EntryHapticFeedback? hapticFeedback;
  final EntryPlaybackSession? playbackSession;

  @override
  State<HoopTraceEntryGate> createState() => _HoopTraceEntryGateState();
}

class _HoopTraceEntryGateState extends State<HoopTraceEntryGate>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final EntryFeedbackPlayer _feedbackPlayer =
      widget.feedbackPlayer ?? AssetEntryFeedbackPlayer();

  HoopTraceMotionTheme _motion = const HoopTraceMotionTheme.light();
  EntryMotionMode? _mode;
  bool _decisionStarted = false;
  bool _visible = true;
  bool _feedbackEmitted = false;
  bool _skipping = false;
  bool _childMounted = false;
  bool _resumeAfterChildMountScheduled = false;
  bool _feedbackDisposed = false;
  bool _feedbackSuppressedByLifecycle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller =
        AnimationController(
            vsync: this,
            animationBehavior: AnimationBehavior.preserve,
          )
          ..addListener(_handleProgress)
          ..addStatusListener(_handleStatus);
    if (widget.playbackSession?.claim() == false) {
      _decisionStarted = true;
      _mode = EntryMotionMode.disabled;
      _visible = false;
      _feedbackDisposed = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion =
        Theme.of(context).extension<HoopTraceMotionTheme>() ??
        const HoopTraceMotionTheme.light();
    if (_decisionStarted) return;
    _decisionStarted = true;

    final media = MediaQuery.maybeOf(context);
    if (media?.disableAnimations == true) {
      _mode = EntryMotionMode.disabled;
      _visible = false;
      _disposeFeedbackBestEffort();
      return;
    }
    _precacheBrandAssets();
    if (media?.accessibleNavigation == true) {
      _start(EntryMotionMode.reduced);
      return;
    }
    unawaited(_resolvePersistedPreference());
  }

  void _precacheBrandAssets() {
    unawaited(
      precacheImage(
        const AssetImage('assets/icons/hooptrace-app-icon-foreground.png'),
        context,
      ).catchError((Object _) {}),
    );
  }

  Future<void> _resolvePersistedPreference() async {
    final loader = widget.motionPreferenceLoader;
    MotionPreference preference;
    if (loader == null) {
      preference = MotionPreference.standard;
    } else {
      try {
        preference = await loader().timeout(
          _motion.entryPreferenceWait,
          onTimeout: () => MotionPreference.reduced,
        );
      } on Object {
        preference = MotionPreference.reduced;
      }
    }
    if (!mounted || !_visible || _skipping) return;
    _start(
      preference == MotionPreference.reduced
          ? EntryMotionMode.reduced
          : EntryMotionMode.standard,
    );
  }

  void _start(EntryMotionMode mode) {
    if (!_visible || mode == EntryMotionMode.disabled) return;
    _mode = mode;
    _controller.duration = mode == EntryMotionMode.standard
        ? _motion.entry
        : _motion.entryReduced;
    _controller.value = 0;
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_visible || _skipping || _controller.isAnimating) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_visible || _skipping || _controller.isAnimating) {
          return;
        }
        if (mode == EntryMotionMode.standard) {
          unawaited(_runBestEffort(_feedbackPlayer.prepare));
        }
        unawaited(_controller.forward());
      });
      WidgetsBinding.instance.scheduleFrame();
    });
  }

  void _handleProgress() {
    _stageChildBehindFinalMark();
    if (_mode != EntryMotionMode.standard ||
        _skipping ||
        _feedbackEmitted ||
        _feedbackSuppressedByLifecycle) {
      return;
    }
    final swishFraction =
        HoopTraceEntryTimeline.flightEnd.inMicroseconds /
        HoopTraceEntryTimeline.total.inMicroseconds;
    if (_controller.value < swishFraction) return;
    _feedbackEmitted = true;
    unawaited(_runBestEffort(_feedbackPlayer.playSwish));
    unawaited(
      _runBestEffort(widget.hapticFeedback ?? HapticFeedback.lightImpact),
    );
  }

  void _stageChildBehindFinalMark() {
    final stageFraction =
        HoopTraceEntryTimeline.scaleEnd.inMicroseconds /
        HoopTraceEntryTimeline.total.inMicroseconds;
    if (_mode != EntryMotionMode.standard ||
        _skipping ||
        _childMounted ||
        _controller.value < stageFraction) {
      return;
    }

    _childMounted = true;
    if (_controller.value >= 1) return;

    _controller.stop(canceled: false);
    setState(() {});
    if (_resumeAfterChildMountScheduled) return;
    _resumeAfterChildMountScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumeAfterChildMountScheduled = false;
      if (!mounted || !_visible || _skipping || _controller.isCompleted) {
        return;
      }
      unawaited(_controller.forward());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_feedbackEmitted) {
      _feedbackSuppressedByLifecycle = true;
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _skip() {
    if (!_visible || _skipping) return;
    _skipping = true;
    if (_mode == null) {
      _mode = EntryMotionMode.reduced;
      _controller.duration = _motion.entrySkip;
      if (mounted) setState(() {});
      unawaited(_controller.forward());
      return;
    }
    final duration = _remainingSkipDuration();
    unawaited(
      _controller.animateTo(1, duration: duration, curve: Curves.easeOutCubic),
    );
  }

  Duration _remainingSkipDuration() {
    final configured = _motion.entrySkip;
    final base = _controller.duration ?? configured;
    final remainingMicros = (base.inMicroseconds * (1 - _controller.value))
        .round();
    return Duration(
      microseconds: math.min(configured.inMicroseconds, remainingMicros),
    );
  }

  void _finish() {
    if (!_visible || !mounted) return;
    setState(() => _visible = false);
    _disposeFeedbackBestEffort();
  }

  Future<void> _runBestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Entry feedback is decorative and must never gate application startup.
    }
  }

  void _disposeFeedbackBestEffort() {
    if (_feedbackDisposed) return;
    _feedbackDisposed = true;
    unawaited(_runBestEffort(_feedbackPlayer.dispose));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _disposeFeedbackBestEffort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible && !_childMounted) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_childMounted) widget.child,
        if (_visible)
          Positioned.fill(
            child: BlockSemantics(
              child: ExcludeSemantics(
                child: GestureDetector(
                  key: hoopTraceEntryOverlayKey,
                  behavior: HitTestBehavior.opaque,
                  onTap: _skip,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => HoopTraceEntryFrame(
                      key: hoopTraceEntrySceneKey,
                      mode: _mode,
                      progress: _controller.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HoopTraceEntryFrame extends StatelessWidget {
  const HoopTraceEntryFrame({
    required this.mode,
    required this.progress,
    super.key,
  }) : assert(progress >= 0 && progress <= 1);

  final EntryMotionMode? mode;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final shortestSide = mediaSize.shortestSide;
    final visibleMarkSize = (shortestSide * 0.42).clamp(144.0, 208.0);
    final canvasExtent = visibleMarkSize * (1024 / 544);

    final overlayOpacity = switch (mode) {
      EntryMotionMode.reduced => 1 - Curves.easeInCubic.transform(progress),
      EntryMotionMode.standard =>
        1 -
            _entryInterval(
              progress,
              HoopTraceEntryTimeline.scaleEnd,
              HoopTraceEntryTimeline.total,
              Curves.easeInCubic,
            ),
      EntryMotionMode.disabled => 0.0,
      null => 1.0,
    };

    return Opacity(
      opacity: overlayOpacity.clamp(0.0, 1.0),
      child: ColoredBox(
        color: HoopTraceColors.ink,
        child: _buildScene(canvasExtent),
      ),
    );
  }

  Widget _buildScene(double canvasExtent) {
    if (mode == null) {
      return _centerMark(
        canvasExtent,
        Transform.scale(scale: 0.78, child: const _HoopAsset()),
      );
    }
    if (mode == EntryMotionMode.reduced) {
      return _centerMark(
        canvasExtent,
        Stack(
          fit: StackFit.expand,
          children: [
            _HoopAsset(opacity: 1 - progress),
            _FinalBrandAsset(opacity: Curves.easeOutCubic.transform(progress)),
          ],
        ),
      );
    }
    if (mode == EntryMotionMode.disabled) return const SizedBox.shrink();

    final scale = _standardScale(progress);
    final hoopOpacity =
        1 -
        _entryInterval(
          progress,
          HoopTraceEntryTimeline.handoffEnd,
          HoopTraceEntryTimeline.flightRevealEnd,
          Curves.easeInCubic,
        );
    final painterOpacity = math.min(
      _entryInterval(
        progress,
        HoopTraceEntryTimeline.handoffEnd,
        HoopTraceEntryTimeline.flightRevealEnd,
        Curves.easeOutCubic,
      ),
      1 -
          _entryInterval(
            progress,
            HoopTraceEntryTimeline.swishEnd,
            HoopTraceEntryTimeline.lockEnd,
            Curves.easeInOutCubic,
          ),
    );
    final finalOpacity = _entryInterval(
      progress,
      HoopTraceEntryTimeline.swishEnd,
      HoopTraceEntryTimeline.lockEnd,
      Curves.easeOutCubic,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _EntryScenePainter(
              progress: progress,
              opacity: painterOpacity,
              markExtent: canvasExtent,
            ),
            isComplex: true,
            willChange: true,
          ),
        ),
        _centerMark(
          canvasExtent,
          Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: 0.78,
                child: _HoopAsset(opacity: hoopOpacity),
              ),
              Transform.scale(
                scale: scale,
                child: _FinalBrandAsset(opacity: finalOpacity),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _centerMark(double canvasExtent, Widget child) {
    return Center(
      child: RepaintBoundary(
        child: SizedBox.square(dimension: canvasExtent, child: child),
      ),
    );
  }

  double _standardScale(double t) {
    final logoScale = switch (_milliseconds(t)) {
      < 960 => 0.78,
      < 1090 => _lerp(
        0.78,
        1.03,
        _entryInterval(
          t,
          HoopTraceEntryTimeline.lockEnd,
          HoopTraceEntryTimeline.scalePeak,
          Curves.easeOutCubic,
        ),
      ),
      < 1160 => _lerp(
        1.03,
        1,
        _entryInterval(
          t,
          HoopTraceEntryTimeline.scalePeak,
          HoopTraceEntryTimeline.scaleEnd,
          Curves.easeInOutCubic,
        ),
      ),
      _ => 1.0,
    };
    final exitScale = _lerp(
      1,
      1.04,
      _entryInterval(
        t,
        HoopTraceEntryTimeline.scaleEnd,
        HoopTraceEntryTimeline.total,
        Curves.easeInCubic,
      ),
    );
    return logoScale * exitScale;
  }
}

class _HoopAsset extends StatelessWidget {
  const _HoopAsset({this.opacity = 1});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _EntryScenePainter(progress: 0, opacity: opacity),
      isComplex: true,
    );
  }
}

class _FinalBrandAsset extends StatelessWidget {
  const _FinalBrandAsset({this.opacity = 1});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/hooptrace-app-icon-foreground.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      opacity: AlwaysStoppedAnimation(opacity),
    );
  }
}

class _EntryScenePainter extends CustomPainter {
  const _EntryScenePainter({
    required this.progress,
    this.opacity = 1,
    this.markExtent,
  });

  final double progress;
  final double opacity;
  final double? markExtent;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paintsViewport = markExtent != null;
    final scale =
        (markExtent ?? size.width) / 1024 * (paintsViewport ? 0.78 : 1);
    final origin = paintsViewport
        ? Offset(
            (size.width - (1024 * scale)) / 2,
            (size.height - (1024 * scale)) / 2,
          )
        : Offset.zero;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale, scale);

    final milliseconds = _milliseconds(progress);
    final flight = _entryInterval(
      progress,
      HoopTraceEntryTimeline.handoffEnd,
      HoopTraceEntryTimeline.flightEnd,
      Curves.easeInOutCubic,
    );
    final swish = _entryInterval(
      progress,
      HoopTraceEntryTimeline.flightEnd,
      HoopTraceEntryTimeline.swishEnd,
      Curves.easeOutCubic,
    );
    final lock = _entryInterval(
      progress,
      HoopTraceEntryTimeline.swishEnd,
      HoopTraceEntryTimeline.lockEnd,
      Curves.easeInOutCubic,
    );

    _paintBackboard(canvas);
    _paintRimAndNet(canvas, swish);

    final arc = paintsViewport
        ? _buildViewportFlightArc(size, origin, scale)
        : (Path()
            ..moveTo(332, 300)
            ..cubicTo(478, 307, 626, 437, 568, 607));
    final drop = Path()
      ..moveTo(568, 607)
      ..cubicTo(566, 647, 560, 688, 548, 716);
    final orange = Paint()
      ..color = HoopTraceColors.orange.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 45
      ..strokeCap = StrokeCap.round;
    final arcMetric = arc.computeMetrics().single;
    if (flight > 0) {
      final start = math.min(82.0, arcMetric.length * flight);
      final end = arcMetric.length * flight;
      if (end > start) {
        canvas.drawPath(arcMetric.extractPath(start, end), orange);
      }
    }

    if (milliseconds >= HoopTraceEntryTimeline.swishEnd.inMilliseconds &&
        milliseconds < HoopTraceEntryTimeline.lockEnd.inMilliseconds) {
      canvas.drawPath(arc, orange);
      final pulseCenter = arcMetric.length * (1 - lock);
      final pulseStart = math.max(0.0, pulseCenter - 66);
      final pulseEnd = math.min(arcMetric.length, pulseCenter + 66);
      final halo = Paint()
        ..color = HoopTraceColors.orange.withValues(alpha: 0.32 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 78
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(arcMetric.extractPath(pulseStart, pulseEnd), halo);
    }

    if (milliseconds >= HoopTraceEntryTimeline.handoffEnd.inMilliseconds &&
        milliseconds < HoopTraceEntryTimeline.swishEnd.inMilliseconds) {
      late final Offset ballCenter;
      late final Offset tangent;
      late final double ballOpacity;
      if (milliseconds < HoopTraceEntryTimeline.flightEnd.inMilliseconds) {
        final sample = arcMetric.getTangentForOffset(
          arcMetric.length * flight,
        )!;
        ballCenter = sample.position;
        tangent = sample.vector;
        ballOpacity = 1;
      } else {
        final dropMetric = drop.computeMetrics().single;
        final sample = dropMetric.getTangentForOffset(
          dropMetric.length * swish,
        )!;
        ballCenter = sample.position;
        tangent = sample.vector;
        ballOpacity = 1 - Curves.easeInCubic.transform(swish);
      }
      _paintBall(
        canvas,
        center: ballCenter,
        tangent: tangent,
        rotationProgress: flight,
        opacity: ballOpacity * opacity,
        squeeze: math.sin(math.pi * swish) * 0.06,
      );
    }

    canvas.restore();
  }

  Path _buildViewportFlightArc(Size viewport, Offset origin, double scale) {
    Offset toDesign(Offset point) =>
        Offset((point.dx - origin.dx) / scale, (point.dy - origin.dy) / scale);

    final ballRadius = 91 * scale;
    final start = Offset(
      -ballRadius * 1.35,
      math.max(ballRadius * 1.5, viewport.height * 0.18),
    );
    final end = origin + Offset(568 * scale, 607 * scale);
    final firstControl = Offset(
      viewport.width * 0.16,
      math.max(ballRadius * 0.6, viewport.height * 0.04),
    );
    final secondControl = Offset(
      end.dx + (viewport.width * 0.14),
      end.dy - (viewport.height * 0.31),
    );
    final startDesign = toDesign(start);
    final firstControlDesign = toDesign(firstControl);
    final secondControlDesign = toDesign(secondControl);
    final endDesign = toDesign(end);
    return Path()
      ..moveTo(startDesign.dx, startDesign.dy)
      ..cubicTo(
        firstControlDesign.dx,
        firstControlDesign.dy,
        secondControlDesign.dx,
        secondControlDesign.dy,
        endDesign.dx,
        endDesign.dy,
      );
  }

  void _paintBackboard(Canvas canvas) {
    final paint = Paint()
      ..color = HoopTraceColors.offWhite.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final outer = Path()
      ..moveTo(390, 379)
      ..lineTo(767, 379)
      ..lineTo(767, 642)
      ..lineTo(329, 642)
      ..lineTo(329, 417);
    canvas.drawPath(outer, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(457, 482, 636, 610),
        const Radius.circular(3),
      ),
      paint..strokeWidth = 24,
    );
  }

  void _paintRimAndNet(Canvas canvas, double swish) {
    final reaction = math.sin(math.pi * swish);
    canvas.save();
    canvas.translate(0, reaction * 10);
    final rimPaint = Paint()
      ..color = HoopTraceColors.offWhite.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawOval(const Rect.fromLTRB(416, 583, 681, 652), rimPaint);

    final netSqueeze = 1 - reaction * 0.045;
    canvas.translate(548, 642);
    canvas.scale(netSqueeze, 1 - reaction * 0.025);
    canvas.translate(-548, -642);
    final net = Path()
      ..moveTo(438, 636)
      ..quadraticBezierTo(470, 724, 483, 807)
      ..moveTo(657, 636)
      ..quadraticBezierTo(626, 724, 613, 807)
      ..moveTo(470, 642)
      ..quadraticBezierTo(520, 720, 613, 807)
      ..moveTo(626, 642)
      ..quadraticBezierTo(576, 720, 483, 807)
      ..moveTo(505, 642)
      ..quadraticBezierTo(526, 721, 577, 793)
      ..moveTo(590, 642)
      ..quadraticBezierTo(570, 721, 518, 793);
    canvas.drawPath(net, rimPaint..strokeWidth = 18);
    canvas.restore();
  }

  void _paintBall(
    Canvas canvas, {
    required Offset center,
    required Offset tangent,
    required double rotationProgress,
    required double opacity,
    required double squeeze,
  }) {
    if (opacity <= 0) return;
    final angle = math.atan2(tangent.dy, tangent.dx);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle * 0.16 + rotationProgress * math.pi * 0.72);
    canvas.scale(1 + squeeze, 1 - squeeze);

    final orange = Paint()
      ..color = HoopTraceColors.orange.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final ballRect = Rect.fromCircle(center: Offset.zero, radius: 91);
    canvas.drawOval(ballRect, orange);
    canvas.clipPath(Path()..addOval(ballRect));
    final seam = Paint()
      ..color = HoopTraceColors.ink.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-91, 0), const Offset(91, 0), seam);
    canvas.drawPath(
      Path()
        ..moveTo(-49, -80)
        ..cubicTo(2, -42, 15, 42, 49, 80),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(48, -80)
        ..cubicTo(22, -33, -21, 28, -73, 57),
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-91, -23)
        ..cubicTo(-26, -31, 24, 6, 91, 47),
      seam,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EntryScenePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.markExtent != markExtent;
  }
}

double _interval(
  double progress,
  double startMilliseconds,
  double endMilliseconds,
  Curve curve,
) {
  final milliseconds = _milliseconds(progress);
  final normalized =
      ((milliseconds - startMilliseconds) /
              (endMilliseconds - startMilliseconds))
          .clamp(0.0, 1.0);
  return curve.transform(normalized);
}

double _entryInterval(
  double progress,
  Duration start,
  Duration end,
  Curve curve,
) {
  return _interval(
    progress,
    start.inMicroseconds / Duration.microsecondsPerMillisecond,
    end.inMicroseconds / Duration.microsecondsPerMillisecond,
    curve,
  );
}

double _milliseconds(double progress) {
  return progress * HoopTraceEntryTimeline.total.inMilliseconds;
}

double _lerp(double begin, double end, double t) {
  return begin + (end - begin) * t;
}
