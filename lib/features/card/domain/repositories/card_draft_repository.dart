import 'package:memox/features/card/domain/models/card_draft_model.dart';

/// The card being written, kept on this device (SP2a R9): never synced and
/// never logged. The one implementation is `CardDraftRepositoryImpl`; the
/// contract lets the presentation layer stay off `data/` and tests fail a
/// write on purpose.
abstract interface class CardDraftRepository {
  /// The draft kept under [key], or null when there is none.
  Future<CardDraft?> read(String key);

  /// Keeps [draft] under [key], replacing any earlier draft of that key.
  Future<void> save(String key, CardDraft draft);

  /// Drops the draft under [key]; dropping a missing one changes nothing.
  Future<void> clear(String key);
}
