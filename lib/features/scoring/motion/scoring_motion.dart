import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

/// Presentation policy for a scoring hero. It intentionally has no persistence
/// or controller dependency, so a dropped frame cannot affect a score commit.
enum ScoringMotionMode { standard, reduced, disabled }

class ScoringMotionEvent {
  const ScoringMotionEvent({
    required this.receipt,
    Offset? sourceButton,
    Offset? sourceButtonCoordinate,
    required this.courtBounds,
    required this.safeWorkspace,
    this.sourceIdentity,
    this.geometryAvailable = true,
    this.assetAvailable = true,
  }) : assert(
         sourceButton != null || sourceButtonCoordinate != null,
         'A score-button coordinate is required for a motion event.',
       ),
       sourceButton = sourceButton ?? sourceButtonCoordinate ?? Offset.zero;

  final ShotLocationCommitReceipt receipt;
  final Offset sourceButton;
  Offset get sourceButtonCoordinate => sourceButton;
  final Rect courtBounds;
  final Rect safeWorkspace;
  final String? sourceIdentity;
  final bool geometryAvailable;
  final bool assetAvailable;

  String get id => receipt.eventId;
  String get locationId => receipt.shotLocationId;
  String get stableSourceIdentity =>
      sourceIdentity ?? '${receipt.side.name}:${receipt.points}';

  Offset get destination => Offset(
    courtBounds.left + (receipt.point.x * courtBounds.width),
    courtBounds.top + (receipt.point.y * courtBounds.height),
  );

  ScoringMotionPath get path => ScoringMotionPath.build(
    source: sourceButton,
    destination: destination,
    safeWorkspace: safeWorkspace,
  );
}

class ScoringMotionPath {
  ScoringMotionPath._({
    required this.source,
    required this.destination,
    required this.control1,
    required this.control2,
    required this.safeWorkspace,
    required ui.Path path,
  }) : _path = path;

  final Offset source;
  final Offset destination;
  final Offset control1;
  final Offset control2;
  final Rect safeWorkspace;
  final ui.Path _path;

  static ScoringMotionPath build({
    required Offset source,
    required Offset destination,
    required Rect safeWorkspace,
  }) {
    final distance = (destination - source).distance;
    final arc = (distance * .22).clamp(56.0, 160.0).toDouble();
    final topRoom = math.min(source.dy, destination.dy) - safeWorkspace.top;
    Offset c1;
    Offset c2;
    if (topRoom >= arc) {
      c1 = Offset(source.dx, source.dy - arc);
      c2 = Offset(destination.dx, destination.dy - arc);
    } else {
      final leftRoom = math.min(source.dx, destination.dx) - safeWorkspace.left;
      final rightRoom =
          safeWorkspace.right - math.max(source.dx, destination.dx);
      final direction = rightRoom >= leftRoom ? 1.0 : -1.0;
      c1 = source + Offset(direction * arc, 0);
      c2 = destination + Offset(direction * arc, 0);
    }
    c1 = _clampOffset(c1, safeWorkspace);
    c2 = _clampOffset(c2, safeWorkspace);
    final path = ui.Path()
      ..moveTo(source.dx, source.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, destination.dx, destination.dy);
    return ScoringMotionPath._(
      source: source,
      destination: destination,
      control1: c1,
      control2: c2,
      safeWorkspace: safeWorkspace,
      path: path,
    );
  }

  static ScoringMotionPath calculate({
    required Offset source,
    required Offset destination,
    required Rect safeWorkspace,
  }) => build(
    source: source,
    destination: destination,
    safeWorkspace: safeWorkspace,
  );

  ui.Path get path => _path;

  ScoringMotionSample sample(double progress) {
    final p = progress.clamp(0.0, 1.0).toDouble();
    final metric = _path.computeMetrics().first;
    final distance = metric.length * p;
    final tangent = metric.getTangentForOffset(distance);
    final resolved = tangent ?? ui.Tangent(destination, destination - source);
    final count = math.max(1, math.min(12, (p * 12).ceil()));
    final trail = <ScoringTrailNode>[];
    for (var i = 0; i < count; i++) {
      final trailProgress = (p - (i * .035)).clamp(0.0, 1.0).toDouble();
      final trailTangent = metric.getTangentForOffset(
        metric.length * trailProgress,
      );
      trail.add(
        ScoringTrailNode(
          position: trailTangent?.position ?? resolved.position,
          opacity: math.max(.08, .72 * (1 - (i / count))),
        ),
      );
    }
    return ScoringMotionSample(
      position: resolved.position,
      tangent: resolved,
      trail: List.unmodifiable(trail),
    );
  }
}

Offset _clampOffset(Offset point, Rect bounds) => Offset(
  point.dx.clamp(bounds.left, bounds.right).toDouble(),
  point.dy.clamp(bounds.top, bounds.bottom).toDouble(),
);

class ScoringMotionSample {
  const ScoringMotionSample({
    required this.position,
    required this.tangent,
    required this.trail,
  });

  final Offset position;
  final ui.Tangent tangent;
  final List<ScoringTrailNode> trail;
}

class ScoringTrailNode {
  const ScoringTrailNode({required this.position, required this.opacity});

  final Offset position;
  final double opacity;
}

class ScoringMotionTiming {
  const ScoringMotionTiming({required this.flight, required this.impact});

  final Duration flight;
  final Duration impact;
  Duration get total => flight + impact;
}

