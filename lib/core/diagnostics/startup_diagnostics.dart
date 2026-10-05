import 'dart:developer' as developer;

/// In-memory preparation spans for opt-in Profile startup diagnostics.
/// Normal builds do not read the clock, collect records, or emit output.
abstract final class StartupDiagnostics {
  static const enabled =
      bool.fromEnvironment('dart.vm.profile') &&
      bool.fromEnvironment('HOOPTRACE_ENTRY_PROFILE');

  static final _spans = <Map<String, Object>>[];

  static int? start() => enabled ? developer.Timeline.now : null;

  static void end(String stage, int? startedAt) {
    if (startedAt == null) return;
    final endedAt = developer.Timeline.now;
    _spans.add({
      'stage': stage,
      'started_at_us': startedAt,
      'ended_at_us': endedAt,
      'elapsed_us': endedAt - startedAt,
    });
  }

  static T measureSync<T>(String stage, T Function() action) {
    if (!enabled) return action();
    final startedAt = start();
    try {
      return action();
    } finally {
      end(stage, startedAt);
    }
  }

  static List<Map<String, Object>> takeSpans() {
    final result = List<Map<String, Object>>.of(_spans);
    _spans.clear();
    return result;
  }
}
