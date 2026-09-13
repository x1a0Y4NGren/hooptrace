# Repository Guidelines

## Project Structure & Module Organization

HoopTrace is an offline-first Flutter application. Composition, routing, themes, and localization live in `lib/app/`. Domain rules and Drift persistence live in `lib/core/`; user-facing modules are grouped by capability in `lib/features/` (`scoring/`, `replay/`, `pregame/`).

Tests mirror the production layout under `test/`; Android end-to-end flows live in `integration_test/`. Store bundled resources in `assets/`, release documentation in `docs/release/`, release automation in `tool/release/`, and pinned SQLite sources in `third_party/sqlite/`.

## Build, Test, and Development Commands

```powershell
flutter pub get                         # Resolve locked dependencies.
flutter run -d <device-id>              # Run the app locally.
dart format --output=none --set-exit-if-changed .
flutter analyze                         # Apply flutter_lints and project rules.
flutter test                            # Run unit, widget, database, and golden tests.
flutter test integration_test/main_loop_test.dart -d <android-device-id>
flutter build apk --debug               # Produce a local Android debug APK.
```

After changing Drift tables or queries, run `dart run build_runner build --delete-conflicting-outputs` and commit the generated `app_database.g.dart`. Update ARB files in `lib/app/l10n/` together and regenerate localization output.

## Coding Style & Naming Conventions

Use Dart's formatter and two-space indentation. The analyzer requires single quotes, trailing commas, no `print`, and final locals where possible. Name files `snake_case.dart`, classes and enums `UpperCamelCase`, and members `lowerCamelCase`. Reuse existing repositories, controllers, command queues, and transactions instead of bypassing architectural boundaries.

Scoring mutations must pass through `MatchCommandService` and the controller, preserving receipts, audit chronology, idempotency, and transactional undo. Presentation-only controls belong in page state and must never filter stored events, replay, or statistics.

## Testing Guidelines

Name tests `*_test.dart` and describe observable behavior. Use unit tests for domain rules, in-memory Drift tests for persistence and rollback, widget tests for interaction and responsive layouts, and integration tests for critical routes or plugins. UI changes should cover relevant Chinese/English, light/dark, compact, and large-text states. Update golden files only after visually inspecting the differences.

For court markers, test both pixels and behavior: made and missed shapes, hidden-marker hit testing, animation fallback, and undo projection. Keep all primary scoring targets at least 48dp.

## Commit & Pull Request Guidelines

Use short imperative commits, such as `fix: guard replay navigation` or `feat(scoring): add undo feedback`. Keep PRs focused and include user impact, compatibility/privacy effects, exact verification commands, screenshots for visual changes, and linked issues.

## Security & Offline Constraints

Never commit signing keys, `key.properties`, device databases, build output, or real player data. Core features must remain offline-capable; new network behavior requires privacy and architecture review.
