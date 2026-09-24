import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/presentation/providers/add_tag_to_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/delete_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/move_cards_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/select_all_card_ids_use_case_provider.dart';
import 'package:memox/features/card/presentation/providers/set_cards_flagged_use_case_provider.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'card_actions_controller.g.dart';

/// The card list's bulk commands (UC-CARD-001 A5–A8).
///
/// Each command calls exactly one use case (AD-12) and hands back its result;
/// the widget chooses the feedback. A database `Failure` is thrown through.
@riverpod
class CardActionsController extends _$CardActionsController {
  @override
  void build() {}

  /// Every card [query] lets through, not only the loaded rows (BR-CARD-012).
  Future<Set<String>> selectAll({
    required String deckId,
    required CardListQuery query,
  }) => ref.read(selectAllCardIdsUseCaseProvider)(deckId: deckId, query: query);

  Future<Outcome<void, CardRejection>> setFlagged({
    required Set<String> cardIds,
    required bool isFlagged,
  }) => ref.read(setCardsFlaggedUseCaseProvider)(
    cardIds: cardIds,
    isFlagged: isFlagged,
  );

  Future<Outcome<void, TagRejection>> addTag({
    required Set<String> cardIds,
    required String tagName,
  }) => ref.read(addTagToCardsUseCaseProvider)(
    cardIds: cardIds,
    tagName: tagName,
  );

  Future<Outcome<void, CardRejection>> moveCards({
    required Set<String> cardIds,
    required String targetDeckId,
  }) => ref.read(moveCardsUseCaseProvider)(
    cardIds: cardIds,
    targetDeckId: targetDeckId,
  );

  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
  }) => ref.read(deleteCardsUseCaseProvider)(cardIds: cardIds);
}
