import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/app_providers.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/l10n/app_localizations_zh.dart';
import 'package:hooptrace/app/match_view_data_mapper.dart';
import 'package:hooptrace/app/orientation_shell.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/data/repositories/match_lifecycle_repository.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_history_entry.dart';
import 'package:hooptrace/core/domain/domain_enums.dart';
import 'package:hooptrace/core/domain/entities/player.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/features/history/history_controller.dart';
import 'package:hooptrace/features/history/history_page.dart';
import 'package:hooptrace/features/home/home_page.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/pregame/start_match_mapper.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/players/player_editor_page.dart';
import 'package:hooptrace/features/players/player_career_page.dart';
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
            onViewAnalytics: (player) =>
                context.push('/players/${player.id}/analytics'),
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
        path: '/players/:playerId/analytics',
        builder: (context, state) => Consumer(
          builder: (context, ref, child) {
            final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
            final playerId = state.pathParameters['playerId']!;
            final players = ref.watch(playerProfilesProvider);
            return players.when(
              loading: () => const _RouteLoading(),
              error: (error, stackTrace) => _RouteMessage(
                title: l10n.playerAnalyticsLoadError,
                message: l10n.actionFailedRetry,
              ),
              data: (values) {
                final player = values
                    .where((value) => value.id == playerId)
                    .firstOrNull;
                if (player == null) {
                  return _RouteMessage(
                    title: l10n.playerAnalyticsNotFound,
                    message: l10n.playerAnalyticsNotFoundBody,
                  );
                }
                return PlayerCareerPage(
                  controller: ref.watch(
                    playerCareerControllerProvider(playerId),
                  ),
                  player: player,
                  opponents: values
                      .where((value) => value.id != playerId)
                      .toList(growable: false),
                );
              },
            );
          },
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
        builder: (context, state) =>
            _ReplayRoute(matchId: state.pathParameters['matchId']!),
      ),
    ],
  );
}

