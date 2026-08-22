import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/match_view_data_mapper.dart';
import 'package:hooptrace/app/orientation_shell.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/features/history/history_controller.dart';
import 'package:hooptrace/features/history/history_page.dart';
import 'package:hooptrace/features/home/home_page.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/players/player_editor_page.dart';
import 'package:hooptrace/features/players/player_list_page.dart';
import 'package:hooptrace/features/project/project_details_page.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/rules/rule_template_list_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:hooptrace/features/settings/settings_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = buildProviderAppRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter buildProviderAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _HomeRoute()),
      GoRoute(
        path: '/pregame',
        builder: (context, state) => const _PregameRoute(),
      ),
      GoRoute(
        path: '/settings/rules',
        builder: (context, state) => Consumer(
          builder: (context, ref, child) => RuleTemplateListPage(
            repository: ref.watch(ruleTemplateRepositoryProvider),
          ),
        ),
      ),
      GoRoute(
        path: '/scoring/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return OrientationShell(
            mode: HoopTraceOrientationMode.landscapeRequired,
            child: _ScoringRoute(matchId: matchId),
          );
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const _HistoryRoute(),
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => Consumer(
          builder: (context, ref, child) => PlayerListPage(
            repository: ref.watch(playerRepositoryProvider),
            onCreate: () => context.push('/players/new'),
            onEdit: (player) => context.push('/players/${player.id}/edit'),
          ),
        ),
      ),
      GoRoute(
        path: '/players/new',
        builder: (context, state) => Consumer(
          builder: (context, ref, child) => PlayerEditorPage(
            repository: ref.watch(playerRepositoryProvider),
            onSaved: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: '/players/:playerId/edit',
        builder: (context, state) => Consumer(
          builder: (context, ref, child) => PlayerEditorPage(
            repository: ref.watch(playerRepositoryProvider),
            playerId: state.pathParameters['playerId']!,
            onSaved: () => context.pop(),
            onDeleted: () => context.pop(),
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _SettingsRoute(),
      ),
      GoRoute(
        path: '/project',
        builder: (context, state) => const ProjectDetailsPage(),
      ),
      GoRoute(
        path: '/matches/:matchId/replay',
        builder: (context, state) => _ReplayRoute(
          key: ValueKey('provider-replay-${state.pathParameters['matchId']}'),
          matchId: state.pathParameters['matchId']!,
        ),
      ),
    ],
  );
}

class _HomeRoute extends ConsumerWidget {
  const _HomeRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeMatchProvider);
    return active.when(
      loading: () => const _RouteLoading(),
      error: (error, stackTrace) =>
          _RouteMessage(title: '无法读取进行中的比赛', message: '$error'),
      data: (detail) => HomePage(
        activeMatch: detail,
        onStartScoring: () {
          if (detail != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text('已有进行中的比赛，请先继续或放弃它。')),
              );
            return;
          }
          context.push('/pregame');
        },
        onContinue: detail == null
            ? () {}
            : () => context.go('/scoring/${detail.match.id}'),
        onAbandon: detail == null
            ? () async {}
            : () => _abandon(context, ref, detail.match.id),
        onOpenHistory: () => context.push('/history'),
        onOpenPlayers: () => context.push('/players'),
        onOpenSettings: () => context.push('/settings'),
        onOpenProject: () => context.push('/project'),
      ),
    );
  }
}

class _PregameRoute extends ConsumerWidget {
  const _PregameRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeState = ref.watch(activeMatchProvider);
    if (activeState.isLoading) return const _RouteLoading();
    if (activeState.hasError) {
      return const _RouteMessage(
        title: '无法确认进行中的比赛',
        message: '请返回主页后重试，避免在状态未确认时创建新比赛。',
      );
    }
    final active = activeState.valueOrNull;
    if (active != null) {
      return _ActiveMatchGatePage(
        detail: active,
        onContinue: () => context.go('/scoring/${active.match.id}'),
        onAbandon: () => _abandon(context, ref, active.match.id),
      );
    }

    final templates = ref.watch(ruleTemplatesProvider);
    return templates.when(
      loading: () => const _RouteLoading(),
      error: (error, stackTrace) => PregamePage(
        templates: RuleTemplateRepositoryFallback.templates,
        onStartMatch: (setup) => unawaited(_startMatch(context, ref, setup)),
      ),
      data: (values) => PregamePage(
        templates: values,
        onManageRules: () => context.push('/settings/rules'),
        onStartMatch: (setup) => unawaited(_startMatch(context, ref, setup)),
      ),
    );
  }
}

