import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/trash/presentation/providers/watch_card_restore_targets_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/watch_deck_restore_targets_use_case_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_restore_targets_provider.g.dart';

/// The decks the cards of [batchIds] can go back into, live (BR-TRASH-006).
@riverpod
Stream<List<CardMoveTarget>> cardRestoreTargets(
  Ref ref,
  TrashBatchIds batchIds,
) => ref.watch(watchCardRestoreTargetsUseCaseProvider)(batchIds: batchIds.ids);

/// Where the decks of [batchIds] can go back to, live (BR-TRASH-006).
@riverpod
Stream<DeckRestoreTargets> deckRestoreTargets(
  Ref ref,
  TrashBatchIds batchIds,
) => ref.watch(watchDeckRestoreTargetsUseCaseProvider)(batchIds: batchIds.ids);
