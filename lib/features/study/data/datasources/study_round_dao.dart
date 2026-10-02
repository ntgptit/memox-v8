import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'study_round_dao.g.dart';

/// A built row of a round, with what preparing the round reads of it.
typedef RoundRowRecord = ({
  String cardId,
  int position,
  bool isPending,
  int? meaningSlot,
  int optionCount,
  String backFolded,
});

/// Row access for preparing a round (graded modes spec §8.2): its built rows,
/// the meaning source of its `guess` questions, the meaning slots of its
/// `match` boards and the stored options (`study_round_queries.drift`). It
/// returns Drift rows and records, never domain values, and runs inside the
/// caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/study_round_queries.drift'},
)
final class StudyRoundDao extends DatabaseAccessor<AppDatabase>
    with _$StudyRoundDaoMixin {
  StudyRoundDao(super.attachedDatabase);

  /// The built rows of [round] of [mode], in position order, with their
  /// card's `back_folded` and the options their question has stored.
  Future<List<RoundRowRecord>> builtRows(
    String sessionId,
    String mode,
    int round,
  ) async => [
    for (final row in await builtRoundRows(sessionId, mode, round).get())
      (
        cardId: row.cardId,
        position: row.position,
        isPending: row.status == 'pending',
        meaningSlot: row.meaningSlot,
        optionCount: row.optionCount,
        backFolded: row.backFolded,
      ),
  ];

  /// The cards a `guess` question of [sessionId] can draw on: those of its
  /// queue and the learned, active cards of [rootId]'s tree, each with its
  /// `back_folded` (BR-STUDY-038; package 2a spec D5). Sorted, so a seeded
  /// draw repeats.
  Future<List<({String cardId, String meaningFolded})>> meaningSource(
    String sessionId,
    String rootId,
  ) async => [
    for (final row in await meaningSourceOf(rootId, sessionId).get())
      (cardId: row.id, meaningFolded: row.meaningFolded),
  ];

  /// Gives each card of [slots] its meaning slot in [round] of [mode].
  Future<void> setMeaningSlots(
    String sessionId,
    String mode,
    int round,
    Map<String, int> slots,
  ) async {
    for (final MapEntry(key: cardId, value: slot) in slots.entries) {
      await setRoundMeaningSlot(slot, sessionId, mode, round, cardId);
    }
  }

  /// Replaces the options of [cardId]'s question in [round] with
  /// [optionIds], in the order shown; with none when [optionIds] is null.
  /// One insert per option, inside the caller's transaction (`.drift` spec D9).
  Future<void> replaceOptions(
    String sessionId,
    int round,
    String cardId,
    List<String>? optionIds,
  ) async {
    await deleteGuessOptionsOf(sessionId, round, cardId);
    if (optionIds == null) return;
    for (final (slot, optionId) in optionIds.indexed) {
      await createGuessOption(
        StudyGuessOptionsCompanion.insert(
          sessionId: sessionId,
          round: round,
          cardId: cardId,
          slot: slot,
          optionCardId: optionId,
        ),
      );
    }
  }
}
