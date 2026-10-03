# Repository Guidelines

## Scope and Completion

Complete the current request, relevant verification, and affected documentation. Reuse authorization already given for that task; ask only when an unresolved choice materially changes scope or consequences. Preserve unrelated user changes.

Read only relevant guidance: [CONTRIBUTING.md](CONTRIBUTING.md) for development, [HANDOFF.md](HANDOFF.md) for prior status, and the [release checklist](docs/release/release-checklist.md) when preparing a release. Historical plans and branch prompts are reference material, not current assignments or standing approval gates. Apply skills to the workflow they actually support; current user instructions take precedence over skill recommendations.

Check the current branch and HANDOFF before continuing: the main checkout and a candidate worktree can contain different application versions. Keep build and test evidence tied to its actual application source commit; later documentation commits do not change APK provenance.

## Project Structure

HoopTrace is an offline-first Flutter app. Routing, themes, and localization live in `lib/app/`; domain rules and Drift persistence in `lib/core/`; UI modules in `lib/features/`. Tests mirror production under `test/`; Android flows use `integration_test/`. Bundled assets live in `assets/`, release tooling in `tool/release/`, and pinned SQLite sources in `third_party/sqlite/`.

## Implementation Constraints

Use Dart formatting, two-space indentation, and `analysis_options.yaml`. Name files `snake_case.dart`, types `UpperCamelCase`, and members `lowerCamelCase`.

Scoring mutations go through the controller and `MatchCommandService`, preserving receipts, audit order, idempotency, transactions, and undo. Presentation-only filters must not alter stored events, replay, or statistics. Keep primary scoring targets at least 48dp.

For the 2.0 candidate, coverage changes use `FinishMatchCommand` or `SetTrackingCoverageCommand`; misses and locations never imply complete recording. Keep FG and FT denominators separate, and count location coverage as confirmed field-goal locations / recorded field-goal attempts. `MatchSetupPreset` reuses participants and rules only. Keep schema 3 and JSON format 2 unless the current task explicitly changes the compatibility contract.

Replacement and safety-copy rollback must protect the current data before mutation, retain the write reservation through backup and replacement, and block while a match is active. Preserve the shared import/export capacity limits and fail before reporting a successful backup or share.

For Drift schema/query changes, run `dart run build_runner build --delete-conflicting-outputs` and include generated changes. Update both ARB files and run `flutter gen-l10n` when changing localized text.

Keep core features offline-capable. Review privacy and architecture for new network behavior. Never commit signing keys, `key.properties`, device databases, build output, or real player data.

## Proportionate Verification

Use the validation matrix in CONTRIBUTING. Documentation-only edits need content/link checks and `git diff --check`, not Flutter builds. For Dart changes, format affected files, analyze, and run relevant `*_test.dart` tests. Broaden coverage for shared behavior, persistence, platform integration, or release work.

Test observable behavior and inspect changed goldens. Reuse successful checks while their relevant inputs and environment remain unchanged; rerun for new changes, failures, or concrete concerns. Android integration tests can overwrite `app-debug.apk`; rebuild before manual installation.

Run Android integration tests on a dedicated test device or isolated Android user (`--device-user <id>`): the runner can uninstall that user's app. File close/reopen tests do not establish process-restart recovery; use an actual file database and cold restart when that behavior is under verification.

## Collaboration and Delivery

Delegate independent, bounded work when useful. Create worktrees only when isolation is needed. Wait only for an actual dependency; use completion notifications or bounded waits instead of fixed sleeps and repeated unchanged polls.

Use short imperative commits, such as `fix: guard replay navigation`. Report the result, actual verification, and remaining blockers. Merging, pushing, and publishing follow authorization for the current task; historical release instructions do not grant it.