class _HomeRoute extends ConsumerWidget {
  const _HomeRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final active = ref.watch(activeMatchProvider);
    return active.when(
      loading: () => const _RouteLoading(),
      error: (error, stackTrace) => _RouteMessage(
        title: l10n.routeHomeLoadError,
        message: l10n.actionFailedRetry,
      ),
      data: (detail) => HomePage(
        activeMatch: detail,
        onStartScoring: () {
          if (detail != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.routeActiveMatchTitle)),
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final activeState = ref.watch(activeMatchProvider);
    if (activeState.isLoading) return const _RouteLoading();
    if (activeState.hasError) {
      return _RouteMessage(
        title: l10n.routeActiveMatchCheckError,
        message: l10n.routeActiveMatchCheckBody,
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
    final players = ref.watch(playerProfilesProvider);
    return templates.when(
      loading: () => const _RouteLoading(),
      error: (error, stackTrace) => _buildPregamePage(
        context,
        ref,
        RuleTemplateRepositoryFallback.templates,
        players,
        l10n: l10n,
        templatesError: true,
      ),
      data: (values) =>
          _buildPregamePage(context, ref, values, players, l10n: l10n),
    );
  }
}

Widget _buildPregamePage(
  BuildContext context,
  WidgetRef ref,
  List<RuleTemplate> templates,
  AsyncValue<List<Player>> players, {
  required AppLocalizations l10n,
  bool templatesError = false,
}) {
  return players.when(
    loading: () => PregamePage(
      templates: templates,
      playersNotice: templatesError
          ? l10n.pregameTemplatesFallbackLoading
          : l10n.pregamePlayersLoading,
      onManageRules: () => context.push('/settings/rules'),
      onStartMatch: (setup) => unawaited(_startMatch(context, ref, setup)),
    ),
    error: (error, stackTrace) => PregamePage(
      templates: templates,
      playersNotice: templatesError
          ? l10n.pregameTemplatesPlayersError
          : l10n.pregamePlayersError,
      onManageRules: () => context.push('/settings/rules'),
      onStartMatch: (setup) => unawaited(_startMatch(context, ref, setup)),
    ),
    data: (values) => PregamePage(
      templates: templates,
      players: values,
      playersNotice: templatesError
          ? l10n.pregameTemplatesFallbackNotice
          : null,
      onManageRules: () => context.push('/settings/rules'),
      onStartMatch: (setup) => unawaited(_startMatch(context, ref, setup)),
    ),
  );
}

class _ScoringRoute extends ConsumerWidget {
  const _ScoringRoute({required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    final detail = ref.watch(liveMatchProvider(matchId));
    // A missing/terminal/error projection is a real route state. Check it
    // before controller availability so a controller that is still being
    // reconstructed cannot mask a useful explanation with an endless
    // loading page.
    if (detail.hasError) {
      return _RouteMessage(
        title: l10n.routeMatchLoadError,
        message: l10n.actionFailedRetry,
        onHome: () => context.go('/'),
      );
    }
    if (detail.hasValue) {
      final projection = detail.valueOrNull;
      final canViewReplay =
          projection != null &&
          (projection.match.lifecycle == MatchLifecycle.finished ||
              projection.match.lifecycle == MatchLifecycle.archived);
      if (projection == null || projection.match.lifecycle.name != 'active') {
        return _RouteMessage(
          title: l10n.routeMatchNotActive,
          message: l10n.routeMatchNotActiveBody,
          onHome: () => context.go('/'),
          onReplay: canViewReplay
              ? () => context.go('/matches/$matchId/replay')
              : null,
        );
      }
      final controller = ref.watch(scoringControllerProvider(matchId));
      if (controller == null) {
        return _RouteMessage(
          title: l10n.routeMatchRestoring,
          message: l10n.routeMatchRestoringBody,
          onHome: () => context.go('/'),
        );
      }
      final canResumeClock =
          projection.decision == null &&
          projection.match.timerEnabled &&
          projection.clock != null &&
          !projection.clock!.isRunning;
      final feedback = ref.watch(scoringFeedbackServiceProvider);
      return ScoringPage(
        controller: controller,
        onOpenReplay: () => context.push('/matches/$matchId/replay'),
        onRequestLeave: () => _leaveScoring(context, ref, matchId),
        onResumeClock: canResumeClock
            ? () => _resumeScoring(context, ref, matchId)
            : null,
        onContinueDecision: projection.decision?.canContinue == true
            ? () => _continueScoringDecision(ref, matchId)
            : null,
        onFinishDecision: projection.decision?.canFinish == true
            ? (redScore, blueScore) => _finishScoringDecision(
                context,
                ref,
                matchId,
                redScore,
                blueScore,
              )
            : null,
        onActionCommitted: feedback.emitCommitted,
      );
    }
    return const _RouteLoading();
  }
}

class _HistoryRoute extends ConsumerStatefulWidget {
  const _HistoryRoute();

  @override
  ConsumerState<_HistoryRoute> createState() => _HistoryRouteState();
}

class _HistoryRouteState extends ConsumerState<_HistoryRoute> {
  late final HistoryController _controller;
  List<HistoryMatchSummary> _importedIncompleteMatches = const [];
  bool _importedIncompleteLoadError = false;

  @override
  void initState() {
    super.initState();
    _controller = HistoryController(
      matches: const [],
      dataSource: _RepositoryHistoryDataSource(
        ref.read(matchRepositoryProvider),
        ref.read(matchLifecycleRepositoryProvider),
      ),
    );
    unawaited(_controller.loadNextPage());
    unawaited(_loadImportedIncomplete());
  }

  Future<void> _loadImportedIncomplete() async {
    if (mounted) {
      setState(() => _importedIncompleteLoadError = false);
    }
    try {
      final page = await ref
          .read(matchRepositoryProvider)
          .queryImportedIncomplete();
      if (!mounted) return;
      setState(() {
        _importedIncompleteMatches = page.entries
            .map(historySummaryFromEntry)
            .toList(growable: false);
        _importedIncompleteLoadError = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _importedIncompleteLoadError = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeMatchProvider).valueOrNull;
    return HistoryPage(
      controller: _controller,
      activeMatch: active == null ? null : _historySummaryFromActive(active),
      onResumeActive: active == null
          ? null
          : () => context.go('/scoring/${active.match.id}'),
      importedIncompleteMatches: _importedIncompleteMatches,
      onResumeImportedIncomplete: (matchId) =>
          _resumeImportedIncomplete(context, ref, matchId),
      importedIncompleteLoadError: _importedIncompleteLoadError,
      onRetryImportedIncomplete: () => unawaited(_loadImportedIncomplete()),
      onArchive: (matchId) => _controller.archiveMatch(matchId),
      onUnarchive: (matchId) => _controller.unarchiveMatch(matchId),
      onDelete: (matchId) => _controller.deleteMatch(matchId, confirmed: true),
      onMatchTap: (matchId) => context.push('/matches/$matchId/replay'),
      onHome: () => context.go('/'),
    );
  }

  Future<void> _resumeImportedIncomplete(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) async {
    try {
      await ref
          .read(matchCommandServiceProvider)
          .resumeImportedIncomplete(
            ResumeImportedIncompleteMatchCommand(matchId: matchId),
          );
      if (context.mounted) context.go('/scoring/$matchId');
    } on MatchCommandFailure {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.historyResumeImportedIncompleteFailed)),
        );
      await _loadImportedIncomplete();
    }
  }
}

class _RepositoryHistoryDataSource implements HistoryDataSource {
  const _RepositoryHistoryDataSource(this.repository, this.lifecycle);

  final MatchRepository repository;
  final MatchLifecycleRepository lifecycle;

  @override
  Future<HistoryPageResult> loadPage({
    required HistoryFilters filters,
    required int limit,
    String? cursor,
  }) async {
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final recordingMode = filters.recordingMode == null
        ? null
        : RecordingMode.values
              .where((mode) => mode.name == filters.recordingMode)
              .firstOrNull;
    final selectedLifecycles = switch (filters.lifecycle) {
      HistoryLifecycleFilter.finished => {MatchLifecycle.finished},
      HistoryLifecycleFilter.archived => {MatchLifecycle.archived},
      HistoryLifecycleFilter.all => {
        MatchLifecycle.finished,
        MatchLifecycle.archived,
      },
    };
    final page = await repository.queryHistory(
      filter: MatchHistoryFilter(
        search: filters.search.trim().isEmpty ? null : filters.search.trim(),
        from: filters.from?.toUtc(),
        to: filters.to?.add(const Duration(days: 1)).toUtc(),
        ruleName: filters.ruleName?.trim().isEmpty == true
            ? null
            : filters.ruleName?.trim(),
        recordingMode: recordingMode,
        lifecycles: selectedLifecycles,
      ),
      offset: offset,
      limit: limit,
    );
    return HistoryPageResult(
      entries: page.entries
          .map(historySummaryFromEntry)
          .toList(growable: false),
      nextCursor: page.nextOffset == null ? null : '${page.nextOffset}',
    );
  }

  @override
  Future<void> archiveMatch(String matchId) => lifecycle.archive(matchId);

  @override
  Future<void> unarchiveMatch(String matchId) => lifecycle.unarchive(matchId);

  @override
  Future<void> permanentlyDeleteMatch(String matchId) =>
      lifecycle.permanentlyDelete(matchId, confirmed: true);
}

HistoryMatchSummary _historySummaryFromActive(MatchDetail detail) {
  return HistoryMatchSummary(
    matchId: detail.match.id,
    playedAt: (detail.match.startedAt ?? detail.match.createdAt).toLocal(),
    redName: detail.match.redName,
    blueName: detail.match.blueName,
    redScore: detail.redScore,
    blueScore: detail.blueScore,
    ruleName: detail.match.ruleTemplateSnapshot.name,
    duration: detail.duration ?? Duration.zero,
    locatedShots: detail.locatedShotCount,
    scoringEvents: detail.shotAttemptCount,
    lifecycle: HistoryMatchLifecycle.active,
    recordingMode: detail.match.recordingMode.name,
  );
}

class _SettingsRoute extends ConsumerWidget {
  const _SettingsRoute();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsPage(
      controller: ref.watch(settingsControllerProvider),
      themeController: ref.watch(themePreferencesControllerProvider),
      languageController: ref.watch(languagePreferencesControllerProvider),
      onOpenProject: () => context.push('/project'),
      onOpenRules: () => context.push('/settings/rules'),
      onDataRestored: () => context.go('/'),
    );
  }
}

class _ReplayRoute extends ConsumerStatefulWidget {
  const _ReplayRoute({required this.matchId});

  final String matchId;

  @override
  ConsumerState<_ReplayRoute> createState() => _ReplayRouteState();
}

class _ReplayRouteState extends ConsumerState<_ReplayRoute> {
  late Future<ReplayController?> _future;
  ReplayController? _controller;
  MatchLifecycle? _lifecycle;
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    _startLoad();
  }

  @override
  void didUpdateWidget(covariant _ReplayRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId == widget.matchId) return;
    _controller?.dispose();
    _controller = null;
    _lifecycle = null;
    _startLoad();
  }

