/// Stable, persisted vocabulary shared by the domain and Drift schema.
///
/// Values are intentionally serialized with [Enum.name]. Renaming one of
/// these values is a data-contract change and requires a new schema/backup
/// version.
enum RecordingMode { simple, detailed }

enum MatchLifecycle { draft, active, finished, archived, abandoned }

/// Compatibility alias for the pre-1.0 name. New code should use
/// [MatchLifecycle].
typedef MatchStatus = MatchLifecycle;

enum ClockMode { countUp, countdown }

enum ClockPhase { regulation, regulationExpired, overtime }

enum EventKind {
  /// Legacy score events remain readable while new writes use [fieldGoal].
  score,
  fieldGoal,
  freeThrow,
  miss,
  foul,
  reward,
  pause,
  interruption,
  note,
  custom,
  possession,
}

/// Compatibility alias for the pre-1.0 event enum.
typedef MatchEventType = EventKind;

enum ShotOutcome { made, missed, notApplicable }

enum PossessionPolicy { manual, switchAfterMade, keepAfterMade }

enum PossessionSource { manual, suggested }

enum RestoreMode { replace, merge }

enum ThemePreference { system, light, dark }

enum TrackingCoverage { none, scoresOnly, shotAttempts, locations, full }
