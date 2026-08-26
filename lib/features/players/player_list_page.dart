import 'package:flutter/material.dart';
import 'package:hooptrace/app/design_system/design_system.dart';
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
    final canPop = Navigator.of(context).canPop();
    return EditorialScaffold(
      maxContentWidth: 960,
      masthead: EditorialMasthead(
        title: l10n.playersTitle,
        leading: canPop
            ? EditorialTapTarget(
                onPressed: () => Navigator.maybePop(context),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                child: const Icon(Icons.arrow_back),
              )
            : null,
        trailing: EditorialTapTarget(
          key: const Key('player-create'),
          onPressed: widget.onCreate,
          tooltip: l10n.playersCreate,
          label: l10n.playersCreate,
          child: const Icon(Icons.person_add_alt_1),
        ),
      ),
      body: StreamBuilder<List<Player>>(
        key: ValueKey(_streamKey),
        stream: widget.repository.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StateViewport(
              child: EditorialErrorState(
                title: l10n.playersLoadError,
                message: l10n.playersLoadErrorBody,
                actionLabel: l10n.retryAction,
                onAction: () => setState(() => _streamKey++),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final players = snapshot.data!;
          if (players.isEmpty) {
            return _StateViewport(
              child: EditorialEmptyState(
                title: l10n.playersEmptyTitle,
                message: l10n.playersEmptyBody,
                actionLabel: l10n.playersCreate,
                onAction: widget.onCreate,
                icon: Icons.people_outline,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: HoopTraceSpacing.section),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final sideColor = _sideColor(context, player.preferredSide);
              return EditorialIndexRow(
                key: ValueKey('player-row-${player.id}'),
                index: '${index + 1}'.padLeft(2, '0'),
                title: player.nickname,
                subtitle: _playerSummary(player, l10n),
                onTap: () => widget.onEdit(player),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      key: ValueKey('player-avatar-${player.id}'),
                      radius: 18,
                      backgroundColor: sideColor,
                      foregroundColor: accessibleForegroundFor(sideColor),
                      child: Text(
                        player.nickname.characters.first,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (widget.onViewAnalytics != null) ...[
                      const SizedBox(width: 4),
                      EditorialTapTarget(
                        key: ValueKey('player-analytics-${player.id}'),
                        tooltip: l10n.playerAnalyticsTooltip,
                        label:
                            '${player.nickname}, ${l10n.playerAnalyticsTooltip}',
                        onPressed: () => widget.onViewAnalytics!(player),
                        child: const Icon(Icons.insights_outlined, size: 20),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StateViewport extends StatelessWidget {
  const _StateViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

Color _sideColor(BuildContext context, TeamSide? side) {
  final editorial = editorialThemeOf(context);
  return switch (side) {
    TeamSide.red => editorial.teamRed,
    TeamSide.blue => editorial.teamBlue,
    null => editorial.ink,
  };
}

String _playerSummary(Player player, AppLocalizations l10n) {
  final side = switch (player.preferredSide) {
    TeamSide.red => l10n.playersPreferredRed,
    TeamSide.blue => l10n.playersPreferredBlue,
    null => l10n.playersPreferredUnset,
  };
  final note = player.note?.trim();
  return note == null || note.isEmpty ? side : '$side · $note';
}
