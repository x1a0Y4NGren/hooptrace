/// The one resumable match claimed by the live scoring workspace.
class ActiveSession {
  const ActiveSession({
    required this.id,
    required this.matchId,
    this.claimedAtUtc,
  });

  final String id;
  final String matchId;
  final DateTime? claimedAtUtc;
}
