import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/trash/data/datasources/trash_dao.dart';
import 'package:memox/features/trash/data/mappers/trash_mapper.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// The Trash in one transaction a call: each emission of the list is one
/// snapshot, and each purge is all or nothing (trash spec D12).
final class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._db) : _dao = TrashDao(_db);

  final AppDatabase _db;
  final TrashDao _dao;

  @override
  Stream<List<TrashEntry>> watchEntries() => _dao
      .entryChanges()
      .asyncMap(
        (_) => _db.transaction(
          () async => trashEntriesOf(
            decks: await _dao.deckEntryRows(),
            cards: await _dao.cardEntryRows(),
            forest: await _dao.forestRows(),
          ),
        ),
      )
      .mapDatabaseErrors();

  @override
  Future<PurgeReport> purge({
    required Set<String> batchIds,
    required DateTime now,
  }) => _purge(batchIds, now);

  @override
  Future<PurgeReport> purgeExpired({required DateTime now}) =>
      _purge(const {}, now);

  /// Passes in ascending `deleted_at` until one purges nothing: an inner
  /// batch is older than its deck's (invariant 36), and a pass after it takes
  /// the deck. What is left is skipped whole (BR-TRASH-010).
  Future<PurgeReport> _purge(Set<String> chosen, DateTime now) async {
    try {
      return await _db.transaction(() async {
        var pending = await _dao.purgeCandidates(
          chosen: chosen,
          cutoff: trashCutoff(now),
        );
        final found = {for (final batch in pending) batch.id};
        final purged = <String>{};
        while (true) {
          final left = <DeleteBatch>[];
          for (final batch in pending) {
            if (batch.itemType == 'deck' &&
                (await _dao.blockersOf(batch.id)).isNotEmpty) {
              left.add(batch);
              continue;
            }
            await _dao.purge(batch.id);
            purged.add(batch.id);
          }
          if (left.length == pending.length) break;
          pending = left;
        }
        return PurgeReport(
          purged: purged,
          blocked: {
            for (final batch in pending)
              batch.id: {...(await _dao.blockersOf(batch.id)).nonNulls},
          },
          missing: chosen.difference(found),
        );
      });
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
