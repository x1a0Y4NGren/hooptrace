import 'package:flutter/material.dart';

enum HoopTraceOrientationMode { portraitFriendly, landscapeRequired }

class OrientationShell extends StatelessWidget {
  const OrientationShell({
    required this.mode,
    required this.child,
    super.key,
  });

  final HoopTraceOrientationMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
