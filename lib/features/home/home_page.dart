import 'package:flutter/material.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';

const homeResumeCardKey = Key('home-resume-card');
const homeResumeKey = Key('home-resume');
const homeStartScoringKey = Key('home-start-scoring');
const homeAbandonKey = Key('active-abandon');

class HomePage extends StatelessWidget {
  const HomePage({
    required this.activeMatch,
    required this.onStartScoring,
    required this.onContinue,
    required this.onAbandon,
    required this.onOpenHistory,
    required this.onOpenPlayers,
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
      floatingActionButton: FloatingActionButton.small(
        onPressed: onOpenProject,
        tooltip: l10n.homeProjectTooltip,
        child: const Icon(Icons.info_outline),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
              children: [
                if (activeMatch != null) ...[
                  _ResumeCard(
                    detail: activeMatch!,
                    onContinue: onContinue,
                    onAbandon: onAbandon,
                  ),
                  const SizedBox(height: 20),
                ],
                FilledButton(
                  key: homeStartScoringKey,
                  onPressed: onStartScoring,
                  child: Text(l10n.startScoring),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onOpenHistory,
                  child: Text(l10n.replayHistory),
                ),
              ],
            ),
          ),
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

    return Card(
      key: homeResumeCardKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeActiveMatch,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
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
