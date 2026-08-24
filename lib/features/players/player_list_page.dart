import 'package:flutter/material.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/value_objects/team_side.dart';

class PlayerListPage extends StatefulWidget {
  const PlayerListPage({
    required this.repository,
    required this.onCreate,
    required this.onEdit,
    this.onViewAnalytics,
    super.key,
  });

  final PlayerRepository repository;
  final VoidCallback onCreate;
  final ValueChanged<Player> onEdit;
  final ValueChanged<Player>? onViewAnalytics;

  @override
  State<PlayerListPage> createState() => _PlayerListPageState();
}

class _PlayerListPageState extends State<PlayerListPage> {
  var _streamKey = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.playersTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onCreate,
        tooltip: l10n.playersCreate,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Player>>(
          key: ValueKey(_streamKey),
          stream: widget.repository.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _PlayerLoadError(
                onRetry: () => setState(() => _streamKey++),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final players = snapshot.data!;
            if (players.isEmpty) {
              return _PlayerEmptyState(onCreate: widget.onCreate);
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: players.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = players[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: Semantics(
                    button: true,
                    label:
                        '${player.nickname}, ${_playerSummary(player, l10n)}',
                    child: ListTile(
                      minTileHeight: 64,
                      leading: CircleAvatar(
                        backgroundColor: _sideColor(player.preferredSide),
                        foregroundColor: Colors.white,
                        child: Text(player.nickname.characters.first),
                      ),
                      title: Text(player.nickname),
                      subtitle: Text(_playerSummary(player, l10n)),
                      trailing: widget.onViewAnalytics == null
                          ? Tooltip(
                              message: l10n.playersEdit,
                              child: Icon(Icons.chevron_right),
                            )
                          : IconButton(
                              key: ValueKey('player-analytics-${player.id}'),
                              tooltip: l10n.playerAnalyticsTooltip,
                              icon: const Icon(Icons.insights_outlined),
                              onPressed: () => widget.onViewAnalytics!(player),
                            ),
                      onTap: () => widget.onEdit(player),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PlayerEmptyState extends StatelessWidget {
  const _PlayerEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.playersEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l10n.playersEmptyBody),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.playersCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerLoadError extends StatelessWidget {
  const _PlayerLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.playersLoadError,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l10n.playersLoadErrorBody),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retryAction),
            ),
          ],
        ),
      ),
    );
  }
}

Color _sideColor(TeamSide? side) => switch (side) {
  TeamSide.red => HoopTraceColors.red,
  TeamSide.blue => HoopTraceColors.blue,
  null => HoopTraceColors.orange,
};

String _playerSummary(Player player, AppLocalizations l10n) {
  final side = switch (player.preferredSide) {
    TeamSide.red => l10n.playersPreferredRed,
    TeamSide.blue => l10n.playersPreferredBlue,
    null => l10n.playersPreferredUnset,
  };
  final note = player.note?.trim();
  return note == null || note.isEmpty ? side : '$side · $note';
}
