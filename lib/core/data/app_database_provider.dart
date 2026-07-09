import 'package:drift/drift.dart';
import 'package:hooptrace/core/data/app_database.dart';

AppDatabase createAppDatabase(QueryExecutor executor) {
  return AppDatabase(executor);
}