  void _startLoad() {
    final generation = ++_requestGeneration;
    final matchId = widget.matchId;
    _future = _load(generation, matchId);
  }

  bool _isCurrent(int generation, String matchId) {
    return mounted &&
        generation == _requestGeneration &&
        widget.matchId == matchId;
  }

  bool _isReplayRouteCurrent(GoRouter router, int generation, String matchId) {
    if (!_isCurrent(generation, matchId)) return false;
    final modalRoute = ModalRoute.of(context);
    return modalRoute?.isCurrent == true ||
        router.routeInformationProvider.value.uri.path ==
            '/matches/$matchId/replay';
  }

  Future<ReplayController?> _load(int generation, String matchId) async {
    final repository = ref.read(matchRepositoryProvider);
    final detail = await repository.getMatchDetail(matchId);
    if (!_isCurrent(generation, matchId)) return null;
    if (detail == null) return null;
    _lifecycle = detail.match.lifecycle;
    final replayEditable =
        detail.match.lifecycle == MatchLifecycle.finished ||
        detail.match.lifecycle == MatchLifecycle.archived;
    final commandService = ref.read(matchCommandServiceProvider);
    late final ReplayController controller;
    Future<void> refresh() async {
      final refreshed = await repository.getMatchDetail(matchId);
      if (_isCurrent(generation, matchId) && refreshed != null) {
        controller.replaceData(replayDataFromDetail(refreshed));
      }
    }

    controller = ReplayController(
      data: replayDataFromDetail(detail),
      onCorrectEvent: replayEditable
          ? (correction) async {
              try {
                final projection = await commandService.correct(
                  CorrectMatchEventCommand(
                    matchId: matchId,
                    eventId: correction.eventId,
                    type: correction.type,
                    side: correction.side,
                    points: correction.points,
                    outcome: correction.outcome,
                    note: correction.note,
                    customLabel: correction.customLabel,
                    matchClockPositionSeconds:
                        correction.matchClockPositionSeconds,
                    reason: correction.reason,
                  ),
                );
                if (_isCurrent(generation, matchId)) {
                  controller.replaceData(replayDataFromDetail(projection));
                }
              } on Object {
                await refresh();
                rethrow;
              }
            }
          : null,
      onUndoEvent: replayEditable
          ? (eventId, reason) async {
              try {
                final projection = await commandService.undo(
                  UndoMatchEventCommand(
                    matchId: matchId,
                    eventId: eventId,
                    reason: reason,
                  ),
                );
                if (_isCurrent(generation, matchId)) {
                  controller.replaceData(replayDataFromDetail(projection));
                }
              } on Object {
                await refresh();
                rethrow;
              }
            }
          : null,
      onRestoreEvent: replayEditable
          ? (eventId, reason) async {
              try {
                final projection = await commandService.restore(
                  RestoreMatchEventCommand(
                    matchId: matchId,
                    eventId: eventId,
                    reason: reason,
                  ),
                );
                if (_isCurrent(generation, matchId)) {
                  controller.replaceData(replayDataFromDetail(projection));
                }
              } on Object {
                await refresh();
                rethrow;
              }
            }
          : null,
      onCorrectShotLocation: replayEditable
          ? (eventId, point, reason) async {
              try {
                final projection = await commandService.correctShotLocation(
                  CorrectShotLocationCommand(
                    matchId: matchId,
                    eventId: eventId,
                    point: point,
                    reason: reason,
                  ),
                );
                if (_isCurrent(generation, matchId)) {
                  controller.replaceData(replayDataFromDetail(projection));
                }
              } on Object {
                await refresh();
                rethrow;
              }
            }
          : null,
      loadAuditLogs: () => repository.listAuditLogs(matchId),
    );
    if (!_isCurrent(generation, matchId)) {
      controller.dispose();
      return null;
    }
    return _controller = controller;
  }

