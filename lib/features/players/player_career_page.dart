import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
import 'package:hooptrace/core/domain/analytics/player_career_aggregate.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/features/players/player_career_controller.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';

class PlayerCareerPage extends StatelessWidget {
  const PlayerCareerPage({
    required this.controller,
    required this.player,
    required this.opponents,
    super.key,
  });

  final PlayerCareerController controller;
  final Player player;
  final List<Player> opponents;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DoodleTitle(
          _l10n(context).playerAnalyticsTitle,
          icon: Icons.insights_outlined,
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: _CareerBody(
                      controller: controller,
                      player: player,
                      opponents: opponents,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CareerBody extends StatelessWidget {
  const _CareerBody({
    required this.controller,
    required this.player,
    required this.opponents,
  });

  final PlayerCareerController controller;
  final Player player;
  final List<Player> opponents;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoodleSurface(
          padding: const EdgeInsets.all(16),
          child: _PlayerHeader(player: player),
        ),
        const DoodleDivider(),
        _FilterCard(controller: controller, opponents: opponents),
        const SizedBox(height: 20),
        if (controller.isLoading)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.error != null)
          _ErrorCard(onRetry: controller.reload)
        else if (controller.aggregate == null)
          const SizedBox.shrink()
        else
          _AggregateContent(aggregate: controller.aggregate!, l10n: l10n),
      ],
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: HoopTraceColors.orange,
          child: Text(
            player.nickname.characters.first,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DoodleTitle(
            player.nickname,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.controller, required this.opponents});

  final PlayerCareerController controller;
  final List<Player> opponents;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    return DoodleSurface(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.playerAnalyticsWindow,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PlayerCareerWindow.values
                  .map(
                    (window) => ChoiceChip(
                      key: ValueKey('career-window-${window.name}'),
                      label: Text(_windowLabel(window, l10n)),
                      selected: controller.query.window == window,
                      onSelected: (_) => controller.setWindow(window),
                    ),
                  )
                  .toList(),
            ),
            if (opponents.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                l10n.playerAnalyticsOpponent,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('career-opponent-all'),
                    label: Text(l10n.playerAnalyticsOpponentNone),
                    selected: controller.query.opponentPlayerId == null,
                    onSelected: (_) => controller.setOpponent(null),
                  ),
                  ...opponents.map(
                    (opponent) => ChoiceChip(
                      key: ValueKey('career-opponent-${opponent.id}'),
                      label: Text(opponent.nickname),
                      selected:
                          controller.query.opponentPlayerId == opponent.id,
                      onSelected: (_) => controller.setOpponent(opponent.id),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AggregateContent extends StatelessWidget {
  const _AggregateContent({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (aggregate.matches == 0) {
      return DoodleSurface(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.playerAnalyticsNoMatches),
              const SizedBox(height: 8),
              Text(l10n.playerAnalyticsNoReliablePercentage),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeading(title: l10n.playerAnalyticsGrowth),
        const SizedBox(height: 8),
        _GrowthCard(aggregate: aggregate, l10n: l10n),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatCard(
              label: l10n.playerAnalyticsAveragePoints,
              value: aggregate.averagePoints.toStringAsFixed(1),
            ),
            _StatCard(
              label: l10n.playerAnalyticsAverageMargin,
              value: aggregate.averageMargin.toStringAsFixed(1),
            ),
            _StatCard(
              label: l10n.playerAnalyticsRecord,
              value:
                  '${aggregate.wins}/${aggregate.matches} ${l10n.playerAnalyticsWins}',
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeading(title: l10n.playerAnalyticsShootingTrend),
        const SizedBox(height: 8),
        _TrendCard(aggregate: aggregate, l10n: l10n),
        const SizedBox(height: 20),
        _SectionHeading(title: l10n.playerAnalyticsZoneHeatmap),
        const SizedBox(height: 8),
        _ZoneCard(aggregate: aggregate, l10n: l10n),
      ],
    );
  }
}

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final change = aggregate.recentChange;
    final pointsDelta = change.pointsDelta;
    final marginDelta = change.marginDelta;
    final hasChange = pointsDelta != null || marginDelta != null;
    return DoodleSurface(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: hasChange
            ? Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  if (pointsDelta != null)
                    _Delta(
                      label: l10n.playerAnalyticsAveragePoints,
                      value: pointsDelta,
                    ),
                  if (marginDelta != null)
                    _Delta(
                      label: l10n.playerAnalyticsAverageMargin,
                      value: marginDelta,
                    ),
                ],
              )
            : Text(l10n.playerAnalyticsNoTrend),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (aggregate.shootingTrend.isEmpty) {
      return DoodleSurface(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.playerAnalyticsNoTrend),
        ),
      );
    }
    return DoodleSurface(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: aggregate.shootingTrend
              .map((trend) => _TrendTile(trend: trend, l10n: l10n))
              .toList(),
        ),
      ),
    );
  }
}

class _TrendTile extends StatelessWidget {
  const _TrendTile({required this.trend, required this.l10n});

  final PlayerCareerShootingTrend trend;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final percentage = trend.recordedShootingPercentage;
    return Container(
      constraints: const BoxConstraints(minWidth: 146, maxWidth: 230),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${trend.playedAt.month}/${trend.playedAt.day}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 6),
          Text(
            percentage == null
                ? '${l10n.playerAnalyticsRecordedShots}: ${trend.recordedAttempts}'
                : '${(percentage * 100).round()}%',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.playerAnalyticsFieldGoals} ${trend.fieldGoalMade}/${trend.fieldGoalAttempts} · '
            '${l10n.playerAnalyticsFreeThrows} ${trend.freeThrowMade}/${trend.freeThrowAttempts}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (aggregate.zoneHeatmap.isEmpty) {
      return DoodleSurface(
        key: const Key('player-analytics-zone-empty'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.playerAnalyticsNoLocationData),
        ),
      );
    }
    return DoodleSurface(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: aggregate.zoneHeatmap.entries
              .map(
                (entry) => Chip(
                  label: Text(
                    '${_zoneLabel(entry.key, l10n)} · ${entry.value}',
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          positive ? Icons.trending_up : Icons.trending_down,
          color: positive ? Colors.green.shade700 : HoopTraceColors.red,
          size: 20,
        ),
        const SizedBox(width: 6),
        Text('$label ${positive ? '+' : ''}${value.toStringAsFixed(1)}'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DoodleTitle(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DoodleSurface(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(height: 8),
            Text(_l10n(context).playerAnalyticsLoadError),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(_l10n(context).playerAnalyticsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

String _windowLabel(PlayerCareerWindow window, AppLocalizations l10n) {
  return switch (window) {
    PlayerCareerWindow.sevenDays => l10n.playerAnalyticsSevenDays,
    PlayerCareerWindow.thirtyDays => l10n.playerAnalyticsThirtyDays,
    PlayerCareerWindow.ninetyDays => l10n.playerAnalyticsNinetyDays,
    PlayerCareerWindow.allTime => l10n.playerAnalyticsAllTime,
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

AppLocalizations _l10n(BuildContext context) {
  return AppLocalizations.of(context) ?? AppLocalizationsZh();
}
