/// What a purge did (BR-TRASH-010, UC-TRASH-001 E4 and E6).
final class PurgeReport {
  const PurgeReport({
    required this.purged,
    required this.blocked,
    required this.missing,
  });

  /// The batches deleted for good, and every row of theirs with them.
  final Set<String> purged;

  /// Each batch skipped whole, with the batches that still have rows inside
  /// its decks; an empty set means an active row, which invariants 33 and 34
  /// forbid.
  final Map<String, Set<String>> blocked;

  /// The chosen batches that no longer exist.
  final Set<String> missing;
}