  Future<void> _refreshController({
    required int generation,
    required String matchId,
  }) async {
    if (!_isCurrent(generation, matchId)) return;
    final repository = ref.read(matchRepositoryProvider);
    final refreshed = await repository.getMatchDetail(matchId);
    if (!_isCurrent(generation, matchId)) return;
    final controller = _controller;
    if (refreshed != null && controller != null) {
      _lifecycle = refreshed.match.lifecycle;
      controller.replaceData(replayDataFromDetail(refreshed));
      setState(() {});
    }
  }

  void _retryLoad() {
    _controller?.dispose();
    _controller = null;
    _lifecycle = null;
    final generation = ++_requestGeneration;
    final matchId = widget.matchId;
    setState(() {
      _future = _load(generation, matchId);
    });
  }

  @override
  void dispose() {
    _requestGeneration++;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return FutureBuilder<ReplayController?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _RouteMessage(
            title: l10n.routeReplayOpenError,
            message: l10n.routeReplayOpenErrorBody,
            onHome: () => context.go('/'),
            onRetry: _retryLoad,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const _RouteLoading();
        }
        final controller = snapshot.data;
        if (controller == null) {
          return _RouteMessage(
            title: l10n.routeReplayNotFound,
            message: l10n.routeReplayNotFoundBody,
            onHome: () => context.go('/'),
            onRetry: _retryLoad,
          );
        }
        // The replay detail is the settled source of truth for this route.
        // The active-match stream may still be loading during a cold-start
        // deep link, so valueOrNull would incorrectly make an active replay
        // read-only and send its exit back to Home.
        final active = _lifecycle == MatchLifecycle.active;
        final exitTooltip = active
            ? l10n.replayExitToScoringTooltip
            : GoRouter.of(context).canPop()
            ? l10n.replayExitToHistoryTooltip
            : l10n.historyHomeTooltip;
        final generation = _requestGeneration;
        final routeMatchId = widget.matchId;
        return ReplayPage(
          controller: controller,
          exitTooltip: exitTooltip,
          onExit: () {
            final router = GoRouter.of(context);
            if (active) {
              // An active replay is always an auxiliary view of the live
              // scoring route. Going there explicitly also handles a cold
              // start deep link, whose router stack may still contain Home.
              router.go('/scoring/$routeMatchId');
            } else if (router.canPop()) {
              router.pop();
            } else {
              router.go('/');
            }
          },
          onShareSummary: (bytes, matchId) => ref
              .read(exportCoordinatorProvider)
              .shareReplayImage(
                bytes,
                matchId: matchId,
                subject: l10n.exportReplaySubject,
              ),
          onFinishMatch: active
              ? (redScore, blueScore) async {
                  final router = GoRouter.of(context);
                  final commandService = ref.read(matchCommandServiceProvider);
                  final automaticBackup = ref.read(
                    automaticBackupServiceProvider,
                  );
                  try {
                    await commandService.finish(
                      FinishMatchCommand(
                        matchId: routeMatchId,
                        endedAt: DateTime.now().toUtc(),
                        confirmFinalScore: true,
                        expectedRedScore: redScore,
                        expectedBlueScore: blueScore,
                      ),
                    );
                  } on Object {
                    await _refreshController(
                      generation: generation,
                      matchId: routeMatchId,
                    );
                    rethrow;
                  }
                  unawaited(_runAutomaticBackup(automaticBackup));
                  if (!_isReplayRouteCurrent(
                    router,
                    generation,
                    routeMatchId,
                  )) {
                    return;
                  }
                  router.go('/matches/$routeMatchId/replay');
                  await _refreshController(
                    generation: generation,
                    matchId: routeMatchId,
                  );
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeActiveMatchTitle)),
      body: SafeArea(
        child: Center(
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
                  FilledButton(
                    onPressed: onContinue,
                    child: Text(l10n.routeContinueMatch),
                  ),
                  OutlinedButton(
                    key: homeAbandonKey,
                    onPressed: () => onAbandon(),
                    child: Text(l10n.routeAbandonMatch),
                  ),
                ],
              ),
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
  final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
  try {
    final activeState = ref.read(activeMatchProvider);
    if (!activeState.hasValue) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.routeActiveCheckLoading)));
      return;
    }
    final active = activeState.valueOrNull;
    if (active != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.routeStartMatchConflict)));
      return;
    }
    await ref
        .read(matchCommandServiceProvider)
        .start(buildStartMatchCommand(setup));
    if (context.mounted) context.go('/scoring/${setup.matchId}');
  } on PregameSetupValidationException catch (error) {
    if (context.mounted) {
      final message = error.result.errors
          .map((error) => localizedPregameValidationErrorText(error, l10n))
          .join('\n');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  } on MatchCommandFailure {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.actionFailedRetry)));
    }
  }
}

