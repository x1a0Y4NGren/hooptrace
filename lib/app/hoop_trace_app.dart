import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/app_router.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/match_session_coordinator.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/app_database_provider.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';

class HoopTraceApp extends StatefulWidget {
  const HoopTraceApp({this.database, super.key});

  final AppDatabase? database;

  @override
  State<HoopTraceApp> createState() => _HoopTraceAppState();
}

class _HoopTraceAppState extends State<HoopTraceApp> {
  late final AppDatabase _database;
  late final GoRouter _router;
  late final MatchSessionCoordinator _matchSessions;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();
    _ownsDatabase = widget.database == null;
    _database = widget.database ?? openAppDatabase();
    _matchSessions = MatchSessionCoordinator(MatchRepository(_database));
    _router = buildAppRouter(_matchSessions);
  }

  @override
  void dispose() {
    _router.dispose();
    _matchSessions.dispose();
    if (_ownsDatabase) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HoopTrace',
      theme: buildHoopTraceTheme(),
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
