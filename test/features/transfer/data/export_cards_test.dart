import 'dart:convert';

import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRANSFER-002: one snapshot of a deck's cards, written as a CSV or TSV
// file, read-only (BR-TRANSFER-007…BR-TRANSFER-013; transfer spec §8).

DateTime _now() => DateTime(2026, 9, 26, 10);

const _utf8Bom = [0xEF, 0xBB, 0xBF];

/// The file's text after the UTF-8 BOM that starts every export (transfer
/// spec D14). `utf8.decode` would drop the BOM silently, so its bytes are
/// checked here.
String _text(ExportFile file) {
  expect(file.bytes.take(_utf8Bom.length), _utf8Bom);
  return utf8.decode(file.bytes.skip(_utf8Bom.length).toList());
}

Matcher _refused(TransferRejection reason) =>
    isA<Rejected<ExportFile, TransferRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

ExportFile _file(Outcome<ExportFile, TransferRejection> result) =>
    (result as Ok<ExportFile, TransferRejection>).value;

/// Fails every read once [isFailing] is set (UC-TRANSFER-002 E3).
final class _FailingReads extends QueryInterceptor {
  bool isFailing = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isFailing) throw StateError('disk I/O error');
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TransferRepositoryImpl transfer;
  late DeckEntity root;
  late DeckEntity deck;

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
    deck = await decks.sub(root.id, 'Nhà hàng');
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() => db.close());

  /// A card of [deckId] created on day [day] of September.
  Future<String> card(int day, CardDraft draft, {String? deckId}) async {
    final result = await cards.createCard(
      deckId: deckId ?? deck.id,
      draft: draft,
      now: DateTime(2026, 9, day),
    );
    return switch (result) {
      Ok(:final value) => value.id,
      Rejected(:final reason) => throw StateError('fixture card: $reason'),
    };
  }

  Future<Outcome<ExportFile, TransferRejection>> export(
    ExportScope scope, [
    TransferFormat format = TransferFormat.csv,
  ]) => transfer.exportCards(
    deckId: deck.id,
    scope: scope,
    format: format,
    now: _now(),
  );

  test('a CSV file: a BOM, the six canonical headers, then a CRLF record a '
      'card, oldest first, with empty cells, quotes where a cell needs them '
      'and tags by folded name (BR-TRANSFER-008, BR-TRANSFER-010, '
      'BR-TRANSFER-012)', () async {
    await card(
      3,
      const CardDraft(
        front: 'say "hi"',
        back: 'line 1\nline 2',
        example: 'a, b',
      ),
    );
    await card(
      1,
      const CardDraft(
        front: 'tip',
        back: 'tiền boa',
        pronunciation: '/tɪp/',
        tagNames: ['verb', 'Noun', r'a;b\c'],
      ),
    );
    await card(2, const CardDraft(front: '=1+1', back: '001'));

    final file = _file(await export(const ExportAllCards()));

    expect(
      _text(file),
      'front,back,example,hint,pronunciation,tags\r\n'
      'tip,tiền boa,,,/tɪp/,a\\;b\\\\c;Noun;verb\r\n'
      '=1+1,001,,,,\r\n'
      '"say ""hi""","line 1\nline 2","a, b",,,\r\n',
    );
    expect(
      (file.fileName, file.mimeType, file.cardCount),
      ('Nhà hàng 2026-09-26.csv', 'text/csv', 3),
    );
  });

  test('a TSV file is split by tabs and quotes a cell holding one', () async {
    await card(1, const CardDraft(front: 'a\tb', back: 'c, d'));

    final file = _file(
      await export(const ExportAllCards(), TransferFormat.tsv),
    );

    expect(
      _text(file),
      'front\tback\texample\thint\tpronunciation\ttags\r\n'
      '"a\tb"\tc, d\t\t\t\t\r\n',
    );
    expect(
      (file.fileName, file.mimeType),
      ('Nhà hàng 2026-09-26.tsv', 'text/tab-separated-values'),
    );
  });

  test('all is every active card of the deck itself, whatever the list '
      'shows: not those in the Trash, not another deck\'s '
      '(BR-TRANSFER-007)', () async {
    final other = await decks.sub(root.id, 'o');
    await card(1, const CardDraft(front: 'kept', back: 'x'));
    final trashed = await card(2, const CardDraft(front: 'trashed', back: 'x'));
    await trashCardRow(db, trashed);
    await card(
      3,
      const CardDraft(front: 'elsewhere', back: 'x'),
      deckId: other.id,
    );

    final file = _file(await export(const ExportAllCards()));

    expect(file.cardCount, 1);
    expect(_text(file), contains('kept'));
    expect(_text(file), isNot(contains('trashed')));
    expect(_text(file), isNot(contains('elsewhere')));
  });

  test('selected is those cards, oldest first whatever the set\'s order '
      '(BR-TRANSFER-007, BR-TRANSFER-010)', () async {
    final third = await card(3, const CardDraft(front: 'c3', back: 'x'));
    await card(2, const CardDraft(front: 'c2', back: 'x'));
    final first = await card(1, const CardDraft(front: 'c1', back: 'x'));

    final file = _file(await export(ExportSelectedCards({third, first})));

    expect(file.cardCount, 2);
    expect(
      _text(file).split('\r\n').skip(1).map((line) => line.split(',').first),
      ['c1', 'c3', ''],
    );
  });

  test(
    'a selected card sent to the Trash, moved or gone fails the whole '
    'export, and so does an empty selection (UC-TRANSFER-002 E5, E6)',
    () async {
      final other = await decks.sub(root.id, 'o');
      final kept = await card(1, const CardDraft(front: 'kept', back: 'x'));
      final trashed = await card(
        2,
        const CardDraft(front: 'trashed', back: 'x'),
      );
      await trashCardRow(db, trashed);
      final moved = await card(3, const CardDraft(front: 'moved', back: 'x'));
      await cards.moveCards(cardIds: {moved}, targetDeckId: other.id);

      for (final stale in [trashed, moved, 'missing']) {
        expect(
          await export(ExportSelectedCards({kept, stale})),
          _refused(TransferRejection.staleSelection),
          reason: stale,
        );
      }
      expect(
        await export(const ExportSelectedCards({})),
        _refused(TransferRejection.emptyScope),
      );
    },
  );

  test('a deck with no card is emptyScope; one that is gone or in the Trash '
      'is deckNotFound (UC-TRANSFER-002 E5)', () async {
    expect(
      await export(const ExportAllCards()),
      _refused(TransferRejection.emptyScope),
    );
    expect(
      await transfer.exportCards(
        deckId: root.id,
        scope: const ExportAllCards(),
        format: TransferFormat.csv,
        now: _now(),
      ),
      _refused(TransferRejection.emptyScope),
    );
    await trashDeckRows(db, deck.id);
    expect(
      await export(const ExportAllCards()),
      _refused(TransferRejection.deckNotFound),
    );
    expect(
      await transfer.exportCards(
        deckId: 'missing',
        scope: const ExportAllCards(),
        format: TransferFormat.csv,
        now: _now(),
      ),
      _refused(TransferRejection.deckNotFound),
    );
  });

  test('a read that fails leaves as a database Failure, with no file '
      '(UC-TRANSFER-002 E3)', () async {
    final reads = _FailingReads();
    await db.close();
    await open(openTestDatabase(interceptor: reads));
    await card(1, const CardDraft(front: 'tip', back: 'tiền boa'));
    reads.isFailing = true;

    await expectLater(
      export(const ExportAllCards()),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });

  test('an export writes nothing (BR-TRANSFER-011)', () async {
    final id = await card(
      1,
      const CardDraft(front: 'a', back: 'b', tagNames: ['t']),
    );
    final before = await totalChanges(db);

    await export(const ExportAllCards());
    await export(ExportSelectedCards({id}), TransferFormat.tsv);

    expect(await totalChanges(db), before);
  });

  test('the file imported back into its own deck adds nothing: each row is '
      'a duplicate in the deck (BR-TRANSFER-003)', () async {
    await card(
      1,
      const CardDraft(front: 'tip', back: 'tiền boa', tagNames: ['noun']),
    );
    await card(2, const CardDraft(front: 'bill', back: 'hóa, đơn'));
    final file = _file(await export(const ExportAllCards()));
    final document = await transfer.readSource(
      ImportFile(name: file.fileName, bytes: file.bytes),
    );
    final sheet =
        (document as Ok<ImportDocument, TransferRejection>).value.sheets.single;
    final before = await totalChanges(db);

    final preview = await transfer.previewImport(
      deckId: deck.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );
    final result = await transfer.importCards(
      deckId: deck.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );

    expect((preview.duplicateCount, preview.writeCount), (2, 0));
    expect(
      (result as Ok<ImportResult, TransferRejection>).value.skippedDuplicates,
      2,
    );
    expect(result.value.added, 0);
    expect(await totalChanges(db), before);
  });

  test('a round trip: the file imported into an empty deck gives the same '
      'six fields, tag sets and order (BR-TRANSFER-009)', () async {
    for (final (day, draft) in [
      (
        1,
        const CardDraft(
          front: 'tip',
          back: 'tiền boa',
          tagNames: ['Noun', r'x\;y'],
        ),
      ),
      (
        2,
        const CardDraft(
          front: 'bill',
          back: 'hóa, đơn',
          example: '"quoted"',
          hint: 'h',
        ),
      ),
      (
        3,
        const CardDraft(
          front: 'menu',
          back: 'thực\nđơn',
          pronunciation: 'p',
          tagNames: ['a;b'],
        ),
      ),
    ]) {
      await card(day, draft);
    }
    final copy = await decks.sub(root.id, 'copy');

    for (final format in TransferFormat.values) {
      final file = _file(await export(const ExportAllCards(), format));
      final document = await transfer.readSource(
        ImportFile(name: file.fileName, bytes: file.bytes),
      );
      final sheet = (document as Ok<ImportDocument, TransferRejection>)
          .value
          .sheets
          .single;
      await transfer.importCards(
        deckId: copy.id,
        sheet: sheet,
        settings: const ImportSettings(shouldIncludeDuplicates: true),
      );
      final copied = _file(
        await transfer.exportCards(
          deckId: copy.id,
          scope: const ExportAllCards(),
          format: format,
          now: _now(),
        ),
      );
      final records = _text(copied).split('\r\n');
      expect(
        records.skip(1).take(3).toList(),
        _text(file).split('\r\n').skip(1).take(3).toList(),
        reason: format.name,
      );
      await db.customStatement('DELETE FROM card WHERE deck_id = ?', [copy.id]);
    }
  });
}
