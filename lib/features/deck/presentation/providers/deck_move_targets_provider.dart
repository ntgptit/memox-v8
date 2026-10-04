import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/presentation/providers/watch_deck_move_targets_use_case_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'deck_move_targets_provider.g.dart';

/// The decks [deckId] may move under, each with its path (UC-DECK-005).
@riverpod
Stream<List<DeckMoveTarget>> deckMoveTargets(Ref ref, String deckId) =>
    ref.watch(watchDeckMoveTargetsUseCaseProvider)(deckId: deckId);
