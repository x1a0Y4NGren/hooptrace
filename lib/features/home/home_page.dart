import 'package:flutter/material.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/app/widgets/doodle_components.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';

const homeResumeCardKey = Key('home-resume-card');
const homeResumeKey = Key('home-resume');
const homeStartScoringKey = Key('home-start-scoring');
const homeAbandonKey = Key('active-abandon');
const homeHistoryShortcutKey = Key('home-history-shortcut');
const homePlayersShortcutKey = Key('home-players-shortcut');
const homeRulesShortcutKey = Key('home-rules-shortcut');
const homeSettingsShortcutKey = Key('home-settings-shortcut');
const homeProjectShortcutKey = Key('home-project-shortcut');

class HomePage extends StatelessWidget {
  const HomePage({
    required this.activeMatch,
    required this.onStartScoring,
    required this.onContinue,
    required this.onAbandon,
    required this.onOpenHistory,
    required this.onOpenPlayers,
    required this.onOpenRules,
    required this.onOpenSettings,
    required this.onOpenProject,
    super.key,
  });

  final MatchDetail? activeMatch;
  final VoidCallback onStartScoring;
  final VoidCallback onContinue;
  final Future<void> Function() onAbandon;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenPlayers;
  final VoidCallback onOpenRules;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            onPressed: onOpenPlayers,
            tooltip: l10n.homePlayersTooltip,
            icon: const Icon(Icons.people_outline),
          ),
          IconButton(
            onPressed: onOpenSettings,
            tooltip: l10n.homeSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DoodleSurface(
                      semanticLabel: l10n.startScoring,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (activeMatch != null) ...[
                            _ResumeCard(
                              detail: activeMatch!,
                              onContinue: onContinue,
                              onAbandon: onAbandon,
                            ),
                            const SizedBox(height: 12),
                          ],
                          FilledButton.icon(
                            key: homeStartScoringKey,
                            onPressed: onStartScoring,
                            icon: const Icon(Icons.add_circle_outline),
                            label: Text(l10n.startScoring),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const DoodleDivider(),
                    const SizedBox(height: 8),
                    _ShortcutGrid(
                      wide: constraints.maxWidth >= 520,
                      onOpenHistory: onOpenHistory,
                      onOpenPlayers: onOpenPlayers,
                      onOpenRules: onOpenRules,
                      onOpenSettings: onOpenSettings,
                      l10n: l10n,
                    ),
                    const SizedBox(height: 10),
                    _ShortcutCard(
                      key: homeProjectShortcutKey,
                      icon: Icons.info_outline,
                      title: l10n.projectDetails,
                      onPressed: onOpenProject,
                      tooltip: l10n.homeProjectTooltip,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({
    required this.wide,
    required this.onOpenHistory,
    required this.onOpenPlayers,
    required this.onOpenRules,
    required this.onOpenSettings,
    required this.l10n,
  });

  final bool wide;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenPlayers;
  final VoidCallback onOpenRules;
  final VoidCallback onOpenSettings;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ShortcutCard(
        key: homeHistoryShortcutKey,
        icon: Icons.history,
        title: l10n.replayHistory,
        onPressed: onOpenHistory,
      ),
      _ShortcutCard(
        key: homePlayersShortcutKey,
        icon: Icons.people_outline,
        title: l10n.playersTitle,
        onPressed: onOpenPlayers,
      ),
      _ShortcutCard(
        key: homeRulesShortcutKey,
        icon: Icons.rule_folder_outlined,
        title: l10n.rulesTitle,
        onPressed: onOpenRules,
      ),
      _ShortcutCard(
        key: homeSettingsShortcutKey,
        icon: Icons.tune,
        title: l10n.settings,
        onPressed: onOpenSettings,
      ),
    ];
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < cards.length; index++) ...[
            cards[index],
            if (index != cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.tooltip,
    this.compact = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DoodlePress(
      onPressed: onPressed,
      label: title,
      tooltip: tooltip,
      child: DoodleSurface(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 4 : 10,
        ),
        child: Row(
          children: [
            Icon(icon, size: compact ? 20 : 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Icon(Icons.chevron_right, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.detail,
    required this.onContinue,
    required this.onAbandon,
  });

  final MatchDetail detail;
  final VoidCallback onContinue;
  final Future<void> Function() onAbandon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final clock = detail.clock;
    final clockStatus = clock == null
        ? l10n.homeClockNotConfigured
        : clock.isRegulationExpired
        ? l10n.homeClockRegulationExpired
        : clock.isRunning
        ? l10n.homeClockRunning
        : l10n.homeClockPaused;
    final persisted = detail.lastPersistedAt?.toLocal();
    final persistedLabel = persisted == null
        ? l10n.homeLastPersistedUnknown
        : l10n.homeLastPersisted(
            '${persisted.year}-${persisted.month.toString().padLeft(2, '0')}-'
            '${persisted.day.toString().padLeft(2, '0')} '
            '${persisted.hour.toString().padLeft(2, '0')}:${persisted.minute.toString().padLeft(2, '0')}',
          );

    return Semantics(
      container: true,
      label: l10n.homeActiveMatch,
      child: Column(
        key: homeResumeCardKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DoodleTitle(l10n.homeActiveMatch, icon: Icons.play_circle_outline),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(detail.match.redName)),
              Text(' ${l10n.homeVersus} '),
              Expanded(
                child: Text(detail.match.blueName, textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${detail.redScore} : ${detail.blueScore}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text('$clockStatus · $persistedLabel'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: homeResumeKey,
                  onPressed: onContinue,
                  child: Text(l10n.homeResumeMatch),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: homeAbandonKey,
                  onPressed: () => _confirmAbandon(context),
                  child: Text(l10n.homeAbandonMatch),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAbandon(BuildContext context) async {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.homeAbandonTitle),
        content: Text(l10n.homeAbandonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.homeConfirmAbandon),
          ),
        ],
      ),
    );
    if (confirmed == true) await onAbandon();
  }
}
