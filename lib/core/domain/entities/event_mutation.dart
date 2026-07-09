enum EventMutationType { create, undo, edit, delete }

class EventMutation {
  const EventMutation({
    required this.type,
    required this.eventId,
    this.reason,
  });

  final EventMutationType type;
  final String eventId;
  final String? reason;
}
