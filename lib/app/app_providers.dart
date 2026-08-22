import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooptrace/app/app_metadata.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/data/app_database_provider.dart';
import 'package:hooptrace/core/data/commands/match_command_service.dart';
import 'package:hooptrace/core/data/repositories/match_repository.dart';
import 'package:hooptrace/core/data/repositories/player_repository.dart';
import 'package:hooptrace/core/data/repositories/rule_template_repository.dart';
import 'package:hooptrace/core/domain/entities/match_detail.dart';
import 'package:hooptrace/core/domain/entities/match_history_entry.dart';
import 'package:hooptrace/core/domain/entities/rule_template.dart';
import 'package:hooptrace/core/export/automatic_backup_service.dart';
import 'package:hooptrace/core/export/device_automatic_backup_storage.dart';
import 'package:hooptrace/core/export/device_export_gateway.dart';
import 'package:hooptrace/core/export/export_coordinator.dart';
import 'package:hooptrace/core/export/json_backup_codec.dart';
import 'package:hooptrace/features/scoring/scoring_controller.dart';
import 'package:hooptrace/features/settings/settings_controller.dart';

/// The result of the pre-Drift compatibility probe. A legacy result is
/// deliberately a value instead of an exception so the app can show a clear
/// recovery screen without deleting or mutating the user's file.
enum DatabaseBootstrapKind { ready, incompatibleLegacy }

class DatabaseBootstrapState {
  const DatabaseBootstrapState.ready()
    : kind = DatabaseBootstrapKind.ready,
      version = null;

  const DatabaseBootstrapState.incompatibleLegacy(this.version)
    : kind = DatabaseBootstrapKind.incompatibleLegacy;

  final DatabaseBootstrapKind kind;
  final int? version;

  bool get isReady => kind == DatabaseBootstrapKind.ready;
}

typedef DatabaseCompatibilityProbe =
    Future<void> Function(AppDatabase database);

/// The composition root owns the production database. Tests override this
/// provider with an already-created in-memory database; value overrides do
/// not run the production close callback.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = openAppDatabase();
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});

/// Kept separate from [appDatabaseProvider] so bootstrap tests can inject a
/// typed probe failure without opening or modifying a real user database.
final databaseCompatibilityProbeProvider = Provider<DatabaseCompatibilityProbe>(
  (ref) =>
      (database) => database.assertCompatible(),
);

final databaseBootstrapProvider = FutureProvider<DatabaseBootstrapState>((
  ref,
) async {
  final database = ref.watch(appDatabaseProvider);
  try {
    await ref.watch(databaseCompatibilityProbeProvider)(database);
    return const DatabaseBootstrapState.ready();
  } on LegacySchemaDetectedException catch (error) {
    return DatabaseBootstrapState.incompatibleLegacy(error.version);
  }
});

typedef AppStartupTask = Future<void> Function();

extension AsyncValueNullable<ValueT> on AsyncValue<ValueT> {
  ValueT? get valueOrNull => value;
}

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepository(ref.watch(appDatabaseProvider)),
);

final playerRepositoryProvider = Provider<PlayerRepository>(
  (ref) => PlayerRepository(ref.watch(appDatabaseProvider)),
);

final ruleTemplateRepositoryProvider = Provider<RuleTemplateRepository>(
  (ref) => RuleTemplateRepository(ref.watch(appDatabaseProvider)),
);

final ruleTemplatesProvider = StreamProvider<List<RuleTemplate>>((ref) {
  final repository = ref.watch(ruleTemplateRepositoryProvider);
  return repository.watchAll();
});

final clockEngineProvider = Provider<ClockEngine>((ref) => const ClockEngine());

final matchCommandServiceProvider = Provider<MatchCommandService>(
  (ref) => MatchCommandService(ref.watch(appDatabaseProvider)),
);

final backupCodecProvider = Provider<JsonBackupCodec>(
  (ref) => JsonBackupCodec(
    ref.watch(appDatabaseProvider),
    appVersion: hoopTraceAppVersion,
  ),
);

final backupStorageProvider = Provider<DeviceAutomaticBackupStorage>(
  (ref) => DeviceAutomaticBackupStorage(),
);

final automaticBackupServiceProvider = Provider<AutomaticBackupService>((ref) {
  return AutomaticBackupService(
    ref.watch(appDatabaseProvider),
    ref.watch(backupCodecProvider),
    storage: ref.watch(backupStorageProvider),
  );
});

/// Startup tasks are function providers instead of hard-coded calls so a
/// provider container can verify ordering/counts without touching a user's
/// backup directory. The production functions still delegate to the real
/// repository/service instances owned by this composition root.
final startupEnsureBuiltInsProvider = Provider<AppStartupTask>((ref) {
  final repository = ref.watch(ruleTemplateRepositoryProvider);
  return repository.ensureBuiltIns;
});

