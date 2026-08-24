import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final attempts = analytics.attempts;
    final percentage = analytics.reliableShootingPercentage == null
        ? null
        : (analytics.reliableShootingPercentage! * 100).round();
    final largestLead = analytics.largestLeadSide == null
        ? l10n.replayNoData
        : '${_sideName(analytics.largestLeadSide!)} '
              '+${analytics.largestLeadPoints}';

    return Material(
      type: MaterialType.transparency,
      child: Column(
        key: const Key('replay-analytics-summary'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnalyticsHeading(
            title: l10n.replayAnalyticsTitle,
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AnalyticsMetric(
                label: l10n.replayAnalyticsLeadChanges,
                value: l10n.replayExportLeadChangesValue(analytics.leadChanges),
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsLargestLead,
                value: largestLead,
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsShootingPercentage,
                value: _shootingValue(
                  analytics,
                  attempts: attempts,
                  percentage: percentage,
                  l10n: l10n,
                ),
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsKeyMoments,
                value: l10n.replayExportKeyMomentsValue(
                  analytics.keyPossessions.length,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AnalyticsSubheading(title: l10n.replayAnalyticsShotRecord),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AnalyticsMetric(
                label: l10n.replayAnalyticsFieldGoals,
                value:
                    '${analytics.fieldGoalMadeCount}/${analytics.fieldGoalAttemptCount}',
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsFreeThrows,
                value:
                    '${analytics.freeThrowMadeCount}/${analytics.freeThrowAttemptCount}',
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsFouls,
                value: '${analytics.redFoulCount} · ${analytics.blueFoulCount}',
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsPossessions,
                value:
                    analytics.possessionCount?.toString() ?? l10n.replayNoData,
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsTrackingCoverage,
                value: _coverageLabel(analytics.trackingCoverage, l10n),
              ),
              _AnalyticsMetric(
                label: l10n.replayAnalyticsLocationCoverage,
                value: analytics.shotAttemptCount == null
                    ? l10n.replayNoData
                    : '${analytics.confirmedLocationCount}/${analytics.fieldGoalAttemptCount}',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _AnalyticsSubheading(title: l10n.replayAnalyticsScoringRun),
          const SizedBox(height: 8),
          if (analytics.scoringRuns.isEmpty)
            Text(l10n.replayAnalyticsNoScoringEvents)
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analytics.scoringRuns
                  .map(
                    (run) => Chip(
                      avatar: CircleAvatar(
                        backgroundColor: run.side == TeamSide.red
                            ? HoopTraceColors.red
                            : HoopTraceColors.blue,
                      ),
                      label: Text('${_sideName(run.side)} +${run.points}'),
                    ),
                  )
                  .toList(),
            ),
          if (analytics.zoneDistribution.isNotEmpty) ...[
            const SizedBox(height: 18),
            _AnalyticsSubheading(title: l10n.replayAnalyticsShotZones),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analytics.zoneDistribution.entries
                  .map(
                    (entry) => Chip(
                      label: Text(
                        '${_zoneLabel(entry.key, l10n)} · ${entry.value}',
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          _AnalyticsSubheading(title: l10n.replayAnalyticsScoringFlow),
          const SizedBox(height: 8),
          if (analytics.scoringFlow.isEmpty)
            Text(l10n.replayAnalyticsNoScoringEvents)
          else
            SizedBox(
              height: 72,
              child: ListView.separated(
                key: const Key('replay-scoring-flow'),
                scrollDirection: Axis.horizontal,
                itemCount: analytics.scoringFlow.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right, size: 18),
                ),
                itemBuilder: (context, index) {
                  final entry = analytics.scoringFlow[index];
                  return _ScoringFlowItem(
                    entry: entry,
                    sideName: _sideName(entry.side),
                    l10n: l10n,
                  );
                },
              ),
            ),
          const SizedBox(height: 18),
          _AnalyticsSubheading(title: l10n.replayAnalyticsKeyPossessions),
          const SizedBox(height: 4),
          if (analytics.keyPossessions.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.replayAnalyticsNoKeyPossessions),
            )
          else
            ...analytics.keyPossessions.map(
              (possession) => _KeyPossessionRow(
                possession: possession,
                sideName: _sideName(possession.side),
                l10n: l10n,
              ),
            ),
        ],
      ),
    );
  }

  String _sideName(TeamSide side) {
    return side == TeamSide.red ? redName : blueName;
  }

  String _shootingValue(
    MatchAnalytics analytics, {
    required int attempts,
    required int? percentage,
    required AppLocalizations l10n,
  }) {
    if (attempts == 0) return l10n.replayAnalyticsNoAttempts;
    if (analytics.hasReliableShootingPercentage && percentage != null) {
      return '$percentage% · ${analytics.madeShotCount}/$attempts';
    }
    return '${l10n.replayAnalyticsIncompleteShooting} · '
        '${l10n.replayAnalyticsRecordedAttempts} · $attempts';
  }

  String _coverageLabel(TrackingCoverage coverage, AppLocalizations l10n) {
    return switch (coverage) {
      TrackingCoverage.none => l10n.replayAnalyticsTrackingNone,
      TrackingCoverage.scoresOnly => l10n.replayAnalyticsTrackingScoresOnly,
      TrackingCoverage.shotAttempts => l10n.replayAnalyticsTrackingShotAttempts,
      TrackingCoverage.locations => l10n.replayAnalyticsTrackingLocations,
      TrackingCoverage.full => l10n.replayAnalyticsTrackingFull,
    };
  }

  String _zoneLabel(ShotZone zone, AppLocalizations l10n) {
    return switch (zone) {
      ShotZone.restrictedArea => l10n.replayAnalyticsZoneRestrictedArea,
      ShotZone.paint => l10n.replayAnalyticsZonePaint,
      ShotZone.midRange => l10n.replayAnalyticsZoneMidRange,
      ShotZone.cornerThree => l10n.replayAnalyticsZoneCornerThree,
      ShotZone.wingThree => l10n.replayAnalyticsZoneWingThree,
      ShotZone.topThree => l10n.replayAnalyticsZoneTopThree,
      ShotZone.unknown => l10n.replayAnalyticsZoneUnknown,
    };
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ScoringFlowItem extends StatelessWidget {
  const _ScoringFlowItem({
    required this.entry,
    required this.sideName,
    required this.l10n,
  });

  final ScoringFlowEntry entry;
  final String sideName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = entry.side == TeamSide.red
        ? HoopTraceColors.red
        : HoopTraceColors.blue;
    return Semantics(
      label: l10n.replayAnalyticsScoreSemantics(
        sideName,
        entry.points,
        entry.redScore,
        entry.blueScore,
      ),
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
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
    required this.l10n,
  });

  final KeyPossession possession;
  final String sideName;
  final AppLocalizations l10n;

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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.16),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 28, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$sideName · ${_label(possession.type, l10n)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text('${possession.redScore} : ${possession.blueScore}'),
        ],
      ),
    );
  }

  String _label(KeyPossessionType type, AppLocalizations l10n) {
    return switch (type) {
      KeyPossessionType.tie => l10n.replayAnalyticsTie,
      KeyPossessionType.overtake => l10n.replayAnalyticsOvertake,
      KeyPossessionType.matchPoint => l10n.replayAnalyticsMatchPoint,
      KeyPossessionType.scoringRun => l10n.replayAnalyticsScoringRun,
    };
  }
}
