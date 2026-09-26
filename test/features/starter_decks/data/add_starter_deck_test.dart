import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/starter_decks/data/repositories/starter_library_repository_impl.dart';
import 'package:memox/features/starter_decks/domain/failures/starter_failure.dart';
import 'package:memox/features/starter_decks/domain/models/added_starter_deck_model.dart';
import 'package:memox/features/starter_decks/domain/models/starter_template_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/invariant_queries.dart';
import '../../../support/test_database.dart';

DateTime _clock() => DateTime.utc(2026, 9, 26, 9);

const _id = 'fixture.test';

StarterTemplate _template({
  int version = 1,
  String title = 'Everyday',
  List<StarterDeck> decks = const [
    StarterDeck(
      name: 'Words',
      decks: [
        StarterDeck(
          name: 'Greetings',
          cards: [
            StarterCard(front: 'hello', back: 'xin chào'),
            StarterCard(
              front: 'goodbye',
              back: 'tạm biệt',
              example: 'Goodbye, see you tomorrow.',
              hint: 'leaving',
              pronunciation: 'ɡʊdˈbaɪ',
            ),
          ],
        ),
      ],
    ),
    StarterDeck(
      name: 'Travel',
      cards: [StarterCard(front: 'ticket', back: 'vé')],
    ),
  ],
}) => StarterTemplate(
  templateId: _id,
  version: version,
  locale: 'en',
  title: title,
  contentSource: 'Development fixture',
  frontLanguage: 'en',
  backLanguage: 'vi',
  suggestedScheduler: SchedulerType.eightBox,
  decks: decks,
);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _clock);
  });
  tearDown(() => db.close());

  /// The library over [templates], as a build of the app would read them.
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

  Future<Outcome<AddedStarterDeck, StarterRejection>> add(
    StarterLibraryRepositoryImpl repo, {
    SchedulerType schedulerType = SchedulerType.sm2,
    bool allowSecondCopy = false,
  }) => repo.addStarterDeck(
    templateId: _id,
    schedulerType: schedulerType,
    allowSecondCopy: allowSecondCopy,
  );

  Future<AddedStarterDeck> added(
    StarterLibraryRepositoryImpl repo, {
    bool allowSecondCopy = false,
  }) async => switch (await add(repo, allowSecondCopy: allowSecondCopy)) {
    Ok(:final value) => value,
    Rejected(:final reason) => throw StateError('refused: $reason'),
  };

  Future<List<Map<String, Object?>>> rows(
    String sql, [
    List<String> args = const [],
  ]) async => [
    for (final row
        in await db
            .customSelect(sql, variables: [for (final a in args) Variable(a)])
            .get())
      row.data,
  ];

  Future<int> count(String table) async =>
      (await rows('SELECT COUNT(*) AS n FROM $table')).single['n']! as int;

  test('a copy is an ordinary deck tree of its own: the root, the sub-decks '
      'in template order, the cards, and one fresh schedule row per card '
      'under the chosen scheduler (BR-STARTER-003, BR-STARTER-004)', () async {
    final copy = await added(library([_template()]));

    expect(
      (copy.title, copy.schedulerType, copy.cardCount),
      ('Everyday', SchedulerType.sm2, 3),
    );
    expect(
      await rows(
        'SELECT d.name, p.name AS parent, d.root_id = ? AS in_copy, d.depth, '
        'd.content_type, d.scheduler_type, d.generation, d.first_answered_at, '
        'd.source_template_id, d.source_template_version '
        'FROM deck d LEFT JOIN deck p ON p.id = d.parent_id '
        'ORDER BY d.depth, d.sibling_position',
        [copy.rootDeckId],
      ),
      [
        {
          'name': 'Everyday',
          'parent': null,
          'in_copy': 1,
          'depth': 1,
          'content_type': 'deck',
          'scheduler_type': 'sm2',
          'generation': 1,
          'first_answered_at': null,
          'source_template_id': _id,
          'source_template_version': 1,
        },
        for (final (name, parent, depth, type) in [
          ('Words', 'Everyday', 2, 'deck'),
          ('Travel', 'Everyday', 2, 'card'),
          ('Greetings', 'Words', 3, 'card'),
        ])
          {
            'name': name,
            'parent': parent,
            'in_copy': 1,
            'depth': depth,
            'content_type': type,
            'scheduler_type': null,
            'generation': null,
            'first_answered_at': null,
            'source_template_id': null,
            'source_template_version': null,
          },
      ],
    );
    expect(
      await rows(
        'SELECT d.name AS deck, c.front, c.back, c.example, c.hint, '
        'c.pronunciation, s.scheduler_type, '
        's.generation, s.learned_at IS NULL AS is_new '
        'FROM card c JOIN deck d ON d.id = c.deck_id '
        'JOIN card_schedule s ON s.card_id = c.id ORDER BY d.name, c.front',
      ),
      [
        for (final (deck, front, back, example, hint, pronunciation) in [
          (
            'Greetings',
            'goodbye',
            'tạm biệt',
            'Goodbye, see you tomorrow.',
            'leaving',
            'ɡʊdˈbaɪ',
          ),
          ('Greetings', 'hello', 'xin chào', null, null, null),
          ('Travel', 'ticket', 'vé', null, null, null),
        ])
          {
            'deck': deck,
            'front': front,
            'back': back,
            'example': example,
            'hint': hint,
            'pronunciation': pronunciation,
            'scheduler_type': 'sm2',
            'generation': 1,
            'is_new': 1,
          },
      ],
    );
    expect(await count('card_schedule'), 3);
    expect(await count('review_log'), 0);
    for (final MapEntry(key: number, value: query)
        in invariantQueries.entries) {
      expect(await rows(query), isEmpty, reason: 'invariant $number');
    }
  });

  test('the deepest template the library lists copies whole: ten levels '
      'with the root, cards on the tenth (BR-DECK-001, spec D6)', () async {
    var deepest = const StarterDeck(
      name: 'Level 10',
      cards: [StarterCard(front: 'deep', back: 'sâu')],
    );
    for (var level = 9; level >= 2; level--) {
      deepest = StarterDeck(name: 'Level $level', decks: [deepest]);
    }

    final copy = await added(
      library([
        _template(decks: [deepest]),
      ]),
    );

    expect(
      await rows(
        'SELECT MAX(depth) AS depth, COUNT(*) AS decks FROM deck '
        'WHERE root_id = ?',
        [copy.rootDeckId],
      ),
      [
        {'depth': 10, 'decks': 10},
      ],
    );
    expect(await count('card'), 1);
  });

  test('a copy under eight boxes writes eight-box schedule rows', () async {
    await add(library([_template()]), schedulerType: SchedulerType.eightBox);

    expect(await rows('SELECT DISTINCT scheduler_type FROM card_schedule'), [
      {'scheduler_type': 'eight_box'},
    ]);
  });

  test('a template already in the library is not copied again: the add '
      'writes nothing and says so (BR-STARTER-007)', () async {
    final repo = library([_template()]);
    await added(repo);
    final before = await totalChanges(db);

    final again = await add(repo);

    expect(
      (again as Rejected<AddedStarterDeck, StarterRejection>).reason,
      StarterRejection.alreadyInLibrary,
    );
    expect(await totalChanges(db), before);
  });

  test('two adds at once, as a double tap sends them, make one copy: the '
      'second finds the first inside its transaction (spec D8)', () async {
    final repo = library([_template()]);

    final results = await Future.wait([add(repo), add(repo)]);

    expect([
      for (final result in results)
        switch (result) {
          Ok() => 'added',
          Rejected(:final reason) => reason.name,
        },
    ], unorderedEquals(['added', 'alreadyInLibrary']));
    expect(
      await rows('SELECT id FROM deck WHERE parent_id IS NULL'),
      hasLength(1),
    );
  });

  test('a confirmed second copy is a separate tree of its own, with the same '
      'name (BR-STARTER-008)', () async {
    final repo = library([_template()]);
    final first = await added(repo);

    final second = await added(repo, allowSecondCopy: true);

    expect(second.rootDeckId, isNot(first.rootDeckId));
    expect(await rows('SELECT name FROM deck WHERE parent_id IS NULL'), [
      {'name': 'Everyday'},
      {'name': 'Everyday'},
    ]);
    expect(await count('card'), 6);
    expect(await count('card_schedule'), 6);
  });

  test('a copy in the Trash is not in the library, and a restored one is '
      'again (UC-STARTER-001 A4, spec D7)', () async {
    final repo = library([_template()]);
    final first = await added(repo);
    Future<String> trash(String deckId) async =>
        switch (await decks.deleteDeck(deckId: deckId)) {
          Ok(:final value) => value,
          Rejected(:final reason) => throw StateError('$reason'),
        };

    final batchId = await trash(first.rootDeckId);
    await decks.restoreDecks(batchIds: {batchId}, parentId: null);
    final whileRestored = await add(repo);
    await trash(first.rootDeckId);
    final again = await added(repo);

    expect(
      (whileRestored as Rejected<AddedStarterDeck, StarterRejection>).reason,
      StarterRejection.alreadyInLibrary,
    );
    expect(again.rootDeckId, isNot(first.rootDeckId));
  });

  test('a new version of a template is not in the library: it copies without '
      'asking and leaves the old version\'s copy as it was (BR-STARTER-006, '
      'UC-STARTER-001 A3)', () async {
    const tree =
        'SELECT d.name, d.content_type, c.front, c.back FROM deck d '
        'LEFT JOIN card c ON c.deck_id = d.id WHERE d.root_id = ? '
        'ORDER BY d.depth, d.sibling_position, c.front';
    final old = await added(library([_template()]));
    final oldTree = await rows(tree, [old.rootDeckId]);
    final update = _template(
      version: 2,
      title: 'Everyday, updated',
      decks: const [
        StarterDeck(
          name: 'Food',
          cards: [StarterCard(front: 'rice', back: 'cơm')],
        ),
      ],
    );

    final copy = await added(library([update]));

    expect(copy.rootDeckId, isNot(old.rootDeckId));
    expect(
      await rows(
        'SELECT source_template_version AS v FROM deck '
        'WHERE parent_id IS NULL ORDER BY v',
      ),
      [
        {'v': 1},
        {'v': 2},
      ],
    );
    expect(await rows(tree, [old.rootDeckId]), oldTree);
  });

  test('a copy that fails half-way writes nothing: no root, deck, card or '
      'schedule row (BR-STARTER-009, UC-STARTER-001 E4)', () async {
    // A card the card rules refuse: only a template that skipped the
    // library's checks (spec D6) could hold it, after a good deck.
    final broken = _template(
      decks: const [
        StarterDeck(
          name: 'Good',
          cards: [StarterCard(front: 'hello', back: 'xin chào')],
        ),
        StarterDeck(
          name: 'Bad',
          cards: [StarterCard(front: ' ', back: 'blank')],
        ),
      ],
    );

    await expectLater(add(library([broken])), throwsA(isA<Failure>()));
    expect(await count('deck'), 0);
    expect(await count('card'), 0);
    expect(await count('card_schedule'), 0);
  });

  test('a template the library does not have is refused and nothing is '
      'written', () async {
    final before = await totalChanges(db);

    final result = await library([_template()]).addStarterDeck(
      templateId: 'fixture.other',
      schedulerType: SchedulerType.sm2,
    );

    expect(
      (result as Rejected<AddedStarterDeck, StarterRejection>).reason,
      StarterRejection.templateNotFound,
    );
    expect(await totalChanges(db), before);
  });
}
