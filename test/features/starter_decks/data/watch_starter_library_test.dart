import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/domain/models/starter_library_entry_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/test_database.dart';

// UC-STARTER-001 steps 4-5 and A4: what the Starter library lists, and how
// it follows the copies (starter decks spec §6, D7, D12).

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (the kit's `loadFailed`).
final class _FailingSelects extends QueryInterceptor {
  bool isArmed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isArmed) {
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}

DateTime _clock() => DateTime.utc(2026, 9, 26, 9);

StarterTemplate _template(String id, {int version = 1}) => StarterTemplate(
  templateId: id,
  version: version,
  locale: 'en',
  title: 'Template $id',
  contentSource: 'Development fixture',
  frontLanguage: 'en',
  backLanguage: 'vi',
  suggestedScheduler: SchedulerType.eightBox,
  decks: const [
    StarterDeck(
      name: 'Words',
      decks: [
        StarterDeck(
          name: 'Greetings',
          cards: [
            StarterCard(front: 'hello', back: 'xin chào'),
            StarterCard(front: 'goodbye', back: 'tạm biệt'),
          ],
        ),
      ],
    ),
    StarterDeck(
      name: 'Travel',
      cards: [
        StarterCard(front: 'ticket', back: 'vé'),
        StarterCard(front: 'map', back: 'bản đồ'),
      ],
    ),
  ],
);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: _clock);
  }

  tearDown(() => db.close());

  StarterLibraryRepositoryImpl library(List<StarterTemplate> templates) =>
      StarterLibraryRepositoryImpl(
        db,
        decks,
        CardRepositoryImpl(
          db,
          ScheduleRepositoryImpl(db, now: _clock),
          TagRepositoryImpl(db, now: _clock),
          now: _clock,
        ),
        templates: () async => templates,
      );

  Future<String> add(StarterLibraryRepositoryImpl repo, String id) async =>
      switch (await repo.addStarterDeck(
        templateId: id,
        schedulerType: SchedulerType.sm2,
      )) {
        Ok(:final value) => value.rootDeckId,
        Rejected(:final reason) => throw StateError('refused: $reason'),
      };

  test(
    'the library lists every template in manifest order with what its '
    'card shows, none of them in the library yet (UC-STARTER-001 step 5)',
    () async {
      open();
      final entries = await library([_template('b'), _template('a')])
          .watchLibrary()
          .first;

      expect(
        [
          for (final StarterLibraryEntry e in entries)
            (
              e.templateId,
              e.version,
              e.title,
              e.locale,
              e.frontLanguage,
              e.backLanguage,
              e.contentSource,
              e.suggestedScheduler,
              e.cardCount,
              e.subDeckCount,
              e.isInLibrary,
            ),
        ],
        [
          for (final id in ['b', 'a'])
            (
              id,
              1,
              'Template $id',
              'en',
              'en',
              'vi',
              'Development fixture',
              SchedulerType.eightBox,
              4,
              3,
              false,
            ),
        ],
      );
    },
  );

  test('a template is in the library while a copy of it at its version is '
      'outside the Trash, and only that template (spec D7)', () async {
    open();
    final first = library([_template('a'), _template('b')]);
    await add(first, 'a');
    final update = library([_template('a', version: 2), _template('b')]);

    expect(
      [
        for (final e in await first.watchLibrary().first)
          (e.templateId, e.isInLibrary),
      ],
      [('a', true), ('b', false)],
    );
    expect(
      [
        for (final e in await update.watchLibrary().first)
          (e.templateId, e.version, e.isInLibrary),
      ],
      [('a', 2, false), ('b', 1, false)],
    );
  });

  test('a copy its owner renamed is still in the library: a template is known '
      'by its id and version, not by a name (spec D7)', () async {
    open();
    final repo = library([_template('a')]);
    final rootId = await add(repo, 'a');
    await decks.renameDeck(deckId: rootId, name: 'My words');

    expect(
      [for (final e in await repo.watchLibrary().first) e.isInLibrary],
      [true],
    );
  });

  test('the library follows a copy added, sent to the Trash and restored '
      '(UC-STARTER-001 A4, spec D12)', () async {
    open();
    final repo = library([_template('a')]);
    final isInLibrary = repo.watchLibrary().map(
      (entries) => entries.single.isInLibrary,
    );

    final followed = expectLater(
      isInLibrary,
      emitsInOrder([
        false,
        emitsThrough(true),
        emitsThrough(false),
        emitsThrough(true),
      ]),
    );
    await pumpEventQueue();
    final rootId = await add(repo, 'a');
    await pumpEventQueue();
    final batch = switch (await decks.deleteDeck(deckId: rootId)) {
      Ok(:final value) => value,
      Rejected(:final reason) => throw StateError('$reason'),
    };
    await pumpEventQueue();
    await decks.restoreDecks(batchIds: {batch}, parentId: null);
    await followed;
  });

  test('a database error reaches the library as its Failure (the kit\'s '
      'loadFailed)', () async {
    final failing = _FailingSelects();
    open(failing);
    final repo = library([_template('a')]);
    await add(repo, 'a');
    failing.isArmed = true;

    await expectLater(repo.watchLibrary(), emitsError(isA<Failure>()));
    failing.isArmed = false;
  });
}
