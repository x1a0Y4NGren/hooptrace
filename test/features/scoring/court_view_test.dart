import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/features/scoring/widgets/court_view.dart';

void main() {
  test('pointFromLocal clamps positions into normalized court bounds', () {
    final point = pointFromLocal(
      const Offset(250, -20),
      const Size(200, 100),
    );

    expect(point.x, 1);
    expect(point.y, 0);
  });
}
