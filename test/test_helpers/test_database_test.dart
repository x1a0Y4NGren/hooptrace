import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

void main() {
  test(
    'opens and closes independent databases without sharing executors',
    () async {
      Object? firstExecutor;
      await withTestDatabase((database) async {
        firstExecutor = database.executor;
        expect(await database.select(database.matches).get(), isEmpty);
      });

      Object? secondExecutor;
      await withTestDatabase((database) async {
        secondExecutor = database.executor;
        expect(await database.select(database.matches).get(), isEmpty);
      });

      expect(secondExecutor, isNot(same(firstExecutor)));
    },
  );
}
