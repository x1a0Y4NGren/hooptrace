import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:hooptrace/core/settings/scoring_feedback.dart';

import '../../test_helpers/test_database.dart';

void main() {
  test('defaults to haptic enabled and sound disabled', () async {
    final database = createTestDatabase();
    final repository = ScoringFeedbackPreferencesRepository(database);

    expect(
      await repository.load(),
      const ScoringFeedbackPreferences.defaults(),
    );
  });

  test('malformed and unknown preference payloads fall back safely', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 8, 23);
    await database
        .into(database.appSettings)
        .insert(
          AppSetting(
            key: scoringFeedbackPreferencesKey,
            valueJson: '{not-json',
            updatedAt: now,
          ),
        );
    final malformed = ScoringFeedbackPreferencesRepository(database);
    expect(await malformed.load(), const ScoringFeedbackPreferences.defaults());

    await database
        .into(database.appSettings)
        .insertOnConflictUpdate(
          AppSetting(
            key: scoringFeedbackPreferencesKey,
            valueJson: jsonEncode({
              'version': 99,
              'haptic': false,
              'sound': true,
            }),
            updatedAt: now,
          ),
        );
    final unknownVersion = ScoringFeedbackPreferencesRepository(database);
    expect(
      await unknownVersion.load(),
      const ScoringFeedbackPreferences.defaults(),
    );
  });

  test('round trips updates through AppSettings', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = ScoringFeedbackPreferencesRepository(database);

    final saved = await repository.update(haptic: false, sound: true);
    expect(saved.haptic, isFalse);
    expect(saved.sound, isTrue);

    final reloaded = ScoringFeedbackPreferencesRepository(database);
    expect(await reloaded.load(), saved);
  });

  test(
    'reload observes a restored AppSettings row after invalidation',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = ScoringFeedbackPreferencesRepository(database);
      await repository.update(haptic: false, sound: true);

      await database
          .into(database.appSettings)
          .insertOnConflictUpdate(
            AppSetting(
              key: scoringFeedbackPreferencesKey,
              valueJson: jsonEncode({
                'version': 1,
                'haptic': true,
                'sound': false,
              }),
              updatedAt: DateTime.utc(2026, 8, 23),
            ),
          );
      expect(
        await repository.load(),
        const ScoringFeedbackPreferences(haptic: false, sound: true),
      );
      repository.invalidate();
      expect(
        await repository.load(),
        const ScoringFeedbackPreferences(haptic: true, sound: false),
      );
    },
  );

  test('concurrent loads share one in-flight read', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = ScoringFeedbackPreferencesRepository(database);

    final values = await Future.wait([
      repository.load(),
      repository.load(),
      repository.load(),
    ]);

    expect(values, everyElement(const ScoringFeedbackPreferences.defaults()));
  });

  test('feedback platform failures are isolated per channel', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final platform = _FakePlatform()
      ..throwOnHaptic = true
      ..throwOnSound = true;
    final repository = ScoringFeedbackPreferencesRepository(database);
    await repository.update(haptic: true, sound: true);
    final service = ScoringFeedbackService(repository, platform: platform);

    await expectLater(service.emitCommitted(), completes);
    expect(platform.hapticCalls, 1);
    expect(platform.soundCalls, 1);
  });

  test(
    'committed feedback follows haptic-only, sound-only, and both settings',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = ScoringFeedbackPreferencesRepository(database);
      final platform = _FakePlatform();
      final service = ScoringFeedbackService(repository, platform: platform);

      await service.emitCommitted();
      expect(platform.hapticCalls, 1);
      expect(platform.soundCalls, 0);

      await service.update(haptic: false, sound: true);
      await service.emitCommitted();
      expect(platform.hapticCalls, 1);
      expect(platform.soundCalls, 1);

      await service.update(haptic: true, sound: true);
      await service.emitCommitted();
      expect(platform.hapticCalls, 2);
      expect(platform.soundCalls, 2);
    },
  );
}

class _FakePlatform implements ScoringFeedbackPlatform {
  bool throwOnHaptic = false;
  bool throwOnSound = false;
  int hapticCalls = 0;
  int soundCalls = 0;

  @override
  Future<void> lightImpact() async {
    hapticCalls++;
    if (throwOnHaptic) throw StateError('haptic unavailable');
  }

  @override
  Future<void> click() async {
    soundCalls++;
    if (throwOnSound) throw StateError('sound unavailable');
  }
}
