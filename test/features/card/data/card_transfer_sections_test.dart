import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_import_section_model.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// Spec 2026-10-08 §4.5: one transaction makes the section decks and their
// cards, checking every destination before the first write.

DateTime _now() => DateTime(2026, 10, 8);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

CardImportSection _section(String name, List<String> fronts, {String? into}) =>
    CardImportSection(
      name: name,
      existingDeckId: into,
      drafts: [for (final f in fronts) CardDraft(front: f, back: 'b')],
    );

List<CardImportSectionResult> _ok(
  Outcome<List<CardImportSectionResult>, CardRejection> result,
) => (result as Ok<List<CardImportSectionResult>, CardRejection>).value;

CardRejection _reason(
  Outcome<List<CardImportSectionResult>, CardRejection> result,
) => (result as Rejected<List<CardImportSectionResult>, CardRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardTransferRepositoryImpl cards;
  late DeckEntity root;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardTransferRepositoryImpl(
      db,
      CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: _now),
        TagRepositoryImpl(db, now: _now),
        DeckTreeDataSource(db),
        now: _now,
      ),
      decks,
    );
    root = await decks.root('Korean');
  });
  tearDown(() => db.close());

  Future<List<(String, int)>> children(String parentId) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT d.name, (SELECT COUNT(*) FROM card c WHERE c.deck_id = d.id) '
              'AS n FROM deck d WHERE d.parent_id = ? ORDER BY d.sibling_position',
              variables: [Variable<String>(parentId)],
            )
            .get())
      (row.read<String>('name'), row.read<int>('n')),
  ];

  test('importTarget: the target, its direct sub-decks in order, and their '
      'faces', () async {
    final words = await decks.sub(root.id, 'Words');
    final grammar = await decks.sub(root.id, 'Grammar');
    await decks.sub(grammar.id, 'Particles');
    await insertCard(db, id: 'c', deckId: words.id, front: ' Menu', back: 'x');

    final target = (await cards.importTarget(root.id))!;

    expect(
      (target.isDeckOfCards, target.canHoldCards, target.canHoldDecks),
      (false, false, true),
    );
    expect(
      [for (final c in target.children) (c.name, c.canHoldCards)],
      [('Words', true), ('Grammar', false)],
    );
    expect(target.children.first.pairs, {(front: 'menu', back: 'x')});
    expect(await cards.importTarget('gone'), isNull);
  });

  test('sections become sub-decks in source order, cards in source '
      'order', () async {
    _ok(
      await cards.importSections(
        targetDeckId: root.id,
        sections: [
          _section('Part 1', ['a', 'b']),
          _section('관용어', ['c']),
        ],
        includeDuplicates: false,
      ),
    );

    expect(await children(root.id), [('Part 1', 2), ('관용어', 1)]);
    expect(await _count(db, 'card_schedule'), 3);
  });

  test('an unset target becomes a deck of decks (BR-TRANSFER-005)', () async {
    final unset = await decks.sub(root.id, 'Topik');
    _ok(
      await cards.importSections(
        targetDeckId: unset.id,
        sections: [
          _section('A', ['a']),
        ],
        includeDuplicates: false,
      ),
    );
    expect((await decks.findById(unset.id))!.contentType, DeckContentType.deck);
  });

  test('add to existing writes into it and skips its duplicates '
      '(BR-TRANSFER-003)', () async {
    final part = await decks.sub(root.id, 'Part 1');
    await insertCard(db, id: 'old', deckId: part.id, front: 'a', back: 'b');

    final section = _ok(
      await cards.importSections(
        targetDeckId: root.id,
        sections: [
          _section('Part 1', ['a', 'z'], into: part.id),
        ],
        includeDuplicates: false,
      ),
    ).single;

    expect((section.deckId, section.written), (part.id, 1));
    expect(section.skippedIndexes, [0]);
    expect(await children(root.id), [('Part 1', 2)]);
  });

  test('a section left with nothing to write makes no deck', () async {
    final section = _ok(
      await cards.importSections(
        targetDeckId: root.id,
        sections: [_section('Empty', [])],
        includeDuplicates: false,
      ),
    ).single;
    expect(section.deckId, isNull);
    expect(await children(root.id), isEmpty);
  });

  test('an existing deck that moved away refuses the whole import, nothing '
      'written (BR-TRANSFER-001)', () async {
    final part = await decks.sub(root.id, 'Part 1');
    final other = await decks.root('Other');
    await decks.moveDeck(deckId: part.id, newParentId: other.id);

    final result = await cards.importSections(
      targetDeckId: root.id,
      sections: [
        _section('New', ['a']),
        _section('Part 1', ['b'], into: part.id),
      ],
      includeDuplicates: false,
    );

    expect(_reason(result), CardRejection.sectionTargetChanged);
    expect(await _count(db, 'card'), 0);
    expect(await children(root.id), isEmpty);
  });

  test('a deck of cards cannot take sections (BR-TRANSFER-001)', () async {
    final words = await decks.sub(root.id, 'Words');
    await insertCard(db, id: 'c', deckId: words.id, front: 'a', back: 'b');

    final result = await cards.importSections(
      targetDeckId: words.id,
      sections: [
        _section('A', ['x']),
      ],
      includeDuplicates: false,
    );

    expect(_reason(result), CardRejection.notADeckContainer);
  });

  test('cards of one section keep the source order through their ids '
      '(Review Focus 4)', () async {
    _ok(
      await cards.importSections(
        targetDeckId: root.id,
        sections: [
          _section('A', ['a1', 'a2', 'a3']),
        ],
        includeDuplicates: false,
      ),
    );
    final fronts = await db
        .customSelect('SELECT front FROM card ORDER BY id')
        .map((row) => row.read<String>('front'))
        .get();
    expect(fronts, ['a1', 'a2', 'a3']);
  });
}
