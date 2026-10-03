/// One card as a transfer file carries it: its six content fields and
/// nothing else (BR-TRANSFER-008).
final class CardExportRow {
  const CardExportRow({
    required this.front,
    required this.back,
    this.example,
    this.hint,
    this.pronunciation,
    this.tagNames = const [],
  });

  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;

  /// Ordered by folded name, then id (BR-TRANSFER-010).
  final List<String> tagNames;
}

/// The deck's name and its cards, read in one transaction, ordered by
/// `created_at`, then `id` (BR-TRANSFER-010).
final class CardExportSnapshot {
  const CardExportSnapshot({
    required this.deckName,
    required this.rows,
    this.skipped = const {},
  });

  final String deckName;
  final List<CardExportRow> rows;

  /// The selected ids that were gone, in the Trash or in another deck when
  /// the snapshot was read (SP2a 2.19); empty for a whole-deck export.
  final Set<String> skipped;
}
