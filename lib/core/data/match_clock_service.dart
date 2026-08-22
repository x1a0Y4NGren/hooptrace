// Compatibility entry point for consumers that depend on a clock-focused
// data service. The command kernel owns clock mutations so they remain in
// the same transaction as semantic events and command receipts.
export 'commands/match_command_service.dart';