class ScoringActiveMotion {
  ScoringActiveMotion({required this.event, required this.timing});

  final ScoringMotionEvent event;
  final ScoringMotionTiming timing;
  Duration elapsed = Duration.zero;

  double get progress => timing.flight == Duration.zero
      ? 1
      : (elapsed.inMicroseconds / timing.flight.inMicroseconds)
            .clamp(0.0, 1.0)
            .toDouble();

  bool get inImpact => elapsed >= timing.flight;
  ScoringMotionSample get sample => event.path.sample(progress);
}

typedef ScoringMotionCallback = void Function(ScoringMotionEvent event);

class ScoringMotionCoordinator extends ChangeNotifier {
  ScoringMotionCoordinator({
    this.motionTheme = const HoopTraceMotionTheme.light(),
    this.mode = ScoringMotionMode.standard,
    this.onComplete,
    this.onFallback,
  });

  final HoopTraceMotionTheme motionTheme;
  final ScoringMotionMode mode;
  final ScoringMotionCallback? onComplete;
  final ScoringMotionCallback? onFallback;
  final List<ScoringMotionEvent> _queue = <ScoringMotionEvent>[];
  ScoringActiveMotion? _active;
  bool _disposed = false;

  ScoringActiveMotion? get active => _active;
  List<ScoringMotionEvent> get queuedEvents => List.unmodifiable(_queue);
  int get pendingCount => (_active == null ? 0 : 1) + _queue.length;

  bool submit(ScoringMotionEvent event) {
    if (_disposed) return false;
    if (mode != ScoringMotionMode.standard ||
        !event.geometryAvailable ||
        !event.assetAvailable) {
      onFallback?.call(event);
      onComplete?.call(event);
      return true;
    }
    final accelerate = pendingCount + 1 > 3;
    final timing = _timing(accelerated: accelerate);
    // Once the visual backlog crosses three, all already-queued (not the
    // currently flying) items use the same accelerated policy. This makes the
    // policy deterministic and guarantees a five-shot burst drains promptly.
    if (accelerate) {
      for (final queued in _queue) {
        _timings[queued.id] = _timing(accelerated: true);
      }
    }
    if (_active == null) {
      _active = ScoringActiveMotion(event: event, timing: timing);
    } else {
      _queue.add(event);
      _timings[event.id] = timing;
    }
    notifyListeners();
    return true;
  }

  final Map<String, ScoringMotionTiming> _timings = {};

  ScoringMotionTiming _timing({required bool accelerated}) =>
      ScoringMotionTiming(
        flight: accelerated
            ? motionTheme.acceleratedScoreFlight
            : motionTheme.scoreFlight,
        impact: accelerated
            ? motionTheme.acceleratedImpact
            : motionTheme.impact,
      );

  void advance(Duration elapsed) {
    if (_disposed || elapsed <= Duration.zero) return;
    var remaining = elapsed;
    while (_active != null && remaining > Duration.zero) {
      final current = _active!;
      final left = current.timing.total - current.elapsed;
      if (remaining < left) {
        current.elapsed += remaining;
        remaining = Duration.zero;
      } else {
        remaining -= left;
        final finished = current.event;
        _active = null;
        onComplete?.call(finished);
        _startNext();
      }
    }
    notifyListeners();
  }

  bool cancelByEventId(String eventId) => _cancel(eventId, byLocation: false);

  bool cancelByLocationId(String locationId) =>
      _cancel(locationId, byLocation: true);

  bool _cancel(String identifier, {required bool byLocation}) {
    if (_disposed) return false;
    if (_active != null &&
        (byLocation ? _active!.event.locationId : _active!.event.id) ==
            identifier) {
      _active = null;
      _startNext();
      notifyListeners();
      return true;
    }
    final before = _queue.length;
    _queue.removeWhere(
      (event) => (byLocation ? event.locationId : event.id) == identifier,
    );
    if (_queue.length != before) {
      _timings.remove(identifier);
      notifyListeners();
      return true;
    }
    return false;
  }

  void _startNext() {
    if (_queue.isEmpty || _disposed) return;
    final event = _queue.removeAt(0);
    final timing =
        _timings.remove(event.id) ??
        ScoringMotionTiming(
          flight: motionTheme.scoreFlight,
          impact: motionTheme.impact,
        );
    _active = ScoringActiveMotion(event: event, timing: timing);
  }

  @override
  void dispose() {
    _disposed = true;
    _active = null;
    _queue.clear();
    _timings.clear();
    super.dispose();
  }
}

class ScoringMotionOverlay extends StatelessWidget {
  const ScoringMotionOverlay({required this.coordinator, super.key});

  final ScoringMotionCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: ScoringMotionPainter(coordinator),
        size: Size.infinite,
      ),
    );
  }
}

class ScoringMotionPainter extends CustomPainter {
  ScoringMotionPainter(this.coordinator) : super(repaint: coordinator);

  final ScoringMotionCoordinator coordinator;

  @override
  void paint(Canvas canvas, Size size) {
    final active = coordinator.active;
    if (active == null) return;
    final sample = active.sample;
    final paint = Paint()..color = Colors.white;
    for (final node in sample.trail) {
      canvas.drawCircle(
        node.position,
        5,
        paint..color = Colors.white.withValues(alpha: node.opacity),
      );
    }
    canvas.drawCircle(sample.position, 8, paint..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant ScoringMotionPainter oldDelegate) =>
      oldDelegate.coordinator != coordinator;
}
