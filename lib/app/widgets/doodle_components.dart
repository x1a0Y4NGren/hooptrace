import 'package:flutter/material.dart';

import 'package:hooptrace/app/design_system/design_system.dart';

/// Temporary compatibility wrapper. Prefer [EditorialSurface].
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
  Widget build(BuildContext context) => EditorialSurface(
    padding: padding,
    margin: margin,
    semanticLabel: semanticLabel,
    color: color,
    borderRadius: borderRadius,
    child: child,
  );
}

/// Temporary compatibility wrapper. Prefer [EditorialSectionRule].
class DoodleDivider extends StatelessWidget {
  const DoodleDivider({this.indent = 0, this.endIndent = 0, super.key});

  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
    child: const EditorialSectionRule(),
  );
}

/// Temporary compatibility wrapper. Prefer [EditorialMasthead].
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
  Widget build(BuildContext context) => EditorialMasthead(
    title: title,
    leading: icon == null ? null : Icon(icon, size: 20),
    compact: true,
    showRule: false,
    textAlign: textAlign,
    titleStyle: style,
  );
}

/// Temporary compatibility wrapper. Prefer [EditorialTapTarget].
class DoodlePress extends StatelessWidget {
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
  Widget build(BuildContext context) => EditorialTapTarget(
    onPressed: onPressed,
    label: label,
    tooltip: tooltip,
    enabled: enabled,
    child: child,
  );
}
