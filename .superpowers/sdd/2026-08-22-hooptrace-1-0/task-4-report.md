# Task 4 report — transactional match command kernel

## Scope

Implemented a Drift-backed `MatchCommandService` for `start`, `record`,
`correct`, `undo`, `pause`, `resume`, `finish`, and `abandon`. Every public
method runs its writes in one awaited Drift transaction and then re-reads a
`MatchDetail` projection after the transaction commits. No UI state is
published from inside a transaction.

The service reuses `audit_logs` as a durable command-receipt ledger rather
than adding a schema-v2 table. Receipt rows use `action = command`, contain a
SHA-256 payload fingerprint, and are hidden from normal audit-log rendering.
Record, correction, and undo also write their business audit rows in the same
transaction as the event mutation and receipt.

## TDD RED evidence

The behavior test was written before the service existed:

```text
flutter test test/core/data/match_command_service_test.dart --reporter expanded
Error when reading 'lib/core/data/commands/match_command_service.dart':
系统找不到指定的路径。
Type 'StartMatchCommand' not found.
Method not found: 'MatchCommandService'.
...
Compilation failed for testPath=.../test/core/data/match_command_service_test.dart
```

After the first GREEN slice, a detailed-shot projection test was added before
changing the reducer. Its expected RED was:

```text
record projection counts made field goals and free throws but not misses
Expected: <2>
  Actual: <0>
test/core/data/match_command_service_test.dart:165:7
```

The reducer was then minimally extended to count made `fieldGoal` and
`freeThrow` events while ignoring misses.

## Design and idempotency keys

- `StartMatchCommand` generates command, match, participant, and clock UUIDs
  before entering the transaction.
- `RecordMatchEventCommand` generates command, event, optional location, and
  create-audit UUIDs before entering the transaction.
- Correction and undo generate command and audit UUIDs before entering the
  transaction; event `id` and `match_id` are never changed.
- Pause/resume generate command and semantic-event UUIDs. Finish/abandon use
  the command UUID as their durable receipt key.
- A command receipt is looked up by its primary key (`audit_logs.id`). Equal
  fingerprints return the post-commit projection without reapplying writes;
  different fingerprints raise `CommandConflictFailure` with the last
  committed projection. This remains valid after constructing a new service
  instance or restoring the persisted graph.
- `active_sessions(id = 'active')` is claimed and released in the same
  transaction as match lifecycle changes. SQLite's serialized writer plus the
  fixed primary key rejects simultaneous starts; the service maps the loser to
  `ActiveMatchConflictFailure`.
- `CommandTransactionFailure` carries `lastCommittedProjection`, the
  immutable command, `retryable`, and an explicit `retry()` closure. The test
  failure injector runs after writes and before transaction completion, proving
  rollback leaves no event or receipt behind.
- The old snapshot path is explicitly `@Deprecated` on
  `MatchRepository.replaceMatchSnapshot` and `MatchSessionCoordinator`; the
  new command kernel never calls it. `listAuditLogs` excludes internal
  command-receipt rows.

## Commits

- `06519c2 feat: add transactional match command kernel`
- `3e0cb05 fix: retire snapshot command fallback`
- `63d1398 fix: persist record command audit`
- `43d066f fix: score made shot events in projections`
- `840928d feat: expose command kernel compatibility aliases`
- `9114cba fix: validate shot location event types`

## Verification

```text
flutter test test/core/data/match_command_service_test.dart --reporter expanded
# 12 tests passed

flutter test --reporter expanded
# 153 tests passed, 0 failures

flutter analyze
# No issues found

dart run build_runner build --delete-conflicting-outputs
# Built; generated outputs unchanged

dart run drift_dev schema dump lib/core/data/app_database.dart drift_schemas/drift_schema_v2.json
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
# completed; generated schema/helper outputs unchanged

dart format --output=none --set-exit-if-changed lib test
# exit 0, 117 files checked, 0 changed

git diff --check
# clean

flutter build apk --debug
# Built build/app/outputs/flutter-apk/app-debug.apk

HOOPTRACE_ALLOW_UNSIGNED_RELEASE=true flutter build apk --release --no-shrink
# Built build/app/outputs/flutter-apk/app-release.apk

git status --short
# clean
```

## Concerns / self-review

- Receipt rows intentionally live in `audit_logs`; no schema, generated Drift
  helper, or eleven-table backup change was necessary. Existing backups retain
  and restore receipts, so duplicate commands remain provable after restore.
- Clock persistence is initialized by `start` and semantic pause/resume events
  are recorded, but elapsed-time reconstruction and end-condition algorithms
  remain Task 5 scope.
- Riverpod/UI composition and full retirement of the legacy controller remain
  Task 6 scope; the legacy bridge is marked deprecated and is not a fallback
  from the command service.
