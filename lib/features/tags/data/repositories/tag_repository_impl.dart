import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/tags/data/datasources/tag_dao.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// Every method checks its rules on rows read inside its transaction, and
/// writes only once every rule has passed: a refusal writes nothing.
final class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = TagDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final TagDao _dao;
  final DateTime Function() _now;

  @override
  Future<Outcome<void, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (TagEntity.checkName(name) case Rejected(:final reason)) {
        return Rejected(reason);
      }
      if (cardIds.isEmpty) return const Ok(null);
      if (await _dao.liveCardCount(cardIds) != cardIds.length) {
        return const Rejected(TagRejection.notFound);
      }
      final existing = await _dao.findByFoldedName(TagEntity.fold(name));
      final lacking = existing == null
          ? cardIds
          : cardIds.difference(await _dao.cardsCarrying(cardIds, existing.id));
      final counts = await _dao.tagCounts(lacking);
      if (counts.values.any((count) => count >= TagEntity.maxPerCard)) {
        return const Rejected(TagRejection.tooManyTags);
      }

      final tagId = existing?.id ?? await _createTag(name, at);
      for (final cardId in lacking) {
        await _dao.link(cardId, tagId);
      }
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, TagRejection>> detach({
    required Set<String> cardIds,
    required String tagId,
  }) => _write(() async {
    if (cardIds.isEmpty) return const Ok(null);
    if (await _dao.liveCardCount(cardIds) != cardIds.length) {
      return const Rejected(TagRejection.notFound);
    }
    if (await _dao.findById(tagId) == null) {
      return const Rejected(TagRejection.notFound);
    }
    await _dao.unlink(cardIds, tagId);
    return const Ok(null);
  });

  @override
  Future<Outcome<void, TagRejection>> replaceForCard({
    required String cardId,
    required List<String> names,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      for (final name in names) {
        if (TagEntity.checkName(name) case Rejected(:final reason)) {
          return Rejected(reason);
        }
      }
      final byFold = <String, String>{};
      for (final name in names) {
        byFold.putIfAbsent(TagEntity.fold(name), () => name);
      }
      if (byFold.length > TagEntity.maxPerCard) {
        return const Rejected(TagRejection.tooManyTags);
      }
      if (await _dao.liveCardCount({cardId}) != 1) {
        return const Rejected(TagRejection.notFound);
      }

      final wanted = <String>{};
      for (final MapEntry(key: folded, value: name) in byFold.entries) {
        final existing = await _dao.findByFoldedName(folded);
        wanted.add(existing?.id ?? await _createTag(name, at));
      }
      final carried = await _dao.tagIdsOf(cardId);
      for (final tagId in carried.difference(wanted)) {
        await _dao.unlink({cardId}, tagId);
      }
      for (final tagId in wanted.difference(carried)) {
        await _dao.link(cardId, tagId);
      }
      return const Ok(null);
    });
  }

  @override
  Stream<List<TagCount>> watchTagCounts({
    String? deckId,
    String searchTerm = '',
  }) {
    final term = TagEntity.fold(searchTerm);
    return _dao
        .countChanges()
        .asyncMap((_) => _dao.countRows(deckId: deckId, foldedTerm: term))
        .map(
          (rows) => [
            for (final row in rows)
              TagCount(
                id: row.read<String>('id'),
                name: row.read<String>('name'),
                cardCount: row.read<int>('card_count'),
              ),
          ],
        )
        .mapDatabaseErrors();
  }

  Future<String> _createTag(String name, DateTime at) async {
    final id = newId();
    await _dao.insertTag(
      TagsCompanion.insert(
        id: id,
        name: name.trim(),
        nameFolded: TagEntity.fold(name),
        createdAt: at,
      ),
    );
    return id;
  }

  /// One transaction, joining the caller's. An unexpected database error
  /// leaves as the [Failure] `mapDatabaseError` makes of it.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
