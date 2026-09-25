import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';

/// The Progress screen's reads (UC-PROGRESS-001, UC-PROGRESS-002). The one
/// implementation is `ProgressRepositoryImpl` (data layer); the contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class ProgressRepository {
  /// `/progress` (Progress spec §6): the overview and every root deck with
  /// the numbers of its tree for both ranges, read as one snapshot on the
  /// local days of [days]; again after every write to the history, the cards
  /// or the decks. It writes nothing (BR-PROGRESS-009).
  Stream<Progress> watchProgress(ProgressDays days);

  /// `/progress/:deckId`: [deckId]'s path and every direct child with the
  /// numbers of its subtree, for both ranges, as one snapshot on the local
  /// days of [days]; [ProgressDeckMissing] while [deckId] is not an active
  /// deck. Again after every write it can see; it writes nothing
  /// (BR-PROGRESS-007).
  Stream<DeckProgress> watchDeckProgress({
    required String deckId,
    required ProgressDays days,
  });
}
