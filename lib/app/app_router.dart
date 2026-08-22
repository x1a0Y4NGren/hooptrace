import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/match_session_coordinator.dart';
import 'package:hooptrace/app/match_view_data_mapper.dart';
import 'package:hooptrace/app/orientation_shell.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/features/history/history_controller.dart';
import 'package:hooptrace/features/history/history_page.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/players/player_editor_page.dart';
import 'package:hooptrace/features/players/player_list_page.dart';
import 'package:hooptrace/features/project/project_details_page.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/rules/rule_template_list_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/settings/settings_page.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';

GoRouter buildAppRouter(
  MatchSessionCoordinator matchSessions,
  PlayerRepository playerRepository,
  RuleTemplateRepository ruleTemplates,
  ExportCoordinator exports,
  AutomaticBackupService automaticBackup,
) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _HomePageShell()),
      GoRoute(
        path: '/pregame',
        builder: (context, state) => StreamBuilder(
          stream: ruleTemplates.watchAll(),
          builder: (context, snapshot) => PregamePage(
            templates: snapshot.data ?? RuleTemplateRepository.builtIns,
            onManageRules: () => context.push('/settings/rules'),
            onStartMatch: (setup) {
              context.go('/scoring/${setup.matchId}', extra: setup);
            },
          ),
        ),
      ),
      GoRoute(
        path: '/settings/rules',
        builder: (context, state) =>
            RuleTemplateListPage(repository: ruleTemplates),
      ),
      GoRoute(
        path: '/scoring/:matchId',
        builder: (context, state) {
          final setup = state.extra is MatchSetup
              ? state.extra! as MatchSetup
              : null;
          return OrientationShell(
            mode: HoopTraceOrientationMode.landscapeRequired,
            child: _buildScoringPage(
              context,
              matchSessions,
              matchId: state.pathParameters['matchId']!,
              setup: setup,
            ),
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) =>
            _HistoryRoute(matchSessions: matchSessions),
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => PlayerListPage(
          repository: playerRepository,
          onCreate: () => context.push('/players/new'),
          onEdit: (player) => context.push('/players/${player.id}/edit'),
        ),
      ),
      GoRoute(
        path: '/players/new',
        builder: (context, state) => PlayerEditorPage(
          repository: playerRepository,
          onSaved: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/players/:playerId/edit',
        builder: (context, state) => PlayerEditorPage(
          repository: playerRepository,
          playerId: state.pathParameters['playerId']!,
          onSaved: () => context.pop(),
          onDeleted: () => context.pop(),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => _SettingsRoute(
          matchSessions: matchSessions,
          exports: exports,
          automaticBackup: automaticBackup,
        ),
      ),
      GoRoute(
        path: '/project',
        builder: (context, state) => const ProjectDetailsPage(),
      ),
      GoRoute(
        path: '/matches/:matchId/replay',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return _ReplayRoute(
            key: ValueKey('replay-$matchId'),
            matchSessions: matchSessions,
            matchId: matchId,
            exports: exports,
            automaticBackup: automaticBackup,
          );
        },
      ),
    ],
  );
}

class _SettingsRoute extends StatefulWidget {
  const _SettingsRoute({
    required this.matchSessions,
    required this.exports,
    required this.automaticBackup,
  });

  final MatchSessionCoordinator matchSessions;
  final ExportCoordinator exports;
  final AutomaticBackupService automaticBackup;

  @override
  State<_SettingsRoute> createState() => _SettingsRouteState();
}

class _SettingsRouteState extends State<_SettingsRoute> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(
      exports: widget.exports,
      automaticBackup: widget.automaticBackup,
      canRestoreBackup: !widget.matchSessions.hasActiveMatch,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      controller: _controller,
      onOpenProject: () => context.push('/project'),
      onOpenRules: () => context.push('/settings/rules'),
      onDataRestored: () => context.go('/'),
    );
  }
}

