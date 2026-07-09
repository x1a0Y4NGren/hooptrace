import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/features/pregame/pregame_controller.dart';
import 'package:hooptrace/features/pregame/pregame_page.dart';
import 'package:hooptrace/features/scoring/scoring_page.dart';

GoRouter buildAppRouter() {
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
          return ScoringPage(
            matchId: state.pathParameters['matchId'],
            setup: setup,
          );
        },
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
                onPressed: () => context.go('/pregame'),
                child: Text(l10n.startScoring),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                child: Text(l10n.replayHistory),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
