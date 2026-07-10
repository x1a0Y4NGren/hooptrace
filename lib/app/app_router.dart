import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/match_session_coordinator.dart';
import 'package:hooptrace/app/match_view_data_mapper.dart';
import 'package:hooptrace/app/orientation_shell.dart';
import 'package:hooptrace/features/history/history_controller.dart';
import 'package:hooptrace/features/history/history_page.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/replay/replay_controller.dart';
import 'package:hooptrace/features/replay/replay_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

GoRouter buildAppRouter(MatchSessionCoordinator matchSessions) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _HomePageShell(),
      ),
      GoRoute(
        path: '/pregame',
        builder: (context, state) {
          return PregamePage(
            onStartMatch: (setup) {
              context.go('/scoring/${setup.matchId}', extra: setup);
            },
          );
        },
      ),
      GoRoute(
        path: '/scoring/:matchId',
        builder: (context, state) {
          final setup =
              state.extra is MatchSetup ? state.extra! as MatchSetup : null;
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
        builder: (context, state) => _HistoryRoute(
          matchSessions: matchSessions,
        ),
      ),
      GoRoute(
        path: '/matches/:matchId/replay',
        builder: (context, state) => _ReplayRoute(
          matchSessions: matchSessions,
          matchId: state.pathParameters['matchId']!,
        ),
      ),
    ],
  );
}

class _HomePageShell extends StatelessWidget {
  const _HomePageShell();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
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
  final controller = setup == null
      ? matchSessions.controllerFor(matchId)
      : matchSessions.beginMatch(setup);
  if (controller == null) {
    return const _RouteMessage(
      title: '比赛未在进行中',
      message: '请从主页开始一场新比赛。',
    );
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
  });

  final MatchSessionCoordinator matchSessions;
  final String matchId;

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
    final detail =
        await widget.matchSessions.repository.getMatchDetail(widget.matchId);
    if (detail == null) {
      return null;
    }
    return _ownedController =
        ReplayController(data: replayDataFromDetail(detail));
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
          return const _RouteMessage(
            title: '没有找到这场比赛',
            message: '记录可能已被移除。',
          );
        }
        final active = widget.matchSessions.isActive(widget.matchId);
        return ReplayPage(
          controller: controller,
          onFinishMatch: active
              ? () async {
                  await widget.matchSessions.finishMatch(widget.matchId);
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
