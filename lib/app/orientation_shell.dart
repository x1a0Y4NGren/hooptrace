import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum HoopTraceOrientationMode { portraitFriendly, landscapeRequired }

class OrientationShell extends StatefulWidget {
  const OrientationShell({required this.mode, required this.child, super.key});

  final HoopTraceOrientationMode mode;
  final Widget child;

  @override
  State<OrientationShell> createState() => _OrientationShellState();
}

class _OrientationShellState extends State<OrientationShell> {
  @override
  void initState() {
    super.initState();
    _applyOrientation();
  }

  @override
  void didUpdateWidget(covariant OrientationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _applyOrientation();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _applyOrientation() {
    if (widget.mode == HoopTraceOrientationMode.landscapeRequired) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return;
    }

    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