class _ScoringRoute extends ConsumerWidget {
  const _ScoringRoute({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(liveMatchProvider(matchId));
    final controller = ref.watch(scoringControllerProvider(matchId));
    if (detail.isLoading || controller == null) return const _RouteLoading();
    if (detail.hasError || detail.valueOrNull == null) {
      return const _RouteMessage(title: '比赛未在进行中', message: '请从主页继续一场活动比赛。');
    }
    return ScoringPage(
      controller: controller,
      onOpenReplay: () => context.push('/matches/$matchId/replay'),
      onRequestLeave: () => _leaveScoring(context, ref, matchId),
    );
  }
}

class _HistoryRoute extends ConsumerWidget {
  const _HistoryRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return history.when(
      loading: () => const _RouteLoading(),
      error: (error, stackTrace) =>
          _RouteMessage(title: '无法读取比赛记录', message: '$error'),
      data: (entries) => HistoryPage(
        controller: HistoryController(
          matches: entries.map(historySummaryFromEntry).toList(growable: false),
        ),
        onMatchTap: (matchId) => context.push('/matches/$matchId/replay'),
        onHome: () => context.go('/'),
      ),
    );
  }
}

class _SettingsRoute extends ConsumerWidget {
  const _SettingsRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsPage(
      controller: ref.watch(settingsControllerProvider),
      onOpenProject: () => context.push('/project'),
      onOpenRules: () => context.push('/settings/rules'),
      onDataRestored: () => context.go('/'),
    );
  }
}

class _ReplayRoute extends ConsumerStatefulWidget {
  const _ReplayRoute({required this.matchId, super.key});

  final String matchId;

  @override
  ConsumerState<_ReplayRoute> createState() => _ReplayRouteState();
}

class _ReplayRouteState extends ConsumerState<_ReplayRoute> {
  late Future<ReplayController?> _future;
  ReplayController? _controller;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ReplayController?> _load() async {
    final repository = ref.read(matchRepositoryProvider);
    final detail = await repository.getMatchDetail(widget.matchId);
    if (detail == null) return null;
    final active =
        ref.read(activeMatchProvider).valueOrNull?.match.id == widget.matchId;
    late final ReplayController controller;
    Future<void> refresh() async {
      final refreshed = await repository.getMatchDetail(widget.matchId);
      if (refreshed != null) {
        controller.replaceData(replayDataFromDetail(refreshed));
      }
    }

    controller = ReplayController(
      data: replayDataFromDetail(detail),
      onMoveShotLocation: active
          ? null
          : (locationId, point, reason) async {
              await repository.moveShotLocation(
                locationId: locationId,
                point: point,
                reason: reason,
              );
              await refresh();
            },
      onSoftDeleteEvent: active
          ? null
          : (eventId, reason) async {
              await repository.softDeleteEvent(
                eventId: eventId,
                reason: reason,
              );
              await refresh();
            },
      onUpdateEventNote: active
          ? null
          : (eventId, note, reason) async {
              await repository.updateEventNote(
                eventId: eventId,
                note: note,
                reason: reason,
              );
              await refresh();
            },
      loadAuditLogs: () => repository.listAuditLogs(widget.matchId),
    );
    return _controller = controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active =
        ref.watch(activeMatchProvider).valueOrNull?.match.id == widget.matchId;
    return FutureBuilder<ReplayController?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _RouteMessage(
            title: '无法打开复盘',
            message: '比赛数据读取失败，请返回后重试。',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _RouteLoading();
        }
        final controller = snapshot.data;
        if (controller == null) {
          return const _RouteMessage(title: '没有找到这场比赛', message: '记录可能已被移除。');
        }
        return ReplayPage(
          controller: controller,
          onShareSummary: (bytes, matchId) => ref
              .read(exportCoordinatorProvider)
              .shareReplayImage(bytes, matchId: matchId),
          onFinishMatch: active
              ? () async {
                  await ref
                      .read(matchCommandServiceProvider)
                      .finish(
                        FinishMatchCommand(
                          matchId: widget.matchId,
                          endedAt: DateTime.now().toUtc(),
                        ),
                      );
                  try {
                    await ref
                        .read(automaticBackupServiceProvider)
                        .runIfEnabled();
                  } on Object {
                    // A moved backup folder does not undo a successful finish.
                  }
                  if (context.mounted) context.go('/history');
                }
              : null,
        );
      },
    );
  }
}

