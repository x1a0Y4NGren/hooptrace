# Task 6 report — replay and history playbook redesign

## Delivered

- Made the replay court the visual focus with a 5:4 wide split (roughly 56% court / 44% timeline), while preserving the court-first portrait flow and bounded outer scrolling.
- Added a paper-styled, independently scrollable timeline surface with stable `replay-timeline-scroll` reachability.
- Timeline taps now call `ReplayController.selectEvent` in read-only review as well as edit mode. Selection is keyed by event/location identity, exposes selected semantics, and renders an optional orange court highlight without changing scoring data.
- Kept edit-mode gating, correction sheets, location editing, filters, analytics, audit, restore, finish, navigation, and existing replay keys intact.
- Restyled history results as reusable Doodle paper cards. Recovery/import/error banners remain outside the filtered result list; paging, deduplication, ordering, search, filters, confirmations, and `history-match-*` / `history-actions-*` boundaries remain unchanged.
- Added focused TDD coverage for stable replay selection/highlight semantics, wide split/timeline reachability, and history paper/action boundaries.

## Verification

- `flutter test test/features/replay test/features/history test/features/scoring/court_view_test.dart --reporter expanded` — passed (67 tests).
- `flutter test --reporter expanded` — passed (702 tests). Existing Drift multiple-database warning remains in the pre-existing backup merge fixture; no test failed.
- `flutter analyze` — exit 0; production code clean. Existing analyzer info/warnings are confined to unrelated pre-existing tests.
- `dart format` on all changed Dart files — passed.
- `git diff --check` — passed.

No routes, ARB/generated localization, provider router, settings, or auxiliary-page files were changed.
