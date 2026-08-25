import 'package:flutter/material.dart';

import 'package:hooptrace/app/app_theme.dart';

HoopTraceEditorialTheme editorialThemeOf(BuildContext context) =>
    Theme.of(context).extension<HoopTraceEditorialTheme>() ??
    (Theme.of(context).brightness == Brightness.dark
        ? const HoopTraceEditorialTheme.dark()
        : const HoopTraceEditorialTheme.light());

Duration editorialMotionDuration(
  BuildContext context, {
  required Duration standard,
  Duration reduced = Duration.zero,
}) {
  final media = MediaQuery.maybeOf(context);
  if (media?.disableAnimations == true) return Duration.zero;
  if (media?.accessibleNavigation == true) return reduced;
  return standard;
}

class EditorialSurface extends StatelessWidget {
  const EditorialSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.color,
    this.borderRadius,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? editorial.surface,
        border: Border.all(color: editorial.rule),
        borderRadius:
            borderRadius ?? BorderRadius.circular(HoopTraceRadii.card),
      ),
      child: child,
    );
    if (semanticLabel == null) return content;
    return Semantics(container: true, label: semanticLabel, child: content);
  }
}

class EditorialTapTarget extends StatefulWidget {
  const EditorialTapTarget({
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
  State<EditorialTapTarget> createState() => _EditorialTapTargetState();
}

class _EditorialTapTargetState extends State<EditorialTapTarget> {
  bool _pressed = false;

  bool get _isEnabled => widget.enabled && widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_isEnabled || _pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    final motion = Theme.of(context).extension<HoopTraceMotionTheme>();
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isEnabled ? widget.onPressed : null,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(HoopTraceRadii.control),
          focusColor: editorial.focus.withValues(alpha: 0.18),
          splashColor: editorial.arenaAccent.withValues(alpha: 0.14),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: editorialMotionDuration(
              context,
              standard: motion?.press ?? const Duration(milliseconds: 90),
            ),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
    final semantics = Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      child: content,
    );
    if (widget.tooltip == null) return semantics;
    return Tooltip(message: widget.tooltip!, child: semantics);
  }
}
