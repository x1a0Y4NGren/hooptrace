import 'package:hooptrace/core/domain/domain_enums.dart';

/// Persisted clock projection; display time is reconstructed from this state
/// and [runningSinceUtc], rather than writing once per tick.
class ClockState {
  ClockState({
    required this.id,
    required this.matchId,
    required this.mode,
    required this.phase,
    required this.accumulatedSeconds,
    this.runningSinceUtc,
    this.regulationSeconds,
  }) {
    if (accumulatedSeconds < 0) {
      throw ArgumentError.value(
        accumulatedSeconds,
        'accumulatedSeconds',
        'must not be negative',
      );
    }
    if (regulationSeconds != null && regulationSeconds! < 0) {
      throw ArgumentError.value(
        regulationSeconds,
        'regulationSeconds',
        'must not be negative',
      );
    }
  }

  final String id;
  final String matchId;
  final ClockMode mode;
  final ClockPhase phase;
  final int accumulatedSeconds;
  final DateTime? runningSinceUtc;
  final int? regulationSeconds;

  bool get isRunning => runningSinceUtc != null;

  int? get remainingSeconds {
    if (mode != ClockMode.countdown || regulationSeconds == null) return null;
    return (regulationSeconds! - accumulatedSeconds).clamp(
      0,
      regulationSeconds!,
    );
  }
}
