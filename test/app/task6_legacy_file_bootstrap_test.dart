import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooptrace/app/hoop_trace_app.dart';
import 'package:hooptrace/core/data/app_database_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  testWidgets('production LazyDatabase bootstrap preserves a real v1 file', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('hooptrace-task6-v1-'),
    ))!;
    addTearDown(() => directory.delete(recursive: true));
    final file = File(
      '${directory.path}${Platform.pathSeparator}hooptrace.sqlite',
    );
    final raw = sqlite3.sqlite3.open(file.path);
    raw.execute('PRAGMA user_version = 1');
    raw.execute('CREATE TABLE legacy_sentinel(value TEXT NOT NULL)');
    raw.execute("INSERT INTO legacy_sentinel(value) VALUES ('untouched')");
    raw.close();
    final database = openAppDatabaseAt(file);
    await tester.pumpWidget(HoopTraceApp(database: database));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('legacy-bootstrap')), findsOneWidget);
    expect(find.text('无法打开 HoopTrace v0.1 数据'), findsOneWidget);
    expect(find.textContaining('不会静默迁移、删除或清空'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(database.close);
    final verify = sqlite3.sqlite3.open(file.path);
    expect(verify.select('PRAGMA user_version').single.values.first, 1);
    expect(
      verify.select('SELECT value FROM legacy_sentinel').single.values.first,
      'untouched',
    );
    expect(
      verify
          .select(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name IN ('matches', 'match_events', 'active_sessions')",
          )
          .isEmpty,
      isTrue,
    );
    verify.close();
  });
}
