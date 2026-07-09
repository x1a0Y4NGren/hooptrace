import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class ScoreSidePanel extends StatelessWidget {
  const ScoreSidePanel({
    required this.side,
    required this.name,
    required this.score,
    required this.fouls,
    required this.onScore,
    required this.onFoul,
    super.key,
  });

  final TeamSide side;
  final String name;
  final int score;
  final int fouls;
  final ValueChanged<int> onScore;
  final VoidCallback onFoul;

  @override
  Widget build(BuildContext context) {
    final color =
        side == TeamSide.red ? HoopTraceColors.red : HoopTraceColors.blue;

    return ColoredBox(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$score',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: HoopTraceColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            Text(
              '犯规 $fouls',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const Spacer(),
            for (final points in const [1, 2, 3]) ...[
              SizedBox(
                height: 44,
                child: FilledButton(
                  key: Key('${side.name}-score-$points'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: () => onScore(points),
                  child: Text('+$points'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: onFoul,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('犯规'),
            ),
          ],
        ),
      ),
    );
  }
}
