import 'package:flutter/material.dart';
import 'package:hooptrace/app/design_system/design_system.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/analytics/match_analytics.dart';
import 'package:hooptrace/core/domain/analytics/player_career_aggregate.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/features/players/player_career_controller.dart';

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
    final canPop = Navigator.of(context).canPop();
    return EditorialScaffold(
      maxContentWidth: 920,
      masthead: EditorialMasthead(
        title: _l10n(context).playerAnalyticsTitle,
        leading: canPop
            ? EditorialTapTarget(
                onPressed: () => Navigator.maybePop(context),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) => SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: HoopTraceSpacing.section),
          child: _CareerBody(
            controller: controller,
            player: player,
            opponents: opponents,
          ),
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
        _PlayerIdentity(player: player),
        const SizedBox(height: 24),
        _CareerFilters(controller: controller, opponents: opponents),
        const SizedBox(height: 24),
        if (controller.isLoading)
          const Padding(
            padding: EdgeInsets.all(36),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (controller.error != null)
          EditorialErrorState(
            title: l10n.playerAnalyticsLoadError,
            message: l10n.playerAnalyticsLoadError,
            actionLabel: l10n.playerAnalyticsRetry,
            onAction: controller.reload,
          )
        else if (controller.aggregate == null)
          const SizedBox.shrink()
        else
          _AggregateContent(aggregate: controller.aggregate!, l10n: l10n),
      ],
    );
  }
}

