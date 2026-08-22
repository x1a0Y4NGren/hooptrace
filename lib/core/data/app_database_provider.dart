import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

AppDatabase createAppDatabase(QueryExecutor executor) {
  return AppDatabase(executor);
}

AppDatabase openAppDatabase() {
  return AppDatabase(driftDatabase(name: 'hooptrace'));
}

/// Opens the documented native file after a raw `user_version` probe. The
/// probe runs in NativeDatabase setup, before Drift can inspect or migrate it.
Future<AppDatabase> openNativeAppDatabase() async {
  final documents = await getApplicationDocumentsDirectory();
  final file = File(path.join(documents.path, 'hooptrace.sqlite'));
  final executor = NativeDatabase(
    file,
    setup: (raw) {
      final result = raw.select('PRAGMA user_version');
      final version = result.single.values.first as int;
      if (version == firstReleaseSchemaVersion) {
        throw LegacySchemaDetectedException(version);
      }
    },
  );
  final database = AppDatabase(executor);
  await database.customSelect('PRAGMA user_version').getSingle();
  return database;
}