Future<void> _abandon(
  BuildContext context,
  WidgetRef ref,
  String matchId,
) async {
  final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
  try {
    await ref
        .read(matchCommandServiceProvider)
        .abandon(
          AbandonMatchCommand(
            matchId: matchId,
            endedAt: DateTime.now().toUtc(),
          ),
        );
  } on MatchCommandFailure {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.routeAbandonFailed)));
    }
  }
}

Future<void> _resumeScoring(
  BuildContext context,
  WidgetRef ref,
  String matchId,
) async {
  final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
  try {
    await ref
        .read(matchCommandServiceProvider)
        .resume(
          ResumeMatchCommand(
            matchId: matchId,
            occurredAt: DateTime.now().toUtc(),
          ),
        );
    await ref.read(scoringFeedbackServiceProvider).emitCommitted();
  } on MatchCommandFailure {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.routeResumeFailed)));
    }
  }
}

Future<void> _continueScoringDecision(WidgetRef ref, String matchId) async {
  await ref
      .read(matchCommandServiceProvider)
      .continueMatch(
        ContinueMatchCommand(
          matchId: matchId,
          occurredAt: DateTime.now().toUtc(),
        ),
      );
}

Future<void> _finishScoringDecision(
  BuildContext context,
  WidgetRef ref,
  String matchId,
  int redScore,
  int blueScore,
) async {
  final router = GoRouter.of(context);
  final commandService = ref.read(matchCommandServiceProvider);
  final automaticBackup = ref.read(automaticBackupServiceProvider);
  await commandService.finish(
    FinishMatchCommand(
      matchId: matchId,
      endedAt: DateTime.now().toUtc(),
      confirmFinalScore: true,
      expectedRedScore: redScore,
      expectedBlueScore: blueScore,
    ),
  );
  unawaited(_runAutomaticBackup(automaticBackup));
  if (!_isScoringRouteForMatch(router, matchId)) return;
  router.go('/matches/$matchId/replay');
}

