import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/presentation/controllers/tag_actions_controller.dart';
import 'package:memox/features/tags/presentation/states/tag_actions_state.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/tag_fixtures.dart';
import '../../../support/tag_screen_fixtures.dart';
import '../../../support/test_database.dart';

// FE-B2 spec D8: screen 05's writes, over the real tag store.

const _tags = [
  ('t-verb', 'động từ', 3),
  ('t-grammar', 'ngữ pháp', 2),
  ('t-tmp', 'tạm', 1),
];

void main() {
  late LibraryEnv env;
  late TagRepositoryFake store;
  late ProviderContainer container;

  setUp(() async {
    env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    await seedTags(env, _tags);
    store = TagRepositoryFake(env);
    container = libraryContainer(env, overrides: [store.asOverride]);
    container.listen(tagActionsControllerProvider, (_, _) {});
  });
  tearDown(() => env.db.close());

  TagActionsController tags() =>
      container.read(tagActionsControllerProvider.notifier);

  Future<TagRenamePlan> plan(String name) async =>
      switch (await tags().planRename(tagId: 't-verb', name: name)) {
        Ok(:final value) => value,
        Rejected(:final reason) => throw StateError('$reason'),
      };

  test('the plan says unchanged, rename, or merge with the union count '
      '(UC-TAG-001 A1, A2)', () async {
    expect(await plan('động từ'), isA<TagRenameUnchanged>());
    expect(await plan('Động từ'), isA<TagRenameRename>());
    expect(await plan('verb'), isA<TagRenameRename>());
    final merge = await plan('NGỮ PHÁP') as TagRenameMerge;
    expect(
      (merge.target.id, merge.target.name, merge.mergedCardCount),
      ('t-grammar', 'ngữ pháp', 5),
    );
  });

  test('a name that breaks a rule is a rejection of the plan (E2)', () async {
    final outcome = await tags().planRename(tagId: 't-verb', name: '  ');

    expect(outcome, isA<Rejected<TagRenamePlan, TagRejection>>());
  });

  test('rename keeps the id; merge folds into the confirmed target', () async {
    expect(
      await tags().rename(tagId: 't-verb', name: 'verb'),
      TagWriteResult.done,
    );
    expect((await tagRowsOf(env.db)).map((row) => row.$2), contains('verb'));

    expect(
      await tags().rename(
        tagId: 't-verb',
        name: 'ngữ pháp',
        mergeIntoTagId: 't-grammar',
      ),
      TagWriteResult.done,
    );
    expect((await tagRowsOf(env.db)).map((row) => row.$1), [
      't-grammar',
      't-tmp',
    ]);
  });

  test('a merge the person did not confirm plans again '
      '(mergeNotConfirmed)', () async {
    expect(
      await tags().rename(tagId: 't-verb', name: 'ngữ pháp'),
      TagWriteResult.replan,
    );
    expect(await tagRowsOf(env.db), hasLength(3));
  });

  test('delete removes the tag and keeps every card (A3)', () async {
    expect(await tags().delete('t-tmp'), TagWriteResult.done);

    expect((await tagRowsOf(env.db)).map((row) => row.$1), [
      't-grammar',
      't-verb',
    ]);
    final cards = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM card')
        .getSingle();
    expect(cards.read<int>('n'), 6);
  });

  test(
    'a tag deleted elsewhere is gone, for a rename and a delete (E3)',
    () async {
      await env.db.customStatement(
        "DELETE FROM card_tags WHERE tag_id = 't-tmp'",
      );
      await env.db.customStatement("DELETE FROM tags WHERE id = 't-tmp'");

      expect(await tags().delete('t-tmp'), TagWriteResult.gone);
      expect(
        await tags().rename(tagId: 't-tmp', name: 'x'),
        TagWriteResult.gone,
      );
    },
  );

  test('a failed write changes nothing and says so (E4, E5)', () async {
    store.failsWrites = true;

    expect(await tags().delete('t-tmp'), TagWriteResult.failed);
    expect(
      await tags().rename(tagId: 't-verb', name: 'verb'),
      TagWriteResult.failed,
    );
    expect(await tagRowsOf(env.db), hasLength(3));
    expect(container.read(tagActionsControllerProvider).busyTagIds, isEmpty);
  });

  test('the row is busy while its write runs, and only then', () async {
    store.hold = Completer<void>();
    final deleting = tags().delete('t-tmp');

    expect(
      container.read(tagActionsControllerProvider).isBusy('t-tmp'),
      isTrue,
    );
    expect(
      container.read(tagActionsControllerProvider).isBusy('t-verb'),
      isFalse,
    );

    store.hold!.complete();
    expect(await deleting, TagWriteResult.done);
    expect(
      container.read(tagActionsControllerProvider).isBusy('t-tmp'),
      isFalse,
    );
  });
}
