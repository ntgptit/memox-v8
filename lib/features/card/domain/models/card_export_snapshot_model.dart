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
  const CardExportSnapshot({required this.deckName, required this.rows});

  final String deckName;
  final List<CardExportRow> rows;
}
