import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hooptrace/core/data/app_database.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

AppDatabase createAppDatabase(QueryExecutor executor) {
  return AppDatabase(executor);
}

AppDatabase openAppDatabase() {
  return AppDatabase(
    LazyDatabase(() async {
      final documents = await getApplicationDocumentsDirectory();
      return _nativeExecutor(
        File(path.join(documents.path, 'hooptrace.sqlite')),
      );
    }),
  );
}

/// Opens the documented native file after a raw `user_version` probe. The
/// probe runs in NativeDatabase setup, before Drift can inspect or migrate it.
Future<AppDatabase> openNativeAppDatabase() async {
  final documents = await getApplicationDocumentsDirectory();
  return openNativeAppDatabaseAt(
    File(path.join(documents.path, 'hooptrace.sqlite')),
  );
}

Future<AppDatabase> openNativeAppDatabaseAt(File file) async {
  final database = AppDatabase(_nativeExecutor(file));
  try {
    await database.customSelect('PRAGMA user_version').getSingle();
    return database;
  } on Object {
    await database.close();
    rethrow;
  }
}

NativeDatabase _nativeExecutor(File file) {
  return NativeDatabase(
    file,
    setup: (raw) {
      final result = raw.select('PRAGMA user_version');
      final version = result.single.values.first as int;
      if (version == firstReleaseSchemaVersion) {
        throw LegacySchemaDetectedException(version);
      }
    },
  );
}