bool _isScoringRouteForMatch(GoRouter router, String matchId) {
  final segments = router.routeInformationProvider.value.uri.pathSegments;
  return segments.length == 2 &&
      segments[0] == 'scoring' &&
      segments[1] == matchId;
}

Future<void> _runAutomaticBackup(AutomaticBackupService service) async {
  try {
    await service.runAfterMatchFinish();
  } on Object {
    // Backup failure must not undo a committed match finish.
  }
}

Future<void> _leaveScoring(
  BuildContext context,
  WidgetRef ref,
  String matchId,
) async {
  final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
  final projection = ref
      .read(leaveScoringProjectionProvider(matchId))
      .valueOrNull;
  if (projection != null &&
      projection.match.lifecycle.name == 'active' &&
      !projection.match.timerEnabled) {
    if (context.mounted) context.go('/');
    return;
  }
  final action = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.routeLeaveTitle),
      content: Text(l10n.routeLeaveBody),
      actions: [
        TextButton(
          key: const Key('leave-stay'),
          onPressed: () => Navigator.of(dialogContext).pop('stay'),
          child: Text(l10n.routeLeaveStay),
        ),
        TextButton(
          key: const Key('leave-keep-running'),
          onPressed: () => Navigator.of(dialogContext).pop('keep'),
          child: Text(l10n.routeLeaveKeepRunning),
        ),
        FilledButton(
          key: const Key('leave-pause-and-leave'),
          onPressed: () => Navigator.of(dialogContext).pop('pause'),
          child: Text(l10n.routeLeavePauseAndLeave),
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
        ..showSnackBar(SnackBar(content: Text(l10n.routeClockCheckError)));
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
  } on MatchCommandFailure {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.actionFailedRetry)));
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
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: l10n.routeLoading,
            liveRegion: true,
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _RouteMessage extends StatelessWidget {
  const _RouteMessage({
    required this.title,
    required this.message,
    this.onHome,
    this.onReplay,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onHome;
  final VoidCallback? onReplay;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsZh();
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                if (onReplay != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    key: const Key('route-message-replay'),
                    onPressed: onReplay,
                    child: Text(l10n.replayTitle),
                  ),
                ],
                if (onRetry != null) ...[
                  const SizedBox(height: 20),
                  OutlinedButton(
                    key: const Key('route-message-retry'),
                    onPressed: onRetry,
                    child: Text(l10n.retryAction),
                  ),
                ],
                if (onHome != null) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('route-message-home'),
                    onPressed: onHome,
                    child: Text(l10n.historyHomeTooltip),
                  ),
                ],
              ],
            ),
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
