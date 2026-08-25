import 'package:flutter/material.dart';

import 'package:hooptrace/app/design_system/editorial_primitives.dart';

class EditorialIndexRow extends StatelessWidget {
  const EditorialIndexRow({
    required this.index,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final String index;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: InkWell(
        onTap: onTap,
        focusColor: editorial.focus.withValues(alpha: 0.18),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: editorial.rule)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  index,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: editorial.arenaAccent,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: editorial.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: editorial.mutedInk,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ] else if (onTap != null)
                Icon(Icons.arrow_forward, color: editorial.ink, size: 20),
            ],
          ),
        ),
      ),
    );
    if (semanticLabel == null) return row;
    return Semantics(label: semanticLabel, button: onTap != null, child: row);
  }
}
