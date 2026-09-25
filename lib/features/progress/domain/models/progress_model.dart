import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

/// `/progress` (UC-PROGRESS-001, and UC-PROGRESS-002 at the library level):
/// the overview and a row per root deck, read as one snapshot (Progress
/// spec §5.2).
final class Progress {
  const Progress({
    required this.overview,
    required this.level,
    required this.validUntil,
  });

  final ProgressOverview overview;
  final ProgressLevel level;

  /// The next local midnight: every number changes there with no write
  /// (BR-PROGRESS-003).
  final DateTime validUntil;
}

/// `/progress/:deckId` (UC-PROGRESS-002 at a deck's level).
sealed class DeckProgress {
  const DeckProgress();
}

/// A deck's level: its path, and a row per direct child with the numbers of
/// its subtree. A deck that holds cards has no row (UC-PROGRESS-002 A1); its
/// total still counts them.
final class DeckProgressLevel extends DeckProgress {
  const DeckProgressLevel({
    required this.path,
    required this.level,
    required this.validUntil,
  });

  /// The root first, the deck last.
  final List<ProgressPathSegment> path;

  final ProgressLevel level;

  /// The next local midnight (BR-PROGRESS-003).
  final DateTime validUntil;
}

/// The deck of a link is gone or in the Trash. Not an error: reading again
/// would find the same (UC-PROGRESS-002 E2).
final class ProgressDeckMissing extends DeckProgress {
  const ProgressDeckMissing();
}

/// A deck on the path from the root to the deck of a level.
final class ProgressPathSegment {
  const ProgressPathSegment({required this.deckId, required this.name});

  final String deckId;
  final String name;
}
