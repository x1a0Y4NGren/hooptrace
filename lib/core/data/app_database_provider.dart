import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:hooptrace/core/data/app_database.dart';

AppDatabase createAppDatabase(QueryExecutor executor) {
  return AppDatabase(executor);
}

AppDatabase openAppDatabase() {
  return AppDatabase(driftDatabase(name: 'hooptrace'));
}