class _ActiveMatchGatePage extends StatelessWidget {
  const _ActiveMatchGatePage({
    required this.detail,
    required this.onContinue,
    required this.onAbandon,
  });

  final MatchDetail detail;
  final VoidCallback onContinue;
  final Future<void> Function() onAbandon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('已有进行中的比赛')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${detail.match.redName} ${detail.redScore} : ${detail.blueScore} ${detail.match.blueName}',
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: onContinue, child: const Text('继续比赛')),
                OutlinedButton(
                  key: homeAbandonKey,
                  onPressed: () => onAbandon(),
                  child: const Text('放弃比赛'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _startMatch(
  BuildContext context,
  WidgetRef ref,
  MatchSetup setup,
) async {
  try {
    final activeState = ref.read(activeMatchProvider);
    if (!activeState.hasValue) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正在确认是否已有进行中的比赛，请稍后再试。')));
      return;
    }
    final active = activeState.valueOrNull;
    if (active != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已有进行中的比赛，请先继续或放弃它。')));
      return;
    }
    await ref.read(matchCommandServiceProvider).start(_commandForSetup(setup));
    if (context.mounted) context.go('/scoring/${setup.matchId}');
  } on MatchCommandFailure catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

StartMatchCommand _commandForSetup(MatchSetup setup) {
  return StartMatchCommand(
    matchId: setup.matchId,
    redName: setup.redName,
    blueName: setup.blueName,
    ruleTemplate: RuleTemplate(
      id: setup.ruleTemplateId,
      name: setup.ruleTemplateName ?? setup.ruleTemplateId,
      scoreButtons: List.unmodifiable(setup.scoreButtons),
      targetScore: setup.targetScore,
      timeLimitSeconds: setup.timerEnabled ? setup.timeLimitMinutes * 60 : null,
      winByTwo: setup.winByTwo,
      foulLimit: setup.foulLimit,
      possessionHintEnabled: setup.possessionHintEnabled,
      customEventTypes: List.unmodifiable(setup.customEventTypes),
    ),
    timerEnabled: setup.timerEnabled,
    regulationSeconds: setup.timerEnabled ? setup.timeLimitMinutes * 60 : null,
    createdAt: DateTime.now().toUtc(),
    startedAt: DateTime.now().toUtc(),
  );
}

Future<void> _abandon(
  BuildContext context,
  WidgetRef ref,
  String matchId,
) async {
  try {
    await ref
        .read(matchCommandServiceProvider)
        .abandon(
          AbandonMatchCommand(
            matchId: matchId,
            endedAt: DateTime.now().toUtc(),
          ),
        );
  } on MatchCommandFailure catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

Future<void> _leaveScoring(
  BuildContext context,
  WidgetRef ref,
  String matchId,
) async {
  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('离开比赛'),
      content: const Text('可以继续计时，或先暂停再离开。'),
      actions: [
        TextButton(
          key: const Key('leave-stay'),
          onPressed: () => Navigator.of(dialogContext).pop('stay'),
          child: const Text('留在比赛'),
        ),
        TextButton(
          key: const Key('leave-keep-running'),
          onPressed: () => Navigator.of(dialogContext).pop('keep'),
          child: const Text('继续运行'),
        ),
        FilledButton(
          key: const Key('leave-pause-and-leave'),
          onPressed: () => Navigator.of(dialogContext).pop('pause'),
          child: const Text('暂停并离开'),
        ),
      ],
    ),
  );
  if (action == 'pause') {
    try {
      await ref
          .read(matchCommandServiceProvider)
          .pause(
            PauseMatchCommand(
              matchId: matchId,
              occurredAt: DateTime.now().toUtc(),
            ),
          );
    } on MatchCommandFailure catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
  }
  if ((action == 'keep' || action == 'pause') && context.mounted) {
    context.pop();
  }
}

class _RouteLoading extends StatelessWidget {
  const _RouteLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

/// Keeps a stable fallback name at the provider boundary without making the
/// route construct a repository or a second source of state.
class RuleTemplateRepositoryFallback {
  static List<RuleTemplate> get templates => const [
    RuleTemplate(id: 'free', name: '自由计分', scoreButtons: [1, 2, 3]),
  ];
}
