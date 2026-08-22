class AuditDiff {
  const AuditDiff({required this.before, required this.after});

  final Map<String, Object?> before;
  final Map<String, Object?> after;
}
