import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/watch_deck_progress_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_progress_provider.g.dart';

/// `/progress/:deckId` (UC-PROGRESS-002 at a deck's level): the deck's path
/// and its children, or [ProgressDeckMissing]; again on every write it can
/// see and at each local midnight.
@riverpod
Stream<DeckProgress> deckProgress(Ref ref, String deckId) =>
    ref.watch(watchDeckProgressUseCaseProvider)(deckId);
