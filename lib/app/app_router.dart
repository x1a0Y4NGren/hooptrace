import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _HomePageShell(),
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
                onPressed: () {},
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
