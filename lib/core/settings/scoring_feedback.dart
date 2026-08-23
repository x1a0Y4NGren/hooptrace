import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hooptrace/core/data/app_database.dart';

/// The single AppSettings row used by live scoring feedback preferences.
///
/// The version is part of the value rather than the database schema so a
/// future preference shape can safely fall back without making old databases
/// incompatible.
const scoringFeedbackPreferencesKey = 'scoring.feedback.v1';
const _scoringFeedbackPreferencesVersion = 1;

class ScoringFeedbackPreferences {
  const ScoringFeedbackPreferences({required this.haptic, required this.sound});

  const ScoringFeedbackPreferences.defaults() : haptic = true, sound = false;

  final bool haptic;
  final bool sound;

  bool get hapticEnabled => haptic;
  bool get soundEnabled => sound;

  ScoringFeedbackPreferences copyWith({bool? haptic, bool? sound}) {
    return ScoringFeedbackPreferences(
      haptic: haptic ?? this.haptic,
      sound: sound ?? this.sound,
    );
  }

  Map<String, Object> toJson() => {
    'version': _scoringFeedbackPreferencesVersion,
    'haptic': haptic,
    'sound': sound,
  };

  @override
  bool operator ==(Object other) {
    return other is ScoringFeedbackPreferences &&
        other.haptic == haptic &&
        other.sound == sound;
  }

  @override
  int get hashCode => Object.hash(haptic, sound);
}

/// Persists and caches the settings used by scoring feedback.
///
/// Reads are lazy and concurrent reads share one future. Writes are serialized
/// so two settings toggles cannot overwrite one another with a stale snapshot.
class ScoringFeedbackPreferencesRepository {
  ScoringFeedbackPreferencesRepository(
    this.database, {
    DateTime Function()? now,
    Future<ScoringFeedbackPreferences> Function()? read,
  }) : now = now ?? DateTime.now,
       _readOverride = read;

  final AppDatabase database;
  final DateTime Function() now;
  final Future<ScoringFeedbackPreferences> Function()? _readOverride;

  ScoringFeedbackPreferences? _cached;
  Future<ScoringFeedbackPreferences>? _loading;
  int _generation = 0;
  int? _loadingGeneration;
  Future<void> _writes = Future<void>.value();

  Future<ScoringFeedbackPreferences> load() {
    final cached = _cached;
    if (cached != null) return Future<ScoringFeedbackPreferences>.value(cached);
    final loading = _loading;
    if (loading != null && _loadingGeneration == _generation) return loading;
    final requestGeneration = _generation;

    late final Future<ScoringFeedbackPreferences> future;
    future = _read()
        .then((value) {
          if (requestGeneration == _generation) _cached = value;
          return value;
        })
        .whenComplete(() {
          if (identical(_loading, future) &&
              _loadingGeneration == requestGeneration) {
            _loading = null;
            _loadingGeneration = null;
          }
        });
    _loading = future;
    _loadingGeneration = requestGeneration;
    return future;
  }

  Future<ScoringFeedbackPreferences> update({bool? haptic, bool? sound}) {
    late final Future<ScoringFeedbackPreferences> operation;
    operation = _writes.then((_) async {
      final current = await load();
      final next = current.copyWith(haptic: haptic, sound: sound);
      await database
          .into(database.appSettings)
          .insertOnConflictUpdate(
            AppSetting(
              key: scoringFeedbackPreferencesKey,
              valueJson: jsonEncode(next.toJson()),
              updatedAt: now().toUtc(),
            ),
          );
      _cached = next;
      return next;
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return operation;
  }

  /// Drops only the in-memory value. The next [load] reads the AppSettings
  /// row again (for example after a backup restore).
  void invalidate() {
    _generation++;
    _cached = null;
  }

  Future<ScoringFeedbackPreferences> _read() async {
    final override = _readOverride;
    if (override != null) return override();
    final row =
        await (database.select(database.appSettings)..where(
              (setting) => setting.key.equals(scoringFeedbackPreferencesKey),
            ))
            .getSingleOrNull();
    if (row == null) return const ScoringFeedbackPreferences.defaults();
    try {
      final decoded = jsonDecode(row.valueJson);
      if (decoded is! Map ||
          decoded['version'] != _scoringFeedbackPreferencesVersion) {
        return const ScoringFeedbackPreferences.defaults();
      }
      final defaults = const ScoringFeedbackPreferences.defaults();
      return ScoringFeedbackPreferences(
        haptic: decoded['haptic'] is bool
            ? decoded['haptic'] as bool
            : defaults.haptic,
        sound: decoded['sound'] is bool
            ? decoded['sound'] as bool
            : defaults.sound,
      );
    } on Object {
      return const ScoringFeedbackPreferences.defaults();
    }
  }
}

abstract interface class ScoringFeedbackPlatform {
  Future<void> lightImpact();

  Future<void> click();
}

class FlutterScoringFeedbackPlatform implements ScoringFeedbackPlatform {
  const FlutterScoringFeedbackPlatform();

  @override
  Future<void> lightImpact() => HapticFeedback.lightImpact();

  @override
  Future<void> click() => SystemSound.play(SystemSoundType.click);
}

/// Applies feedback after a committed scoring command. Platform channels are
/// deliberately isolated here: a missing haptic/sound implementation can
/// never turn a successful database command into a retryable UI failure.
class ScoringFeedbackService {
  ScoringFeedbackService(this.preferences, {ScoringFeedbackPlatform? platform})
    : platform = platform ?? const FlutterScoringFeedbackPlatform();

  final ScoringFeedbackPreferencesRepository preferences;
  final ScoringFeedbackPlatform platform;

  Future<ScoringFeedbackPreferences> load() => preferences.load();

  Future<ScoringFeedbackPreferences> setHapticEnabled(bool enabled) {
    return preferences.update(haptic: enabled);
  }

  Future<ScoringFeedbackPreferences> setSoundEnabled(bool enabled) {
    return preferences.update(sound: enabled);
  }

  Future<ScoringFeedbackPreferences> update({bool? haptic, bool? sound}) {
    return preferences.update(haptic: haptic, sound: sound);
  }

  Future<ScoringFeedbackPreferences> reload() {
    preferences.invalidate();
    return preferences.load();
  }

  Future<void> emitCommitted() async {
    final settings = await _loadBestEffort();
    if (settings == null) return;
    if (settings.haptic) await _runBestEffort(platform.lightImpact);
    if (settings.sound) await _runBestEffort(platform.click);
  }

  Future<ScoringFeedbackPreferences?> _loadBestEffort() async {
    try {
      return await preferences.load();
    } on Object {
      return null;
    }
  }

  Future<void> _runBestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on Object {
      // Feedback is auxiliary and must not alter the command result.
    }
  }
}
