import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/court_point.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

class HalfCourtGeometry {
  const HalfCourtGeometry._();

  // FIBA dimensions, in meters. The app records normalized coordinates inside
  // this half-court rectangle so display and replay can share one mapping.
  static const width = 15.0;
  static const depth = 14.0;
  static const aspectRatio = width / depth;

  static Rect courtRectForSize(Size size) {
    if (size.isEmpty) {
      return Rect.zero;
    }

    final availableRatio = size.width / size.height;
    final courtWidth = availableRatio > aspectRatio
        ? size.height * aspectRatio
        : size.width;
    final courtHeight = courtWidth / aspectRatio;

    return Rect.fromLTWH(
      (size.width - courtWidth) / 2,
      (size.height - courtHeight) / 2,
      courtWidth,
      courtHeight,
    );
  }

  static Offset pointToOffset(CourtPoint point, Size size) {
    final court = courtRectForSize(size);
    return Offset(
      court.left + point.x * court.width,
      court.top + point.y * court.height,
    );
  }

  static CourtPoint pointFromLocal(Offset local, Size size) {
    final court = courtRectForSize(size);
    if (court.isEmpty) {
      return CourtPoint(x: 0.5, y: 0.5);
    }

    return CourtPoint(
      x: ((local.dx - court.left) / court.width).clamp(0, 1).toDouble(),
      y: ((local.dy - court.top) / court.height).clamp(0, 1).toDouble(),
    );
  }

  static Offset metersToOffset(Rect court, double x, double y) {
    return Offset(
      court.left + x / width * court.width,
      court.top + y / depth * court.height,
    );
  }

  static Rect metersRect(
    Rect court, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final topLeft = metersToOffset(court, left, top);
    final bottomRight = metersToOffset(court, left + width, top + height);
    return Rect.fromPoints(topLeft, bottomRight);
  }
}

/// Presentation-only marker shown while a committed location is travelling
/// from its score button to the court. It deliberately carries no database
/// identity beyond the receipt location id and never mutates durable state.
class TransientShotMarker {
  const TransientShotMarker({
    required this.id,
    required this.point,
    required this.side,
  });

  final String id;
  final CourtPoint point;
  final TeamSide side;

  String get locationId => id;
}

typedef CourtTransientMarker = TransientShotMarker;

class EraserShotMarker {
  const EraserShotMarker({
    required this.id,
    required this.point,
    required this.progress,
  });

  final String id;
  final CourtPoint point;
  final double progress;
}

class CourtPainter extends CustomPainter {
  const CourtPainter({
    this.shotLocations = const [],
    this.pendingLocation,
    this.detailedShotDraft,
    this.hiddenShotLocationIds = const <String>{},
    this.transientMarkers = const <TransientShotMarker>[],
    this.eraserMarkers = const <EraserShotMarker>[],
  });

  final List<ScoringShotLocation> shotLocations;
  final PendingShotLocation? pendingLocation;
  final DetailedShotDraft? detailedShotDraft;
  final Set<String> hiddenShotLocationIds;
  final List<TransientShotMarker> transientMarkers;
  final List<EraserShotMarker> eraserMarkers;

  @override
  void paint(Canvas canvas, Size size) {
    final court = HalfCourtGeometry.courtRectForSize(size);
    if (court.isEmpty) {
      return;
    }

    final surfacePaint = Paint()
      ..color = HoopTraceColors.cream
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = HoopTraceColors.ink.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mutedLinePaint = Paint()
      ..color = HoopTraceColors.ink.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final rimPaint = Paint()
      ..color = HoopTraceColors.orange.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1;

    final courtShape = RRect.fromRectAndRadius(court, const Radius.circular(8));
    final shadowPath = Path()..addRRect(courtShape);
    canvas.drawShadow(
      shadowPath,
      Colors.black.withValues(alpha: 0.18),
      8,
      true,
    );
    canvas.drawRRect(courtShape, surfacePaint);
    canvas.drawRRect(courtShape, linePaint);

    _drawHalfCourtLines(
      canvas: canvas,
      court: court,
      linePaint: linePaint,
      mutedLinePaint: mutedLinePaint,
      rimPaint: rimPaint,
    );
    _drawMarkers(canvas, size);
  }

