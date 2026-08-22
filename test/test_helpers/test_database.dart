import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/core/data/app_database.dart';

/// Creates an isolated in-memory database and registers its close operation
/// with the current test.
AppDatabase createTestDatabase() {
  final database = AppDatabase.inMemory();
  addTearDown(database.close);
  return database;
}

/// Runs [action] with an isolated in-memory database and always closes it.
Future<T> withTestDatabase<T>(
  Future<T> Function(AppDatabase database) action,
) async {
  final database = AppDatabase.inMemory();
  try {
    return await action(database);
  } finally {
    await database.close();
  }
}
