# Task 4 report: unified scoring UI

## TDD evidence

- RED: after adding the focused regressions, the old page failed on the new
  `scoring-undo`/`scoring-more` surface, court-first draft, score-first
  supplement, and More/dialog assertions. The first run also correctly
  rejected the not-yet-added `CourtView.locationPrompt` API at compile time.
- GREEN: the six new scoring-page regressions pass individually:
  primary layout/More, court-first gray draft, score-first ten-second
  supplement, text-dialog lifecycle, responsive sizes, and reduced motion.
  `court_view_test.dart` passes 8/8, including the new prompt regression.
- `flutter analyze` on the four changed production scoring files reports no
  issues. `git diff --check` is clean.

## Implementation

- `scoring_page.dart`: one black scoreboard plus blue/court/red workspace;
  top-level Undo and More; grouped More modal; court-first and score-first
  interaction routing; 10-second countdown/pulse; reduced-motion static
  outline; responsive portrait fallback; state-owned text-entry dialog;
  finish confirmation and retry-preserving errors.
- `widgets/score_side_panel.dart`: primary +1/+2/+3/foul-only panel,
  location icon/countdown semantics, 48dp actions, and reduced-motion styling.
- `widgets/court_view.dart`: score-first prompt overlay/live semantics and
  direct tap attachment while retaining drag marker adjustment.
- `widgets/court_painter.dart`: unassigned court-first draft markers render
  gray until a team is selected.
- Tests added to `scoring_page_test.dart` and `court_view_test.dart`.

## Task 2 API consumption

The UI consumes `beginOrMoveCourtFirstShot`, `updateCourtFirstShot`,
`commitCourtFirstShot`, `locationSupplementWindow`,
`attachSupplementLocation`, `expireSupplementWindow`,
`recordScoreCommitted`, `recordMissCommitted`, `recordFreeThrowCommitted`,
`recordPossessionCommitted`, `recordNoteCommitted`,
`recordCustomCommitted`, `pauseCommitted`, `resumeCommitted`,
`undoLastScoringActionCommitted`, and `retryCommand` without changing
controller, command-service, repository, or router files.

## Test environment and risk

The SQLite hook was temporarily switched to `source: sqlite3` for Windows
focused tests/analyze, then restored exactly to `source: source` plus the
checked-in `third_party/sqlite/sqlite3.c` path; `pubspec.yaml` is not part of
the changes. The pre-existing page tests that assert the removed command dock,
pending-location dock, top-level replay button, or detailed draft dock are
expected to require follow-up assertions for the approved unified surface;
those tests were not deleted or weakened.