class _PlayerIdentity extends StatelessWidget {
  const _PlayerIdentity({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    final avatarForeground = accessibleForegroundFor(editorial.arenaAccent);
    return Semantics(
      container: true,
      label: player.nickname,
      child: Row(
        children: [
          CircleAvatar(
            key: ValueKey('career-avatar-${player.id}'),
            radius: 32,
            backgroundColor: editorial.arenaAccent,
            foregroundColor: avatarForeground,
            child: ScoreNumeral(
              value: player.nickname.characters.first,
              color: avatarForeground,
              fontSize: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.nickname,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: editorial.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (player.note case final note? when note.trim().isNotEmpty)
                  Text(
                    note,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: editorial.mutedInk),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerFilters extends StatelessWidget {
  const _CareerFilters({required this.controller, required this.opponents});

  final PlayerCareerController controller;
  final List<Player> opponents;

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorialSectionRule(label: l10n.playerAnalyticsWindow),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final window in PlayerCareerWindow.values)
              _FilterChoice(
                key: ValueKey('career-window-${window.name}'),
                label: _windowLabel(window, l10n),
                selected: controller.query.window == window,
                onPressed: () => controller.setWindow(window),
              ),
          ],
        ),
        if (opponents.isNotEmpty) ...[
          const SizedBox(height: 20),
          EditorialSectionRule(label: l10n.playerAnalyticsOpponent),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChoice(
                key: const Key('career-opponent-all'),
                label: l10n.playerAnalyticsOpponentNone,
                selected: controller.query.opponentPlayerId == null,
                onPressed: () => controller.setOpponent(null),
              ),
              for (final opponent in opponents)
                _FilterChoice(
                  key: ValueKey('career-opponent-${opponent.id}'),
                  label: opponent.nickname,
                  selected: controller.query.opponentPlayerId == opponent.id,
                  onPressed: () => controller.setOpponent(opponent.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FilterChoice extends StatelessWidget {
  const _FilterChoice({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 18,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected
              ? accessibleForegroundFor(editorial.inverseSurface)
              : editorial.ink,
          backgroundColor: selected ? editorial.inverseSurface : null,
          side: BorderSide(
            color: selected ? editorial.inverseSurface : editorial.rule,
            width: selected ? 2 : 1,
          ),
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
      return EditorialEmptyState(
        title: l10n.playerAnalyticsNoMatches,
        message: l10n.playerAnalyticsNoReliablePercentage,
        icon: Icons.insights_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorialSectionRule(label: l10n.playerAnalyticsGrowth),
        const SizedBox(height: 12),
        _GrowthSummary(aggregate: aggregate, l10n: l10n),
        const SizedBox(height: 20),
        _CoreStatistics(aggregate: aggregate, l10n: l10n),
        const SizedBox(height: 24),
        EditorialSectionRule(label: l10n.playerAnalyticsShootingTrend),
        const SizedBox(height: 12),
        _TrendSection(aggregate: aggregate, l10n: l10n),
        const SizedBox(height: 24),
        EditorialSectionRule(label: l10n.playerAnalyticsZoneHeatmap),
        const SizedBox(height: 12),
        _ZoneSection(aggregate: aggregate, l10n: l10n),
      ],
    );
  }
}

class _GrowthSummary extends StatelessWidget {
  const _GrowthSummary({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final pointsDelta = aggregate.recentChange.pointsDelta;
    final marginDelta = aggregate.recentChange.marginDelta;
    if (pointsDelta == null && marginDelta == null) {
      return Text(l10n.playerAnalyticsNoTrend);
    }
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        if (pointsDelta != null)
          _Delta(label: l10n.playerAnalyticsAveragePoints, value: pointsDelta),
        if (marginDelta != null)
          _Delta(label: l10n.playerAnalyticsAverageMargin, value: marginDelta),
      ],
    );
  }
}

class _Delta extends StatelessWidget {
  const _Delta({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    final positive = value >= 0;
    final color = positive ? editorial.success : editorial.danger;
    return Semantics(
      label: '$label ${positive ? '+' : ''}${value.toStringAsFixed(1)}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(label),
          const SizedBox(width: 8),
          Text(
            '${positive ? '+' : ''}${value.toStringAsFixed(1)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CoreStatistics extends StatelessWidget {
  const _CoreStatistics({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CareerStat(
          label: l10n.playerAnalyticsAveragePoints,
          value: aggregate.averagePoints.toStringAsFixed(1),
        ),
        _CareerStat(
          label: l10n.playerAnalyticsAverageMargin,
          value: aggregate.averageMargin.toStringAsFixed(1),
        ),
        _CareerStat(
          label: l10n.playerAnalyticsRecord,
          value: '${aggregate.wins}/${aggregate.matches}',
          note: l10n.playerAnalyticsWins,
        ),
      ],
    );
  }
}

class _CareerStat extends StatelessWidget {
  const _CareerStat({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: editorial.rule)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: editorial.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (note != null) Text(note!),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ScoreNumeral(value: value, fontSize: 46),
        ],
      ),
    );
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (aggregate.shootingTrend.isEmpty) {
      return Text(l10n.playerAnalyticsNoTrend);
    }
    return Column(
      children: [
        for (final (index, trend) in aggregate.shootingTrend.indexed)
          _TrendRow(index: index + 1, trend: trend, l10n: l10n),
      ],
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.index,
    required this.trend,
    required this.l10n,
  });

  final int index;
  final PlayerCareerShootingTrend trend;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    final percentage = trend.recordedShootingPercentage;
    final value = percentage == null
        ? '${l10n.playerAnalyticsRecordedShots}: ${trend.recordedAttempts}'
        : '${(percentage * 100).round()}%';
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: editorial.rule)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Text(
            '${l10n.playerAnalyticsFieldGoals} ${trend.fieldGoalMade}/${trend.fieldGoalAttempts} · '
            '${l10n.playerAnalyticsFreeThrows} ${trend.freeThrowMade}/${trend.freeThrowAttempts}',
          );
          final identity = Text(
            '${index.toString().padLeft(2, '0')}  '
            '${trend.playedAt.month}/${trend.playedAt.day}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: editorial.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          );
          final result = Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          );
          final compact =
              constraints.maxWidth < 520 ||
              MediaQuery.textScalerOf(context).scale(1) >= 1.5;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 4),
                result,
                const SizedBox(height: 4),
                details,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 96, child: identity),
              Expanded(child: details),
              const SizedBox(width: 16),
              result,
            ],
          );
        },
      ),
    );
  }
}

class _ZoneSection extends StatelessWidget {
  const _ZoneSection({required this.aggregate, required this.l10n});

  final PlayerCareerAggregate aggregate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (aggregate.zoneHeatmap.isEmpty) {
      final editorial = editorialThemeOf(context);
      return Container(
        key: const Key('player-analytics-zone-empty'),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: editorial.mutedInk, width: 4)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, color: editorial.mutedInk),
            const SizedBox(width: 10),
            Flexible(child: Text(l10n.playerAnalyticsNoLocationData)),
          ],
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in aggregate.zoneHeatmap.entries)
          _ZoneMetric(label: _zoneLabel(entry.key, l10n), value: entry.value),
      ],
    );
  }
}

class _ZoneMetric extends StatelessWidget {
  const _ZoneMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final editorial = editorialThemeOf(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 128),
      decoration: BoxDecoration(border: Border.all(color: editorial.rule)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: 12),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
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
