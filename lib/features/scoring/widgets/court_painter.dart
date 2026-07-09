import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';

class CourtPainter extends CustomPainter {
  const CourtPainter({
    this.shotLocations = const [],
    this.pendingLocation,
  });

  final List<ScoringShotLocation> shotLocations;
  final PendingShotLocation? pendingLocation;

  @override
  void paint(Canvas canvas, Size size) {
    final surfacePaint = Paint()
      ..color = HoopTraceColors.cream
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = HoopTraceColors.ink.withValues(alpha: 0.68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final mutedLinePaint = Paint()
      ..color = HoopTraceColors.ink.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final courtRect = Offset.zero & size;
    final court = RRect.fromRectAndRadius(
      courtRect,
      const Radius.circular(8),
    );
    canvas.drawRRect(court, surfacePaint);
    canvas.drawRRect(court, linePaint);

    final center = Offset(size.width / 2, size.height * 0.12);
    final paintArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.18),
      width: size.width * 0.2,
      height: size.height * 0.26,
    );
    canvas.drawRect(paintArea, linePaint);
    canvas.drawCircle(center, size.shortestSide * 0.055, linePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.shortestSide * 0.19),
      0,
      3.14159,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.08),
        radius: size.shortestSide * 0.43,
      ),
      0,
      3.14159,
      false,
      mutedLinePaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.72),
      mutedLinePaint,
    );

    for (final location in shotLocations) {
      _paintMarker(
        canvas,
        size,
        location.point.x,
        location.point.y,
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
        pending.point.x,
        pending.point.y,
        _sideColor(pending.side),
        radius: 9,
        isPending: true,
      );
    }
  }

  void _paintMarker(
    Canvas canvas,
    Size size,
    double x,
    double y,
    Color color, {
    required double radius,
    required bool isPending,
  }) {
    final center = Offset(x * size.width, y * size.height);
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

  Color _sideColor(TeamSide side) {
    return side == TeamSide.red ? HoopTraceColors.red : HoopTraceColors.blue;
  }

  @override
  bool shouldRepaint(covariant CourtPainter oldDelegate) {
    return oldDelegate.shotLocations != shotLocations ||
        oldDelegate.pendingLocation != pendingLocation;
  }
}