  void _drawHalfCourtLines({
    required Canvas canvas,
    required Rect court,
    required Paint linePaint,
    required Paint mutedLinePaint,
    required Paint rimPaint,
  }) {
    const centerX = HalfCourtGeometry.width / 2;
    const basketY = 1.575;
    const freeThrowLineY = 5.8;
    const laneWidth = 4.9;
    const freeThrowLineWidth = 3.6;
    const freeThrowRadius = 1.8;
    const restrictedRadius = 1.25;
    const threePointRadius = 6.75;
    const cornerOffset = 0.9;
    const rimRadius = 0.225;
    const backboardY = 1.2;
    const backboardWidth = 1.8;

    final laneLeft = centerX - laneWidth / 2;
    final laneRect = HalfCourtGeometry.metersRect(
      court,
      left: laneLeft,
      top: 0,
      width: laneWidth,
      height: freeThrowLineY,
    );
    canvas.drawRect(laneRect, linePaint);

    final freeThrowStart = HalfCourtGeometry.metersToOffset(
      court,
      centerX - freeThrowLineWidth / 2,
      freeThrowLineY,
    );
    final freeThrowEnd = HalfCourtGeometry.metersToOffset(
      court,
      centerX + freeThrowLineWidth / 2,
      freeThrowLineY,
    );
    canvas.drawLine(freeThrowStart, freeThrowEnd, linePaint);

    final freeThrowCenter = HalfCourtGeometry.metersToOffset(
      court,
      centerX,
      freeThrowLineY,
    );
    final freeThrowCircle = Rect.fromCircle(
      center: freeThrowCenter,
      radius: freeThrowRadius / HalfCourtGeometry.width * court.width,
    );
    canvas.drawArc(freeThrowCircle, 0, math.pi, false, linePaint);
    canvas.drawArc(freeThrowCircle, math.pi, math.pi, false, mutedLinePaint);

    final basket = HalfCourtGeometry.metersToOffset(court, centerX, basketY);
    final restrictedCircle = Rect.fromCircle(
      center: basket,
      radius: restrictedRadius / HalfCourtGeometry.width * court.width,
    );
    canvas.drawArc(restrictedCircle, 0, math.pi, false, mutedLinePaint);

    final threePointCenter = basket;
    final threePointPixelRadius =
        threePointRadius / HalfCourtGeometry.width * court.width;
    final threePointCircle = Rect.fromCircle(
      center: threePointCenter,
      radius: threePointPixelRadius,
    );
    final cornerDx = centerX - cornerOffset;
    final cornerDy = math.sqrt(
      threePointRadius * threePointRadius - cornerDx * cornerDx,
    );
    final arcStart = math.atan2(cornerDy, cornerDx);
    final arcEnd = math.pi - arcStart;

    canvas
      ..drawLine(
        HalfCourtGeometry.metersToOffset(court, cornerOffset, 0),
        HalfCourtGeometry.metersToOffset(
          court,
          cornerOffset,
          basketY + cornerDy,
        ),
        mutedLinePaint,
      )
      ..drawLine(
        HalfCourtGeometry.metersToOffset(
          court,
          HalfCourtGeometry.width - cornerOffset,
          0,
        ),
        HalfCourtGeometry.metersToOffset(
          court,
          HalfCourtGeometry.width - cornerOffset,
          basketY + cornerDy,
        ),
        mutedLinePaint,
      )
      ..drawArc(
        threePointCircle,
        arcStart,
        arcEnd - arcStart,
        false,
        mutedLinePaint,
      );

    final backboardStart = HalfCourtGeometry.metersToOffset(
      court,
      centerX - backboardWidth / 2,
      backboardY,
    );
    final backboardEnd = HalfCourtGeometry.metersToOffset(
      court,
      centerX + backboardWidth / 2,
      backboardY,
    );
    canvas.drawLine(backboardStart, backboardEnd, linePaint);

    canvas.drawCircle(
      basket,
      rimRadius / HalfCourtGeometry.width * court.width,
      rimPaint,
    );

    final centerCircle = Rect.fromCircle(
      center: HalfCourtGeometry.metersToOffset(
        court,
        centerX,
        HalfCourtGeometry.depth,
      ),
      radius: freeThrowRadius / HalfCourtGeometry.width * court.width,
    );
    canvas.drawArc(centerCircle, math.pi, math.pi, false, mutedLinePaint);
  }

  void _drawMarkers(Canvas canvas, Size size) {
    for (final location in shotLocations) {
      if (hiddenShotLocationIds.contains(location.id)) continue;
      _paintMarker(
        canvas,
        size,
        location.point,
        _sideColor(location.side),
        radius: 6,
        isPending: false,
      );
    }

    final pending = pendingLocation;
    if (pending != null) {
      _paintMarker(
        canvas,
        size,
        pending.point,
        _sideColor(pending.side),
        radius: 9,
        isPending: true,
      );
    }

    final draft = detailedShotDraft;
    if (draft != null) {
      _paintMarker(
        canvas,
        size,
        draft.point,
        _sideColor(draft.side),
        radius: 10,
        isPending: true,
      );
    }

    for (final marker in transientMarkers) {
      _paintMarker(
        canvas,
        size,
        marker.point,
        Colors.grey.shade600,
        radius: 10,
        isPending: true,
      );
    }
    for (final marker in eraserMarkers) {
      final center = HalfCourtGeometry.pointToOffset(marker.point, size);
      final opacity = (1 - marker.progress.clamp(0.0, 1.0)) * 0.75;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, 12 + marker.progress * 8, paint);
    }
  }

  void _paintMarker(
    Canvas canvas,
    Size size,
    CourtPoint point,
    Color color, {
    required double radius,
    required bool isPending,
  }) {
    final center = HalfCourtGeometry.pointToOffset(point, size);
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPending ? 3 : 2;
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius + 1, ringPaint);
  }

  Color _sideColor(TeamSide? side) {
    if (side == null) return Colors.grey.shade600;
    return side == TeamSide.red ? HoopTraceColors.red : HoopTraceColors.blue;
  }

  @override
  bool shouldRepaint(covariant CourtPainter oldDelegate) {
    return oldDelegate.shotLocations != shotLocations ||
        oldDelegate.pendingLocation != pendingLocation ||
        oldDelegate.detailedShotDraft != detailedShotDraft ||
        oldDelegate.hiddenShotLocationIds != hiddenShotLocationIds ||
        oldDelegate.transientMarkers != transientMarkers ||
        oldDelegate.eraserMarkers != eraserMarkers;
  }
}
