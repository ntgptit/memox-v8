import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';

/// R3 (UI hardening SP2a 2.01): before a Learn or a Review, the deck whose
/// open session the start would end, so the person is asked first. Null when
/// none. It writes nothing.
final class FindOtherDeckSessionUseCase {
  const FindOtherDeckSessionUseCase(this._entries);

  final StudyEntryRepository _entries;

  Future<String?> call({required String deckId}) =>
      _entries.otherDeckSessionName(deckId: deckId);
}
