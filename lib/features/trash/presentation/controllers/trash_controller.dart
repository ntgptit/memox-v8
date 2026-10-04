import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/purge_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/restore_cards_from_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/providers/restore_decks_from_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/states/trash_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_controller.g.dart';

/// Screen 06 (UC-TRASH-001): the filter, the selection locked to one kind
/// (BR-TRASH-011), and the commands, each through its use case. A database
/// `Failure` is thrown through; the widget says so and the selection stays
/// (E5).
@riverpod
class TrashController extends _$TrashController {
  @override
  TrashState build() => const TrashState();

  void chooseFilter(TrashFilter filter) => state = TrashState(filter: filter);

  /// "Select": the rows become checkboxes, nothing chosen yet.
  void startSelecting() =>
      state = TrashState(filter: state.filter, isSelecting: true);

  void stopSelecting() => state = TrashState(filter: state.filter);

  /// A tap while selecting, or the long-press that starts it. An entry of
  /// the other kind is refused (BR-TRASH-011).
  void toggle(TrashEntry entry, List<TrashEntry> entries) {
    final kind = state.kindIn(entries);
    if (kind != null && kind != TrashKind.of(entry)) return;
    final selected = {...state.selected};
    if (!selected.remove(entry.batchId)) selected.add(entry.batchId);
    state = TrashState(
      filter: state.filter,
      isSelecting: true,
      selected: selected,
    );
  }

  /// Restores the cards of [batchIds] into [deckId] (UC-TRASH-001 step 7).
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
  }) async {
    final outcome = await ref.read(restoreCardsFromTrashUseCaseProvider)(
      batchIds: batchIds,
      deckId: deckId,
    );
    if (outcome is Ok && ref.mounted) stopSelecting();
    return outcome;
  }

  /// Restores the decks of [batchIds] under [parentId], or to the top level
  /// for null (BR-TRASH-006).
  Future<Outcome<void, DeckRejection>> restoreDecks({
    required Set<String> batchIds,
    required String? parentId,
  }) async {
    final outcome = await ref.read(restoreDecksFromTrashUseCaseProvider)(
      batchIds: batchIds,
      parentId: parentId,
    );
    if (outcome is Ok && ref.mounted) stopSelecting();
    return outcome;
  }

  /// Deletes [batchIds] for good (UC-TRASH-001 A3). The batches the store
  /// skips stay, and the screen names them (spec D6).
  Future<PurgeReport> purge(Set<String> batchIds) async {
    final report = await ref.read(purgeTrashUseCaseProvider)(
      batchIds: batchIds,
    );
    if (ref.mounted) {
      state = TrashState(filter: state.filter, blocked: report.blocked);
    }
    return report;
  }

  /// The auto-purge when the Trash opens (UC-TRASH-001 A4).
  Future<void> purgeExpired() => ref.read(purgeExpiredTrashUseCaseProvider)();
}