class _HomePageShell extends StatelessWidget {
  const _HomePageShell();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HoopTrace'),
        actions: [
          IconButton(
            onPressed: () => context.push('/players'),
            tooltip: '球员',
            icon: const Icon(Icons.people_outline),
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => context.push('/project'),
        tooltip: '项目详情',
        child: const Icon(Icons.info_outline),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => context.push('/pregame'),
                child: Text(l10n.startScoring),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/history'),
                child: Text(l10n.replayHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildScoringPage(
  BuildContext context,
  MatchSessionCoordinator matchSessions, {
  required String matchId,
  required MatchSetup? setup,
}) {
  if (matchSessions.isCommandBacked) {
    return _CommittedScoringRoute(
      matchSessions: matchSessions,
      matchId: matchId,
      setup: setup,
      onOpenReplay: () async {
        await matchSessions.saveCurrent(matchId);
        if (context.mounted) {
          await context.push('/matches/$matchId/replay');
        }
      },
    );
  }
  final controller = setup == null
      ? matchSessions.controllerFor(matchId)
      : matchSessions.beginMatch(setup);
  if (controller == null) {
    return const _RouteMessage(title: '比赛未在进行中', message: '请从主页开始一场新比赛。');
  }

  return ScoringPage(
    controller: controller,
    onOpenReplay: () async {
      await matchSessions.saveCurrent(matchId);
      if (context.mounted) {
        await context.push('/matches/$matchId/replay');
      }
    },
  );
}

class _CommittedScoringRoute extends StatefulWidget {
  const _CommittedScoringRoute({
    required this.matchSessions,
    required this.matchId,
    required this.setup,
    required this.onOpenReplay,
  });

  final MatchSessionCoordinator matchSessions;
  final String matchId;
  final MatchSetup? setup;
  final VoidCallback onOpenReplay;

  @override
  State<_CommittedScoringRoute> createState() => _CommittedScoringRouteState();
}

class _CommittedScoringRouteState extends State<_CommittedScoringRoute> {
  late final Future<ScoringController?> _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.setup == null
        ? widget.matchSessions.loadCommitted(widget.matchId)
        : widget.matchSessions.startCommitted(widget.setup!);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScoringController?>(
      future: _controller,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _RouteMessage(
            title: '无法开始比赛',
            message: '比赛数据未提交，请返回后重试。',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final controller = snapshot.data;
        if (controller == null) {
          return const _RouteMessage(title: '比赛未在进行中', message: '请从主页开始一场新比赛。');
        }
        return ScoringPage(
          controller: controller,
          onOpenReplay: widget.onOpenReplay,
        );
      },
    );
  }
}

class _HistoryRoute extends StatelessWidget {
  const _HistoryRoute({required this.matchSessions});

  final MatchSessionCoordinator matchSessions;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: matchSessions.repository.watchHistory(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _RouteMessage(
            title: '无法读取比赛记录',
            message: '本地记录暂时无法打开，请返回后重试。',
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return HistoryPage(
          controller: HistoryController(
            matches: snapshot.data!
                .map(historySummaryFromEntry)
                .toList(growable: false),
          ),
          onMatchTap: (matchId) => context.push('/matches/$matchId/replay'),
          onHome: () => context.go('/'),
        );
      },
    );
  }
}

class _ReplayRoute extends StatefulWidget {
  const _ReplayRoute({
    required this.matchSessions,
    required this.matchId,
    required this.exports,
    required this.automaticBackup,
    super.key,
  });

  final MatchSessionCoordinator matchSessions;
  final String matchId;
  final ExportCoordinator exports;
  final AutomaticBackupService automaticBackup;

  @override
  State<_ReplayRoute> createState() => _ReplayRouteState();
}

class _ReplayRouteState extends State<_ReplayRoute> {
  late Future<ReplayController?> _controller;
  ReplayController? _ownedController;

  @override
  void initState() {
    super.initState();
    _controller = _loadController();
  }

  Future<ReplayController?> _loadController() async {
    await widget.matchSessions.saveCurrent(widget.matchId);
    final detail = await widget.matchSessions.repository.getMatchDetail(
      widget.matchId,
    );
    if (detail == null) {
      return null;
    }
    final editable = !widget.matchSessions.isActive(widget.matchId);
    late ReplayController controller;
    Future<void> refreshData() async {
      final refreshed = await widget.matchSessions.repository.getMatchDetail(
        widget.matchId,
      );
      if (refreshed != null) {
        controller.replaceData(replayDataFromDetail(refreshed));
      }
    }

    controller = ReplayController(
      data: replayDataFromDetail(detail),
      onMoveShotLocation: editable
          ? (locationId, point, reason) async {
              await widget.matchSessions.repository.moveShotLocation(
                locationId: locationId,
                point: point,
                reason: reason,
              );
              await refreshData();
            }
          : null,
      onSoftDeleteEvent: editable
          ? (eventId, reason) async {
              await widget.matchSessions.repository.softDeleteEvent(
                eventId: eventId,
                reason: reason,
              );
              await refreshData();
            }
          : null,
      onUpdateEventNote: editable
          ? (eventId, note, reason) async {
              await widget.matchSessions.repository.updateEventNote(
                eventId: eventId,
                note: note,
                reason: reason,
              );
              await refreshData();
            }
          : null,
      loadAuditLogs: () =>
          widget.matchSessions.repository.listAuditLogs(widget.matchId),
    );
    return _ownedController = controller;
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReplayController?>(
      future: _controller,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _RouteMessage(
            title: '无法打开复盘',
            message: '比赛数据读取失败，请返回后重试。',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final controller = snapshot.data;
        if (controller == null) {
          return const _RouteMessage(title: '没有找到这场比赛', message: '记录可能已被移除。');
        }
        final active = widget.matchSessions.isActive(widget.matchId);
        return ReplayPage(
          controller: controller,
          onShareSummary: (bytes, matchId) =>
              widget.exports.shareReplayImage(bytes, matchId: matchId),
          onFinishMatch: active
              ? () async {
                  await widget.matchSessions.finishMatch(widget.matchId);
                  try {
                    await widget.automaticBackup.runIfEnabled();
                  } on Object {
                    // Finishing a match succeeds even if its backup folder moved.
                  }
                  if (context.mounted) {
                    context.go('/history');
                  }
                }
              : null,
        );
      },
    );
  }
}

class _RouteMessage extends StatelessWidget {
  const _RouteMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
