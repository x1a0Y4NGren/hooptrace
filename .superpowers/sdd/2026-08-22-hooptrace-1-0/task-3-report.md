# Task 3 report — Domain model and Drift schema v2

## Milestones and commits

- `7e1fd4c test: define schema v2 domain contract` — contract/invariant tests first.
- `bee24c3 feat: establish schema v2 domain contract` — schema, domain records, generated Drift code, native bootstrap probe, and repository compatibility wiring.

## RED evidence

Initial command:

```text
flutter test test/core/data/schema_v2_test.dart --reporter expanded
```

Expected RED: compilation failed because `MatchParticipantsCompanion`, `MatchClocksCompanion`, `ActiveSessionsCompanion`, event `outcome`, possession `source`, and `LegacySchemaDetectedException` were absent from the v1 model. The test file was committed before production changes.

The follow-up ClockState/ActiveSession invariant slice also produced the expected RED for missing `clock_state.dart` and `active_session.dart` before those records were implemented.

## GREEN evidence

```text
flutter test test/core/data/schema_v2_test.dart test/core/data/match_repository_test.dart --reporter expanded
# 17 tests passed

flutter test --reporter expanded
# 126 tests passed

flutter analyze
# no errors (only existing style/info diagnostics)

git diff --check
# clean
```

## Files and contract coverage

- `lib/core/data/app_database.dart`: schema v2 tables, constraints, foreign keys with cascades, indexes, shot-location triggers, v1 incompatibility guard.
- `lib/core/data/app_database.g.dart`: regenerated Drift data classes and companions.
- `lib/core/data/app_database_provider.dart`: `openNativeAppDatabase()` using `getApplicationDocumentsDirectory()/hooptrace.sqlite` and raw `PRAGMA user_version` setup probe.
- `lib/core/data/schema_v2.dart`: public schema version/table export.
- `lib/core/domain/domain_enums.dart`: recording/lifecycle/clock/event/outcome/possession/restore/theme/tracking vocabularies.
- `lib/core/domain/entities/{match.dart,match_participant.dart,clock_state.dart,active_session.dart,match_event.dart,possession_segment.dart,rule_template.dart}`: participant snapshots, clock/session records, normalized event labels, outcome/clock position, soft deletion, possession source, and rule possession policy.
- `lib/core/data/repositories/match_repository.dart`: canonical participant persistence, event extensions, and rule snapshot policy persistence while retaining v0.1 fixture compatibility.
- `test/core/data/schema_v2_test.dart`: domain invariants, schema/table/index/FK integrity, participant/event cascade, shot-location cardinality and free-throw rejection, active-session singleton, and legacy schema guard.

## Concerns / self-review

- Existing v0.1 backup/repository fixtures construct generated `Matche` and possession rows directly. Generated data-class defaults were retained for these legacy constructors; rerunning build_runner will regenerate required constructor parameters, so the compatibility patch should be preserved or replaced with a source-level generator customization in a later maintenance pass.
- Legacy red/blue columns remain as deprecated compatibility columns; participant rows are the canonical 1.0 ownership projection. A later backup/merge task should export/import the new participant, clock, and active-session graph explicitly.
- `flutter analyze` reports only non-blocking style diagnostics in the schema/domain files; no analyzer errors remain.
