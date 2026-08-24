import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

const _sqliteC = 'third_party/sqlite/sqlite3.c';
const _sqliteH = 'third_party/sqlite/sqlite3.h';
const _sqliteCHash =
    'b1dd5d74ec7f29055a6684fa06fb3c2f6821c87dd38f9a458dfd2e8a1db28189';
const _sqliteHHash =
    '919e7f2e8ed1d8f56ac17b412b8971c76aa5d1a879752cc6058f75e7d5910e1d';

Future<void> main() async {
  final pubspec = loadYaml(await File('pubspec.yaml').readAsString());
  if (pubspec is! YamlMap) throw StateError('pubspec.yaml is not a map.');
  final hooks = pubspec['hooks'];
  final userDefines = hooks is YamlMap ? hooks['user_defines'] : null;
  final sqlite = userDefines is YamlMap ? userDefines['sqlite3'] : null;
  if (sqlite is! YamlMap ||
      sqlite['source'] != 'source' ||
      sqlite['path'] != _sqliteC) {
    throw StateError(
      'pubspec.yaml must build sqlite3 from the pinned vendored source.',
    );
  }
  final lock = loadYaml(await File('pubspec.lock').readAsString());
  final packages = lock is YamlMap ? lock['packages'] : null;
  final lockedSqlite = packages is YamlMap ? packages['sqlite3'] : null;
  if (lockedSqlite is! YamlMap || lockedSqlite['version'] != '3.5.2') {
    throw StateError(
      'pubspec.lock must pin package:sqlite3 to the reviewed 3.5.2 release.',
    );
  }

  await _verifyHash(_sqliteC, _sqliteCHash);
  await _verifyHash(_sqliteH, _sqliteHHash);
  final source = await File(_sqliteC).readAsString();
  final header = await File(_sqliteH).readAsString();
  if (!source.contains('#define SQLITE_VERSION        "3.53.4"') ||
      !header.contains('#define SQLITE_VERSION        "3.53.4"') ||
      !source.contains('SQLITE_VERSION_NUMBER 3053004') ||
      !header.contains('SQLITE_VERSION_NUMBER 3053004')) {
    throw StateError(
      'sqlite3.c and sqlite3.h are not the pinned SQLite 3.53.4 source.',
    );
  }
  stdout.writeln('SQLite 3.53.4 source hook and C/H hashes verified.');
}

Future<void> _verifyHash(String path, String expected) async {
  final file = File(path);
  if (!file.existsSync() || file.lengthSync() == 0) {
    throw StateError('Missing vendored SQLite input: $path');
  }
  final actual = (await sha256.bind(file.openRead()).first).toString();
  if (actual != expected) {
    throw StateError('$path SHA-256 mismatch: $actual');
  }
}
