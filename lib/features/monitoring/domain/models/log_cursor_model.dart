/// Where the next page of the server's logs starts: just after the row with
/// this time and id, in the order `log_query` pages by (newest first, then
/// id).
final class LogCursor {
  const LogCursor({required this.occurredAt, required this.id});

  final DateTime occurredAt;
  final String id;

  @override
  bool operator ==(Object other) =>
      other is LogCursor && other.occurredAt == occurredAt && other.id == id;

  @override
  int get hashCode => Object.hash(occurredAt, id);
}
