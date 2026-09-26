import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/import_cards_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TRANSFER-001 and UC-TRANSFER-002: each use case passes its arguments
// to the repository.

DateTime _now() => DateTime(2026, 9, 26, 10);

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late TransferRepositoryImpl transfer;
  late DeckEntity leaf;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    transfer = TransferRepositoryImpl(db, cards, now: _now);
    leaf = await decks.sub((await decks.root('r')).id, 'l');
  });
  tearDown(() => db.close());

  test('PreviewImportUseCase previews the sheet against the deck', () async {
    await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: 'tip', back: 'tiền boa'),
    );

    final preview = await PreviewImportUseCase(transfer)(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['tip', 'tiền boa'],
        ['bill', 'hóa đơn'],
      ]),
    );

    expect((preview.duplicateCount, preview.readyCount), (1, 1));
  });

  test(
    'ImportCardsUseCase imports the sheet with the settings given',
    () async {
      final result = await ImportCardsUseCase(transfer)(
        deckId: leaf.id,
        sheet: _sheet([
          ['tip', 'tiền boa'],
        ]),
        settings: const ImportSettings(hasHeaderRow: false),
      );

      expect(
        result,
        isA<Ok<ImportResult, TransferRejection>>().having(
          (ok) => ok.value.added,
          'added',
          1,
        ),
      );
    },
  );

  test('ReadImportSourceUseCase reads a source through the repository, '
      'and passes its refusal through', () async {
    final read = ReadImportSourceUseCase(transfer);

    final document = await read(const PastedText('front\tback\ntip\ttiền boa'));

    expect(
      [
        for (final row
            in (document as Ok<ImportDocument, TransferRejection>)
                .value
                .sheets
                .single
                .rows)
          row.cells,
      ],
      [
        ['front', 'back'],
        ['tip', 'tiền boa'],
      ],
    );
    expect(
      await read(ImportFile(name: 'cards.pdf', bytes: Uint8List(0))),
      isA<Rejected<ImportDocument, TransferRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        TransferRejection.unsupportedFormat,
      ),
    );
  });
}
