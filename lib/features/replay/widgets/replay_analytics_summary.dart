import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class ReplayAnalyticsSummary extends StatelessWidget {
  const ReplayAnalyticsSummary({
    required this.analytics,
    required this.redName,
    required this.blueName,
    super.key,
  });

  final MatchAnalytics analytics;
  final String redName;
  final String blueName;

  @override
  Widget build(BuildContext context) {
    final attempts = analytics.madeShotCount + analytics.missedShotCount;
    final percentage = (analytics.shootingPercentage * 100).round();
    final largestLead = analytics.largestLeadSide == null
        ? '无'
        : '${_sideName(analytics.largestLeadSide!)} '
            '+${analytics.largestLeadPoints}';

    return Column(
      key: const Key('replay-analytics-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _AnalyticsHeading(
          title: '比赛分析',
          icon: Icons.insights_outlined,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AnalyticsMetric(
              label: '领先变化',
              value: '${analytics.leadChanges} 次',
            ),
            _AnalyticsMetric(label: '最大领先', value: largestLead),
            _AnalyticsMetric(
              label: '投篮命中率',
              value: attempts == 0
                  ? '暂无出手'
                  : '$percentage% · ${analytics.madeShotCount}/$attempts',
            ),
            _AnalyticsMetric(
              label: '关键节点',
              value: '${analytics.keyPossessions.length} 次',
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _AnalyticsSubheading(title: '比分流'),
        const SizedBox(height: 8),
        if (analytics.scoringFlow.isEmpty)
          const Text('本场暂无得分事件')
        else
          SizedBox(
            height: 72,
            child: ListView.separated(
              key: const Key('replay-scoring-flow'),
              scrollDirection: Axis.horizontal,
              itemCount: analytics.scoringFlow.length,
              separatorBuilder: (_, __) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right, size: 18),
              ),
              itemBuilder: (context, index) {
                final entry = analytics.scoringFlow[index];
                return _ScoringFlowItem(
                  entry: entry,
                  sideName: _sideName(entry.side),
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        const _AnalyticsSubheading(title: '关键回合'),
        const SizedBox(height: 4),
        if (analytics.keyPossessions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('本场暂无关键回合'),
          )
        else
          ...analytics.keyPossessions.map(
            (possession) => _KeyPossessionRow(
              possession: possession,
              sideName: _sideName(possession.side),
            ),
          ),
      ],
    );
  }

  String _sideName(TeamSide side) {
    return side == TeamSide.red ? redName : blueName;
  }
}

class _AnalyticsHeading extends StatelessWidget {
  const _AnalyticsHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: HoopTraceColors.orange),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _AnalyticsSubheading extends StatelessWidget {
  const _AnalyticsSubheading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _AnalyticsMetric extends StatelessWidget {
  const _AnalyticsMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 128, minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: HoopTraceColors.cream,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _ScoringFlowItem extends StatelessWidget {
  const _ScoringFlowItem({required this.entry, required this.sideName});

  final ScoringFlowEntry entry;
  final String sideName;

  @override
  Widget build(BuildContext context) {
    final color =
        entry.side == TeamSide.red ? HoopTraceColors.red : HoopTraceColors.blue;
    return Semantics(
      label: '$sideName 得 ${entry.points} 分，'
          '${entry.redScore} 比 ${entry.blueScore}',
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
          color: color.withValues(alpha: 0.07),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.redScore} : ${entry.blueScore}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              '$sideName +${entry.points}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyPossessionRow extends StatelessWidget {
  const _KeyPossessionRow({
    required this.possession,
    required this.sideName,
  });

  final KeyPossession possession;
  final String sideName;

  @override
  Widget build(BuildContext context) {
    final color = possession.side == TeamSide.red
        ? HoopTraceColors.red
        : HoopTraceColors.blue;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: HoopTraceColors.ink.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 28, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$sideName · ${_label(possession.type)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text('${possession.redScore} : ${possession.blueScore}'),
        ],
      ),
    );
  }

  String _label(KeyPossessionType type) {
    return switch (type) {
      KeyPossessionType.tie => '扳平比分',
      KeyPossessionType.overtake => '完成反超',
      KeyPossessionType.matchPoint => '到达赛点',
      KeyPossessionType.scoringRun => '连续得分',
    };
  }
}
