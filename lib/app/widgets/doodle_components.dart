import 'package:flutter/material.dart';

import 'package:hooptrace/app/app_theme.dart';

/// A paper-like container with a stable, low-contrast edge treatment.
class DoodleSurface extends StatelessWidget {
  const DoodleSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.semanticLabel,
    this.color,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final String? semanticLabel;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final visual = Theme.of(context).extension<HoopTraceVisualTheme>();
    final radius = borderRadius ?? BorderRadius.circular(HoopTraceRadii.card);
    final surface =
        color ??
        visual?.paperDeep ??
        Theme.of(context).colorScheme.surfaceContainer;
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: radius,
        border: Border.all(
          color: visual?.divider ?? Theme.of(context).dividerColor,
          width: visual?.strokeWidth ?? 1,
        ),
      ),
      child: CustomPaint(
        painter: _DoodleCornerPainter(
          color: (visual?.ink ?? Theme.of(context).colorScheme.onSurface)
              .withValues(alpha: visual?.doodleOpacity ?? 0.2),
        ),
        child: child,
      ),
    );
    if (semanticLabel == null) return content;
    return Semantics(container: true, label: semanticLabel, child: content);
  }
}

/// A deterministic notebook rule that can be used between playbook sections.
class DoodleDivider extends StatelessWidget {
  const DoodleDivider({this.indent = 0, this.endIndent = 0, super.key});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final visual = Theme.of(context).extension<HoopTraceVisualTheme>();
    return SizedBox(
      height: 8,
      child: CustomPaint(
        painter: _DoodleDividerPainter(
          color: visual?.divider ?? Theme.of(context).dividerColor,
          indent: indent,
          endIndent: endIndent,
        ),
      ),
    );
  }
}

/// A compact title treatment that keeps heading hierarchy legible at 200% text.
class DoodleTitle extends StatelessWidget {
  const DoodleTitle(
    this.title, {
    this.icon,
    this.style,
    this.textAlign,
    super.key,
  });

  final String title;
  final IconData? icon;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final visual = Theme.of(context).extension<HoopTraceVisualTheme>();
    final textStyle =
        style ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: visual?.ink ?? Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        );
    final text = Text(title, style: textStyle, textAlign: textAlign);
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: visual?.accent),
        const SizedBox(width: 8),
        Flexible(child: text),
      ],
    );
  }
}

/// A button-sized press target with a restrained deterministic scale response.
class DoodlePress extends StatefulWidget {
  const DoodlePress({
    required this.child,
    required this.onPressed,
    this.label,
    this.tooltip,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final String? tooltip;
  final bool enabled;

  @override
  State<DoodlePress> createState() => _DoodlePressState();
}

class _DoodlePressState extends State<DoodlePress> {
  bool _pressed = false;

  bool get _isEnabled => widget.enabled && widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_isEnabled || _pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final visual = Theme.of(context).extension<HoopTraceVisualTheme>();
    final motion = Theme.of(context).extension<HoopTraceMotionTheme>();
    final isEnabled = _isEnabled;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isEnabled ? widget.onPressed : null,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(HoopTraceRadii.control),
          splashColor: (visual?.accent ?? HoopTraceColors.orange).withValues(
            alpha: 0.12,
          ),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: motion?.press ?? const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
    final semantics = Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.label,
      child: content,
    );
    if (widget.tooltip == null) return semantics;
    return Tooltip(message: widget.tooltip!, child: semantics);
  }
}

class _DoodleCornerPainter extends CustomPainter {
  const _DoodleCornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width - 22, 4)
      ..quadraticBezierTo(size.width - 16, 1, size.width - 10, 4)
      ..quadraticBezierTo(size.width - 4, 7, size.width - 6, 13);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DoodleCornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _DoodleDividerPainter extends CustomPainter {
  const _DoodleDividerPainter({
    required this.color,
    required this.indent,
    required this.endIndent,
  });

  final Color color;
  final double indent;
  final double endIndent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final left = indent;
    final right = size.width - endIndent;
    if (right <= left) return;
    final middle = (left + right) / 2;
    final path = Path()
      ..moveTo(left, size.height / 2)
      ..quadraticBezierTo(
        middle,
        size.height / 2 - 1.5,
        right,
        size.height / 2,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DoodleDividerPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.indent != indent ||
      oldDelegate.endIndent != endIndent;
}
