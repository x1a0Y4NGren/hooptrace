import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () {},
                child: const Text('寮€濮嬭鍒?'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                child: const Text('澶嶇洏鍘嗗彶'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
