import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

part 'deck_sync_dao.g.dart';

/// Syncs `deck`. The server derives rootId and depth; the pulled values are
/// written as they come.
@DriftAccessor(
  include: {'package:memox/core/database/queries/sync_deck_queries.drift'},
)
class DeckSyncDao extends DatabaseAccessor<AppDatabase>
    with _$DeckSyncDaoMixin, EntitySyncAdapter {
  DeckSyncDao(super.attachedDatabase);

  static const type = 'deck';

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final deck = await syncDeckRow(id).getSingleOrNull();
    if (deck == null) {
      return null;
    }
    return {
      'id': deck.id,
      'name': deck.name,
      'parentId': deck.parentId,
      'rootId': deck.rootId,
      'depth': deck.depth,
      'contentType': deck.contentType,
      'schedulerType': deck.schedulerType,
      'schedulerVersion': deck.schedulerVersion,
      'schedulerConfig': deck.schedulerConfig,
      'studyConfig': deck.studyConfig,
      'generation': deck.generation,
      'firstAnsweredAt': _time(deck.firstAnsweredAt),
      'sourceTemplateId': deck.sourceTemplateId,
      'sourceTemplateVersion': deck.sourceTemplateVersion,
      'deleteBatchId': deck.deleteBatchId,
      'siblingPosition': deck.siblingPosition,
      'createdAt': _time(deck.createdAt),
      'updatedAt': _time(deck.updatedAt),
    };
  }

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) =>
      upsertSyncedDeck(
        DeckCompanion.insert(
          id: row['id'] as String,
          name: row['name'] as String,
          parentId: Value(row['parentId'] as String?),
          rootId: row['rootId'] as String,
          depth: row['depth'] as int,
          contentType: Value(row['contentType'] as String),
          schedulerType: Value(row['schedulerType'] as String?),
          schedulerVersion: Value(row['schedulerVersion'] as int?),
          schedulerConfig: Value(row['schedulerConfig'] as String?),
          studyConfig: Value(row['studyConfig'] as String?),
          generation: Value(row['generation'] as int?),
          firstAnsweredAt: Value(fromWireTime(row['firstAnsweredAt'])),
          sourceTemplateId: Value(row['sourceTemplateId'] as String?),
          sourceTemplateVersion: Value(row['sourceTemplateVersion'] as int?),
          deleteBatchId: Value(row['deleteBatchId'] as String?),
          siblingPosition: row['siblingPosition'] as int,
          createdAt: fromWireTime(row['createdAt'])!,
          updatedAt: fromWireTime(row['updatedAt'])!,
          serverVersion: Value(serverVersion),
        ),
      );

  @override
  Future<void> deleteFromServer(String id) => deleteSyncedDeck(id);

  @override
  Future<void> markAcknowledged(String id, int serverVersion) =>
      acknowledgeDeck(serverVersion, id);

  /// Drift stores whole seconds; the wire drops the fractional part so a
  /// round-trip is exact.
  static String? _time(DateTime? value) =>
      toWireTime(value)?.replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
}
