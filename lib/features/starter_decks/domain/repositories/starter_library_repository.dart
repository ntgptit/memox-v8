import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';

/// The Starter library (UC-STARTER-001). The one implementation is
/// `StarterLibraryRepositoryImpl`; the contract keeps `domain/`
/// framework-free and lets tests substitute a fake (ADR-010).
abstract interface class StarterLibraryRepository {
  /// UC-STARTER-001 steps 4-5: every bundled template, in manifest order,
  /// each with whether it is in the library; again after every write to the
  /// decks (spec §6, D12). A database error arrives as the stream's
  /// `Failure`.
  Stream<List<StarterLibraryEntry>> watchLibrary();

  /// UC-STARTER-001 step 8: the template [templateId] becomes a deck tree of
  /// the person's own under [schedulerType], in one transaction
  /// (BR-STARTER-003, BR-STARTER-009). A copy of it in the library refuses
  /// with `alreadyInLibrary` unless [allowSecondCopy] (BR-STARTER-007,
  /// BR-STARTER-008).
  Future<Outcome<AddedStarterDeck, StarterRejection>> addStarterDeck({
    required String templateId,
    required SchedulerType schedulerType,
    bool allowSecondCopy = false,
    DateTime? now,
  });
}
