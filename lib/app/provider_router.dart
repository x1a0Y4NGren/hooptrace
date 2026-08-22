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
import 'package:hooptrace/features/pregame/start_match_mapper.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/players/player_editor_page.dart';
import 'package:hooptrace/features/players/player_list_page.dart';
import 'package:hooptrace/features/project/project_details_page.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/rules/rule_template_list_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';
import 'package:hooptrace/features/settings/settings_page.dart';

enum LeaveScoringAction { keep, pause }

enum LeaveClockTransition { unknown, noCommand, resume, pause }

/// The action-time snapshot is a separate provider edge so tests and future
/// platform lifecycle hooks can force an unresolved state without replacing
/// the live scoring projection used to render the page.
final leaveScoringProjectionProvider =
    Provider.family<AsyncValue<MatchDetail?>, String>(
      (ref, matchId) => ref.watch(liveMatchProvider(matchId)),
    );

/// Maps a settled active projection to the command, if any, needed before
/// leaving scoring. An unresolved projection deliberately fails closed so a
/// stale or missing clock cannot silently navigate away from the match.
LeaveClockTransition leaveClockTransitionFor(
  AsyncValue<MatchDetail?> state,
  LeaveScoringAction action,
) {
  if (state.isLoading || state.hasError || !state.hasValue) {
    return LeaveClockTransition.unknown;
  }
  final projection = state.valueOrNull;
  if (projection == null || projection.match.lifecycle.name != 'active') {
    return LeaveClockTransition.unknown;
  }
  if (!projection.match.timerEnabled) {
    return LeaveClockTransition.noCommand;
  }
  final clock = projection.clock;
  if (clock == null) {
    return LeaveClockTransition.unknown;
  }
  final isRunning = clock.isRunning;
  return switch (action) {
    LeaveScoringAction.keep =>
      isRunning ? LeaveClockTransition.noCommand : LeaveClockTransition.resume,
    LeaveScoringAction.pause =>
      isRunning ? LeaveClockTransition.pause : LeaveClockTransition.noCommand,
  };
}

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
    // A missing/terminal/error projection is a real route state. Check it
    // before controller availability so a controller that is still being
    // reconstructed cannot mask a useful explanation with an endless
    // loading page.
    if (detail.hasError) {
      return _RouteMessage(title: '无法读取比赛', message: '${detail.error}');
    }
    if (detail.hasValue) {
      final projection = detail.valueOrNull;
      if (projection == null || projection.match.lifecycle.name != 'active') {
        return const _RouteMessage(title: '比赛未在进行中', message: '请从主页继续一场活动比赛。');
      }
      final controller = ref.watch(scoringControllerProvider(matchId));
      if (controller == null) {
        return const _RouteMessage(
          title: '正在恢复比赛',
          message: '已读取比赛，但计分状态还在恢复，请稍候。',
        );
      }
      final canResumeClock =
          projection.match.timerEnabled &&
          projection.clock != null &&
          !projection.clock!.isRunning;
      return ScoringPage(
        controller: controller,
        onOpenReplay: () => context.push('/matches/$matchId/replay'),
        onRequestLeave: () => _leaveScoring(context, ref, matchId),
        onResumeClock: canResumeClock
            ? () => _resumeScoring(context, ref, matchId)
            : null,
      );
    }
    return const _RouteLoading();
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
    await ref
        .read(matchCommandServiceProvider)
        .start(buildStartMatchCommand(setup));
    if (context.mounted) context.go('/scoring/${setup.matchId}');
  } on PregameSetupValidationException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请完成赛前设置：${error.result.errors.join('、')}')),
      );
    }
  } on MatchCommandFailure catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
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

Future<void> _resumeScoring(
  BuildContext context,
  WidgetRef ref,
  String matchId,
) async {
  try {
    await ref
        .read(matchCommandServiceProvider)
        .resume(
          ResumeMatchCommand(
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
  if (action != 'keep' && action != 'pause') return;

  final transition = leaveClockTransitionFor(
    ref.read(leaveScoringProjectionProvider(matchId)),
    action == 'keep' ? LeaveScoringAction.keep : LeaveScoringAction.pause,
  );
  if (transition == LeaveClockTransition.unknown) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('无法确认计时状态，请留在比赛中重试。')));
    }
    return;
  }

  // The live projection is the durable source of truth for this decision.
  // In particular, do not issue a second pause to an already-paused match:
  // the command layer correctly rejects that duplicate semantic command.
  final commandService = ref.read(matchCommandServiceProvider);
  try {
    if (transition == LeaveClockTransition.resume) {
      await commandService.resume(
        ResumeMatchCommand(
          matchId: matchId,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
    } else if (transition == LeaveClockTransition.pause) {
      await commandService.pause(
        PauseMatchCommand(matchId: matchId, occurredAt: DateTime.now().toUtc()),
      );
    }
  } on MatchCommandFailure catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return;
  }
  if (context.mounted) {
    // Scoring is entered with `go`, so there may be no back-stack entry to
    // pop. Leaving must return to the durable home projection explicitly.
    context.go('/');
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
