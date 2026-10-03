import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/di/tag_repository_provider.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_attach_model.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

import 'library_harness.dart';
import 'tag_fixtures.dart';

/// Kit 05's catalog: sixteen tags, each on as many cards as the kit counts,
/// no card carrying two of them. The long name is the kit's ellipsis case.
const List<(String, String, int)> kitTags = [
  ('t-bai', 'bài12', 12),
  ('t-cau', 'Cấu trúc thường gặp trong đề thi TOPIK II phần đọc', 3),
  ('t-can', 'cần ôn lại', 9),
  ('t-dong', 'động từ', 46),
  ('t-hay', 'hay nhầm', 14),
  ('t-hoc', 'Học', 5),
  ('t-lien', 'liên kết câu', 4),
  ('t-ngu', 'ngữ pháp', 31),
  ('t-nghe', 'nghe', 7),
  ('t-phat', 'phát âm', 6),
  ('t-quan', 'quan trọng', 11),
  ('t-so', 'sơ cấp', 20),
  ('t-tam', 'tạm', 2),
  ('t-topik', 'TOPIK I', 8),
  ('t-trung', 'trung cấp', 10),
  ('t-tu', 'từ vựng', 25),
];

/// [tags] on fresh cards of the `leaf` deck of [insertTagDecks].
Future<void> seedTags(
  LibraryEnv env, [
  List<(String, String, int)> tags = kitTags,
]) async {
  await insertTagDecks(env.db);
  var next = 0;
  for (final (id, name, count) in tags) {
    final cardIds = [for (var i = 0; i < count; i++) 'c${next + i}'];
    next += count;
    for (final cardId in cardIds) {
      await insertTagCard(env.db, cardId);
    }
    await insertTag(env.db, id, name, cardIds: cardIds);
  }
}

/// The tag store over [LibraryEnv]'s database, with the failures screen 05
/// must survive.
final class TagRepositoryFake implements TagRepository {
  TagRepositoryFake(LibraryEnv env) : _tags = TagRepositoryImpl(env.db);

  final TagRepositoryImpl _tags;

  /// The next rename or delete throws as a full disk does (`opError`).
  bool failsWrites = false;

  /// Holds every rename and delete until completed (`busy`).
  Completer<void>? hold;

  /// The catalog read fails (E1).
  bool failsReads = false;

  /// Reads wait for this before they emit (`loading`).
  Future<void>? loaded;

  Override get asOverride => tagRepositoryProvider.overrideWithValue(this);

  Future<void> _before() async {
    await hold?.future;
    if (failsWrites) {
      throw UnknownDatabaseFailure(cause: StateError('disk full'));
    }
  }

  @override
  Stream<List<TagCount>> watchTagCounts({
    String? deckId,
    String searchTerm = '',
  }) async* {
    await loaded;
    if (failsReads) {
      throw UnknownDatabaseFailure(cause: StateError('read failed'));
    }
    yield* _tags.watchTagCounts(deckId: deckId, searchTerm: searchTerm);
  }

  @override
  Future<Outcome<TagRenamePlan, TagRejection>> planRename({
    required String tagId,
    required String name,
  }) => _tags.planRename(tagId: tagId, name: name);

  @override
  Future<Outcome<void, TagRejection>> renameTag({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  }) async {
    await _before();
    return _tags.renameTag(
      tagId: tagId,
      name: name,
      mergeIntoTagId: mergeIntoTagId,
    );
  }

  @override
  Future<Outcome<void, TagRejection>> deleteTag({required String tagId}) async {
    await _before();
    return _tags.deleteTag(tagId: tagId);
  }

  @override
  Future<Outcome<TagAttach, TagRejection>> attachByName({
    required Set<String> cardIds,
    required String name,
    DateTime? now,
  }) => _tags.attachByName(cardIds: cardIds, name: name, now: now);

  @override
  Future<Outcome<void, TagRejection>> detach({
    required Set<String> cardIds,
    required String tagId,
  }) => _tags.detach(cardIds: cardIds, tagId: tagId);

  @override
  Future<Outcome<void, TagRejection>> replaceForCard({
    required String cardId,
    required List<String> names,
    DateTime? now,
  }) => _tags.replaceForCard(cardId: cardId, names: names, now: now);
}
