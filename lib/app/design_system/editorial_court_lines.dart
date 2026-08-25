import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A deterministic half-court mark used only when a page explicitly opts in.
class EditorialCourtLinesPainter extends CustomPainter {
  const EditorialCourtLinesPainter({required this.color, this.strokeWidth = 1});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;
    final center = Offset(size.width * 0.78, size.height * 0.5);
    final radius = math.min(size.width, size.height) * 0.22;

    canvas.drawLine(
      Offset(size.width * 0.42, 0),
      Offset(size.width * 0.42, size.height),
      paint,
    );
    canvas.drawCircle(center, radius, paint);
    canvas.drawRect(
      Rect.fromLTRB(
        size.width * 0.76,
        size.height * 0.28,
        size.width,
        size.height * 0.72,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.94, size.height * 0.43),
      Offset(size.width * 0.94, size.height * 0.57),
      paint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.55),
      math.pi * 0.58,
      math.pi * 0.84,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant EditorialCourtLinesPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
