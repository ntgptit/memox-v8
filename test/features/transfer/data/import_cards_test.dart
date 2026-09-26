import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRANSFER-001 steps 5-7, E3-E5: the preview reads the deck; the commit
// classifies again and writes in one transaction (BR-TRANSFER-001,
// BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005; transfer spec §7).
// The store side of IT-CARD-014 steps 1-4 and IT-CARD-015 steps 1-4.

DateTime _now() => DateTime(2026, 9, 26, 10);

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

(int, int, int, int) _counts(ImportResult result) => (
  result.added,
  result.skippedDuplicates,
  result.skippedInvalid,
  result.ignoredBlank,
);

Matcher _imported((int, int, int, int) counts) =>
    isA<Ok<ImportResult, TransferRejection>>().having(
      (ok) => _counts(ok.value),
      'added, duplicates, invalid, blank',
      counts,
    );

Matcher _refused(TransferRejection reason) =>
    isA<Rejected<ImportResult, TransferRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

/// Fails the first tag link, after every card and schedule row of the
/// import is written (UC-TRANSFER-001 E5).
final class _FailingTagLinks extends QueryInterceptor {
  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('card_tags')) throw StateError('disk full');
    return super.runInsert(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TransferRepositoryImpl transfer;
  late DeckEntity root;
  late DeckEntity leaf;

  Future<void> open(AppDatabase database) async {
    db = database;
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    transfer = TransferRepositoryImpl(db, cards, now: _now);
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() => db.close());

  Future<List<String>> frontsInCreationOrder() async => [
    for (final row
        in await db
            .customSelect('SELECT front FROM card ORDER BY created_at, id')
            .get())
      row.read<String>('front'),
  ];

  Future<DeckContentType> contentTypeOf(String deckId) async =>
      (await decks.findById(deckId))!.contentType;

  test('an import writes its ready rows, each with one schedule row and its '
      'tags, and the unset deck becomes a deck of cards '
      '(BR-TRANSFER-004, BR-TRANSFER-005)', () async {
    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back', 'tags'],
        ['tip', 'tiền boa', 'noun'],
        ['bill', 'hóa đơn', ''],
        ['', '', ''],
        ['menu', '', 'noun'],
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((2, 0, 1, 1)));
    expect(await frontsInCreationOrder(), ['tip', 'bill']);
    final schedules = await db
        .customSelect('SELECT scheduler_type, learned_at FROM card_schedule')
        .get();
    expect(
      [for (final row in schedules) row.read<String>('scheduler_type')],
      ['eight_box', 'eight_box'],
    );
    expect(schedules.every((row) => row.data['learned_at'] == null), isTrue);
    final links = await db
        .customSelect(
          'SELECT c.front, t.name FROM card_tags ct '
          'JOIN card c ON c.id = ct.card_id JOIN tags t ON t.id = ct.tag_id',
        )
        .get();
    expect(
      [
        for (final row in links)
          '${row.read<String>('front')}:${row.read<String>('name')}',
      ],
      ['tip:noun'],
    );
    expect(await contentTypeOf(leaf.id), DeckContentType.card);
  });

  test('a tags cell typed by hand: spaces around the names, the library\'s '
      'tag in another case, a comma inside a name (BR-TRANSFER-009, '
      'BR-TAG-001)', () async {
    final other = await decks.sub(root.id, 'o');
    await cards.createCard(
      deckId: other.id,
      draft: const CardDraft(front: 'x', back: 'y', tagNames: ['noun']),
      now: DateTime(2026, 9, 25),
    );

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back', 'tags'],
        ['tip', 'tiền boa', ' Noun ; verb, adj '],
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((1, 0, 0, 0)));
    final tags = await db
        .customSelect('SELECT name FROM tags ORDER BY name_folded')
        .get();
    expect(
      [for (final row in tags) row.read<String>('name')],
      ['noun', 'verb, adj'],
    );
    final links = await db
        .customSelect(
          'SELECT t.name FROM card_tags ct JOIN card c ON c.id = ct.card_id '
          "JOIN tags t ON t.id = ct.tag_id WHERE c.front = 'tip' "
          'ORDER BY t.name_folded',
        )
        .get();
    expect(
      [for (final row in links) row.read<String>('name')],
      ['noun', 'verb, adj'],
    );
  });

  test('the preview reads the deck as it is and writes nothing: a card in the '
      'Trash, or in another deck, is no duplicate (BR-TRANSFER-003)', () async {
    final other = await decks.sub(root.id, 'o');
    await cards.createCards(
      deckId: leaf.id,
      drafts: const [
        CardDraft(front: 'tip', back: 'tiền boa'),
        CardDraft(front: 'bill', back: 'hóa đơn'),
      ],
    );
    await cards.createCard(
      deckId: other.id,
      draft: const CardDraft(front: 'menu', back: 'thực đơn'),
    );
    final bill = await db
        .customSelect("SELECT id FROM card WHERE front = 'bill'")
        .getSingle();
    await trashCardRow(db, bill.read<String>('id'));
    final before = await totalChanges(db);

    final preview = await transfer.previewImport(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['TIP', 'Tiền boa'],
        ['bill', 'hóa đơn'],
        ['menu', 'thực đơn'],
      ]),
      settings: const ImportSettings(),
    );

    expect(
      [for (final row in preview.rows) row.runtimeType],
      [ImportRowDuplicate, ImportRowReady, ImportRowReady],
    );
    expect(await totalChanges(db), before);
  });

  test('the commit classifies again: a card written after the preview is '
      'skipped as a duplicate (BR-TRANSFER-003)', () async {
    final sheet = _sheet([
      ['front', 'back'],
      ['tip', 'tiền boa'],
      ['bill', 'hóa đơn'],
    ]);
    final preview = await transfer.previewImport(
      deckId: leaf.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );
    expect(preview.writeCount, 2);
    await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: 'Tip', back: 'Tiền boa'),
      now: DateTime(2026, 9, 25),
    );

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );

    expect(result, _imported((1, 1, 0, 0)));
    expect(await frontsInCreationOrder(), ['Tip', 'bill']);
  });

  test('duplicates included are written as new cards, the deck\'s copy and '
      'repeated rows alike (UC-TRANSFER-001 A4)', () async {
    await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: 'tip', back: 'tiền boa'),
      now: DateTime(2026, 9, 25),
    );

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['tip', 'tiền boa'],
        ['bill', 'hóa đơn'],
        ['bill', 'hóa đơn'],
      ]),
      settings: const ImportSettings(shouldIncludeDuplicates: true),
    );

    expect(result, _imported((3, 0, 0, 0)));
    expect(await frontsInCreationOrder(), ['tip', 'tip', 'bill', 'bill']);
  });

  test(
    'a deck that is gone, in the Trash, a root or holding sub-decks '
    'refuses the import, which writes nothing (E4, BR-TRANSFER-001)',
    () async {
      final mid = await decks.sub(root.id, 'mid');
      await decks.sub(mid.id, 'inner');
      final trashed = await decks.sub(root.id, 't');
      await trashDeckRows(db, trashed.id);
      final sheet = _sheet([
        ['front', 'back'],
        ['tip', 'tiền boa'],
      ]);
      final before = await totalChanges(db);

      for (final (deckId, reason) in [
        ('missing', TransferRejection.deckNotFound),
        (trashed.id, TransferRejection.deckNotFound),
        (root.id, TransferRejection.deckRejectsCards),
        (mid.id, TransferRejection.deckRejectsCards),
      ]) {
        expect(
          await transfer.importCards(
            deckId: deckId,
            sheet: sheet,
            settings: const ImportSettings(),
          ),
          _refused(reason),
          reason: deckId,
        );
      }
      expect(await totalChanges(db), before);
    },
  );

  test('with nothing to write nothing is written, and an unset deck stays '
      'unset (E3, BR-TRANSFER-004, BR-TRANSFER-005)', () async {
    final before = await totalChanges(db);

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['tip', ''],
        [' ', ' '],
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((0, 0, 1, 1)));
    expect(await totalChanges(db), before);
    expect(await contentTypeOf(leaf.id), DeckContentType.unset);
  });

  test('without front or back mapped the import is refused and writes '
      'nothing (BR-TRANSFER-002)', () async {
    final before = await totalChanges(db);

    expect(
      await transfer.importCards(
        deckId: leaf.id,
        sheet: _sheet([
          ['term', 'meaning'],
          ['tip', 'tiền boa'],
        ]),
        settings: const ImportSettings(),
      ),
      _refused(TransferRejection.mappingIncomplete),
    );
    expect(await totalChanges(db), before);
  });

  test('a failure in the middle rolls the whole import back: no card, no '
      'schedule, no tag, and the deck stays unset (E5)', () async {
    await db.close();
    await open(openTestDatabase(interceptor: _FailingTagLinks()));

    await expectLater(
      transfer.importCards(
        deckId: leaf.id,
        sheet: _sheet([
          ['front', 'back', 'tags'],
          ['tip', 'tiền boa', ''],
          ['bill', 'hóa đơn', 'noun'],
        ]),
        settings: const ImportSettings(),
      ),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    for (final table in ['card', 'card_schedule', 'tags', 'card_tags']) {
      final rows = await db.customSelect('SELECT * FROM $table').get();
      expect(rows, isEmpty, reason: table);
    }
    expect(await contentTypeOf(leaf.id), DeckContentType.unset);
  });

  test('1,500 rows keep the file\'s order: learning takes them in it, and '
      'the card list shows the newest, the last row, first (D11)', () async {
    final rows = [
      for (var i = 1; i <= 1500; i++)
        ['w${i.toString().padLeft(4, '0')}', 'meaning $i'],
    ];

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ...rows,
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((1500, 0, 0, 0)));
    final fronts = [for (final row in rows) row.first];
    expect(await frontsInCreationOrder(), fronts);
    final byId = {
      for (final row
          in await db.customSelect('SELECT id, front FROM card').get())
        row.read<String>('id'): row.read<String>('front'),
    };
    final learning = await StudySessionDao(db).newCards(leaf.id);
    expect([for (final card in learning) byId[card.cardId]], fronts);
    final list = await cards
        .watchCardList(
          deckId: leaf.id,
          query: const CardListQuery(),
          windowSize: 5,
          now: _now(),
        )
        .first;
    expect(
      [for (final item in list.items) item.front],
      ['w1500', 'w1499', 'w1498', 'w1497', 'w1496'],
    );
  });
}
