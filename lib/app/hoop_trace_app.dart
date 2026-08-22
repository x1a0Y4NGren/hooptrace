import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooptrace/app/app_metadata.dart';
import 'package:hooptrace/app/app_router.dart';
import 'package:hooptrace/app/app_theme.dart';
import 'package:hooptrace/app/l10n/app_localizations.dart';
import 'package:hooptrace/app/match_session_coordinator.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/app_database_provider.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/device_export_gateway.dart';
import 'package:hooptrace/core/export/device_automatic_backup_storage.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';

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
  late final RuleTemplateRepository _ruleTemplates;
  late final AutomaticBackupService _automaticBackup;
  late final ExportCoordinator _exports;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();
    _ownsDatabase = widget.database == null;
    _database = widget.database ?? openAppDatabase();
    final commandService = MatchCommandService(_database);
    _matchSessions = MatchSessionCoordinator(
      MatchRepository(_database),
      commandService: commandService,
    );
    _ruleTemplates = RuleTemplateRepository(_database);
    final backupCodec = JsonBackupCodec(
      _database,
      appVersion: hoopTraceAppVersion,
    );
    final backupStorage = DeviceAutomaticBackupStorage();
    _automaticBackup = AutomaticBackupService(
      _database,
      backupCodec,
      storage: backupStorage,
    );
    _exports = ExportCoordinator(
      _database,
      backupCodec,
      gateway: DeviceExportGateway(backupStorage: backupStorage),
      automaticBackup: _automaticBackup,
    );
    unawaited(_initializeLocalServices());
    _router = buildAppRouter(
      _matchSessions,
      PlayerRepository(_database),
      _ruleTemplates,
      _exports,
      _automaticBackup,
    );
  }

  Future<void> _initializeLocalServices() async {
    await _ruleTemplates.ensureBuiltIns();
    try {
      await _automaticBackup.runIfEnabled();
    } on Object {
      // A removed or unavailable user folder must not prevent app startup.
    }
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
