import 'package:memox/features/card/domain/models/card_draft_model.dart';

/// One deck of a sectioned import (spec 2026-10-08 §4.5).
final class CardImportSection {
  const CardImportSection({
    required this.name,
    required this.existingDeckId,
    required this.drafts,
  });

  /// The name of the sub-deck made for it; unused when [existingDeckId] is
  /// set.
  final String name;

  /// "Add to existing": a live direct sub-deck of the target that takes
  /// cards. Null: a new sub-deck, made only when a draft is kept.
  final String? existingDeckId;
  final List<CardDraft> drafts;
}

/// What one section wrote.
final class CardImportSectionResult {
  const CardImportSectionResult({
    required this.deckId,
    required this.written,
    required this.skippedIndexes,
  });

  /// Null when nothing was written and no deck was made.
  final String? deckId;
  final int written;

  /// The places, in the section's drafts, the commit's re-check dropped
  /// (BR-TRANSFER-003).
  final List<int> skippedIndexes;
}
