import 'package:memox/core/error/bulk_outcome.dart';

/// What attaching one tag to several cards came to (UC-CARD-001 A8). A card
/// at the limit does not fail the call with a bare reason: the person is told
/// which cards, so the answer carries them.
sealed class TagAttach {
  const TagAttach();
}

/// The tag is on every card of [outcome].done; the ones already gone were
/// skipped (SP2a 2.19).
final class TagAttached extends TagAttach {
  const TagAttached(this.outcome);

  final BulkOutcome outcome;
}

/// BR-TAG-002: these cards already hold 10 tags and lack this one. Nothing
/// was written, for any card.
final class TagLimitReached extends TagAttach {
  const TagLimitReached(this.fullCardIds);

  final Set<String> fullCardIds;
}