final startupAutomaticBackupProvider = Provider<AppStartupTask>((ref) {
  final automaticBackup = ref.watch(automaticBackupServiceProvider);
  return () async {
    await automaticBackup.runIfEnabled();
  };
});

/// Compatibility errors remain visible to the bootstrap screen. Only the
/// optional automatic backup task is best-effort: a moved/unavailable backup
/// directory must not prevent the local app from opening.
final databaseStartupProvider = FutureProvider<DatabaseBootstrapState>((
  ref,
) async {
  final bootstrap = await ref.watch(databaseBootstrapProvider.future);
  if (!bootstrap.isReady) return bootstrap;

  await ref.watch(startupEnsureBuiltInsProvider)();
  try {
    await ref.watch(startupAutomaticBackupProvider)();
  } on Object {
    // Automatic backup is an auxiliary startup task. Its next explicit or
    // scheduled run can retry after the directory is repaired.
  }
  return bootstrap;
});

final exportGatewayProvider = Provider<ExportGateway>((ref) {
  return DeviceExportGateway(backupStorage: ref.watch(backupStorageProvider));
});

final exportCoordinatorProvider = Provider<ExportCoordinator>((ref) {
  return ExportCoordinator(
    ref.watch(appDatabaseProvider),
    ref.watch(backupCodecProvider),
    gateway: ref.watch(exportGatewayProvider),
    automaticBackup: ref.watch(automaticBackupServiceProvider),
  );
});

/// The query tracks active_sessions, matches, participants, events, locations
/// and clocks. It is the only source of truth for resume cards and active
/// match gating after a process restart.
final activeMatchProvider = StreamProvider<MatchDetail?>((ref) {
  return ref.watch(matchRepositoryProvider).watchActiveMatch();
});

final historyProvider = StreamProvider<List<MatchHistoryEntry>>((ref) {
  return ref.watch(matchRepositoryProvider).watchHistory();
});

final liveMatchProvider = StreamProvider.autoDispose
    .family<MatchDetail?, String>((ref, matchId) {
      return ref.watch(matchRepositoryProvider).watchLiveMatch(matchId);
    });

/// A command-backed controller is reconstructed from the latest committed
/// projection. Subsequent Drift updates are applied to the same short-lived
/// controller, preserving a pending location only until its command commits.
final scoringControllerProvider = Provider.autoDispose
    .family<ScoringController?, String>((ref, matchId) {
      // Do not watch the live projection here. Watching it would invalidate
      // this provider on every committed score/location/clock write and
      // silently throw away controller-local interaction state (for example
      // a pending shot location). The live stream is listened to below and
      // only the first projection/terminal lifecycle transition invalidates
      // this provider.
      final initial = ref.read(liveMatchProvider(matchId)).valueOrNull;
      ScoringController? controller;
      if (initial != null && initial.match.lifecycle.name == 'active') {
        controller = ScoringController.fromCommittedProjection(
          initial,
          ref.read(matchCommandServiceProvider),
        );
      }
      ref.listen<AsyncValue<MatchDetail?>>(liveMatchProvider(matchId), (
        _,
        next,
      ) {
        final projection = next.valueOrNull;
        final isActive = projection?.match.lifecycle.name == 'active';
        if (controller == null) {
          if (isActive) {
            // The provider may have been first read while the stream was
            // loading. Re-evaluate once the initial committed projection is
            // available, then keep that controller stable for later writes.
            ref.invalidateSelf();
          }
          return;
        }
        if (!isActive) {
          ref.invalidateSelf();
          return;
        }
        controller.replaceCommittedProjection(projection!);
      });
      ref.onDispose(() => controller?.dispose());
      return controller;
    });

/// Settings is recreated when the active projection changes, so restore
/// gating cannot remain stale after abandon/finish or after process restore.
final settingsControllerProvider = Provider.autoDispose<SettingsController>((
  ref,
) {
  final activeState = ref.watch(activeMatchProvider);
  final canRestore = canRestoreBackupFor(activeState);
  final controller = SettingsController(
    exports: ref.watch(exportCoordinatorProvider),
    automaticBackup: ref.watch(automaticBackupServiceProvider),
    canRestoreBackup: canRestore,
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Restore is safe only after the active-match query has settled successfully
/// to a genuine null. Riverpod may retain a previous value while refreshing,
/// so loading/error flags must be checked before inspecting [valueOrNull].
bool canRestoreBackupFor(AsyncValue<MatchDetail?> activeState) {
  return !activeState.isLoading &&
      !activeState.hasError &&
      activeState.hasValue &&
      activeState.valueOrNull == null;
}
