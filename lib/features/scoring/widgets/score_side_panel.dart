import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

const foulText = '犯规';

class ScoreSidePanel extends StatelessWidget {
  const ScoreSidePanel({
    required this.side,
    required this.name,
    required this.score,
    required this.fouls,
    required this.onScore,
    required this.onFoul,
    this.scoreButtons = const [1, 2, 3],
    this.onMiss,
    this.scoreEnabled = true,
    this.missEnabled = false,
    super.key,
  });

  final TeamSide side;
  final String name;
  final int score;
  final int fouls;
  final ValueChanged<int> onScore;
  final VoidCallback onFoul;
  final List<int> scoreButtons;
  final VoidCallback? onMiss;
  final bool scoreEnabled;
  final bool missEnabled;

  @override
  Widget build(BuildContext context) {
    final color = side == TeamSide.red
        ? HoopTraceColors.red
        : HoopTraceColors.blue;

    return ColoredBox(
      color: color.withValues(alpha: 0.08),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 560;
          const buttonHeight = 48.0;
          final scoreHeight = compact ? 64.0 : 88.0;
          final gap = compact ? 4.0 : 8.0;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: compact ? 6 : 8,
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (compact ? 12 : 16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: gap),
                        SizedBox(
                          height: scoreHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '$score',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: HoopTraceColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ),
                        Text(
                          '$foulText $fouls',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 6 : 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final points in scoreButtons) ...[
                          SizedBox(
                            height: buttonHeight,
                            child: FilledButton(
                              key: Key('${side.name}-score-$points'),
                              style: FilledButton.styleFrom(
                                backgroundColor: color,
                                minimumSize: const Size(48, buttonHeight),
                              ),
                              onPressed: scoreEnabled
                                  ? () => onScore(points)
                                  : null,
                              child: Text('+$points'),
                            ),
                          ),
                          SizedBox(height: gap),
                        ],
                        if (missEnabled && onMiss != null) ...[
                          SizedBox(
                            height: buttonHeight,
                            child: OutlinedButton.icon(
                              key: Key('${side.name}-miss'),
                              onPressed: onMiss,
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('未中'),
                            ),
                          ),
                          SizedBox(height: gap),
                        ],
                        SizedBox(
                          height: buttonHeight,
                          child: OutlinedButton.icon(
                            key: Key('${side.name}-foul'),
                            onPressed: onFoul,
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: const Text(foulText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
