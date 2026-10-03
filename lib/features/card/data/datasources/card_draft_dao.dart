import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'card_draft_dao.g.dart';

/// Row access for `card_draft` (`card_draft_queries.drift`): the card being
/// written, device-local and never synced (SP2a R9). It returns Drift rows,
/// never domain models.
@DriftAccessor(
  include: {'package:memox/core/database/queries/card_draft_queries.drift'},
)
final class CardDraftDao extends DatabaseAccessor<AppDatabase>
    with _$CardDraftDaoMixin {
  CardDraftDao(super.attachedDatabase);

  Future<CardDraftRow?> find(String key) =>
      findCardDraft(key).getSingleOrNull();

  Future<void> upsert({
    required String key,
    required String front,
    required String back,
    required String extras,
    required String tags,
    required DateTime at,
  }) => upsertCardDraft(key, front, back, extras, tags, at);

  Future<void> remove(String key) => deleteCardDraft(key);

  Future<void> removeBefore(DateTime cutoff) => deleteCardDraftsBefore(cutoff);
}
