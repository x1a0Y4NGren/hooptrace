import 'package:hooptrace/core/audit/audit_diff.dart';

enum AuditAction { create, undo, edit, delete, import, restore }

class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.matchId,
    required this.targetId,
    required this.action,
    required this.createdAt,
    required this.diff,
    this.reason,
  });

  final String id;
  final String matchId;
  final String targetId;
  final AuditAction action;
  final DateTime createdAt;
  final AuditDiff diff;
  final String? reason;
}
