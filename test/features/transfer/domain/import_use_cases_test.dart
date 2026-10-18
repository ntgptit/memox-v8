import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/transfer_fixtures.dart';

// The import use cases run over the real repositories, so each test asserts
// what the person sees (UC-TRANSFER-001).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardTransferRepositoryImpl cards;
  late DeckEntity leaf;
  const files = TransferFileRepositoryImpl();
  late ReadImportSourceUseCase read;
  late PreviewImportUseCase preview;
  late CommitImportUseCase commit;
  setUp(() async {
    (:db, :decks, :cards, root: _, :leaf) = await openTransferWorld();
    read = const ReadImportSourceUseCase(files);
    preview = PreviewImportUseCase(cards);
    commit = CommitImportUseCase(cards);
  });
  tearDown(() => db.close());

  Future<ImportPreview> previewOf(String text) async {
    final table = transferOk(await read(PastedSource(text)));
    return transferOk(
      await preview(
        deckId: leaf.id,
        table: table,
        mapping: ColumnMapping.fromHeader(table.rows.first),
        hasHeaderRow: true,
      ),
    ).preview(defaultDeckName: 'Uncategorized', choices: const {});
  }

  test('pasted rows become cards; the summary counts what was skipped (UC-TRANSFER-001)', () async {
    await insertCard(
      db,
      id: 'old',
      deckId: leaf.id,
      front: 'tip',
      back: 'tiền boa',
    );
    final rows = await previewOf(
      'front,back,tags\nmenu,thực đơn,food\nbill,,\ntip,tiền boa,\n,,\nmenu,thực đơn,\n',
    );

    final summary = transferOk(
      await commit(deckId: leaf.id, preview: rows, includeDuplicates: false),
    );

    expect(
      (
        summary.written,
        summary.duplicatesSkipped,
        summary.invalid,
        summary.blank,
      ),
      (1, 2, 1, 1),
    );
    expect(summary.kind, ImportSummaryKind.partial);
    // Each skipped row, in source order, with why (critique 2026-10-02, F4);
    // the blank row 5 is ignored, not listed.
    expect(
      [for (final row in summary.skipped) (row.rowNumber, row.kind)],
      [
        (3, ImportRowKind.invalid),
        (4, ImportRowKind.duplicateInDeck),
        (6, ImportRowKind.duplicateInSource),
      ],
    );
  });

  test('a clean source ends on success; a blank row alone does not make it partial', () async {
    final summary = transferOk(
      await commit(
        deckId: leaf.id,
        preview: await previewOf('front,back\na,b\n,\nc,d'),
        includeDuplicates: false,
      ),
    );

    expect(summary.kind, ImportSummaryKind.success);
  });

  test('a partial import with a commit-time duplicate and an invalid row: '
      'the counts are the list (final review)', () async {
    final rows = await previewOf('front,back\na,b\nc,\nd,e');
    await insertCard(db, id: 'raced', deckId: leaf.id, front: 'a', back: 'b');

    final summary = transferOk(
      await commit(deckId: leaf.id, preview: rows, includeDuplicates: false),
    );

    expect(summary.kind, ImportSummaryKind.partial);
    expect(
      [for (final row in summary.skipped) (row.rowNumber, row.kind)],
      [(2, ImportRowKind.duplicateInDeck), (3, ImportRowKind.invalid)],
    );
    expect(
      (summary.written, summary.duplicatesSkipped, summary.invalid),
      (1, 1, 1),
    );
  });

  test(
    'rows that became duplicates after the preview end on none (spec §8.1)',
    () async {
      final rows = await previewOf('front,back\na,b');
      await insertCard(db, id: 'raced', deckId: leaf.id, front: 'a', back: 'b');

      final summary = transferOk(
        await commit(deckId: leaf.id, preview: rows, includeDuplicates: false),
      );

      expect((summary.written, summary.kind), (0, ImportSummaryKind.none));
      // The commit's re-check names the row it dropped.
      expect(
        [for (final row in summary.skipped) (row.rowNumber, row.kind)],
        [(2, ImportRowKind.duplicateInDeck)],
      );
      expect(summary.duplicatesSkipped, 1);
    },
  );

  test('an unmapped face, and a preview with nothing to write, are refused before any write', () async {
    final table = transferOk(
      await read(const PastedSource('term,meaning\na,b')),
    );
    expect(
      transferReason(
        await preview(
          deckId: leaf.id,
          table: table,
          mapping: ColumnMapping.fromHeader(table.rows.first),
          hasHeaderRow: true,
        ),
      ),
      TransferRejection.mappingIncomplete,
    );

    final allInvalid = await previewOf('front,back\na,');
    expect(
      transferReason(
        await commit(
          deckId: leaf.id,
          preview: allInvalid,
          includeDuplicates: false,
        ),
      ),
      TransferRejection.nothingToImport,
    );
  });

  test('a header without data rows is an empty source (E2)', () async {
    final table = transferOk(await read(const PastedSource('front,back\n')));

    expect(
      transferReason(
        await preview(
          deckId: leaf.id,
          table: table,
          mapping: ColumnMapping.fromHeader(table.rows.first),
          hasHeaderRow: true,
        ),
      ),
      TransferRejection.emptySource,
    );
  });

  test(
    'a target that gained sub-decks after the preview is refused (E4)',
    () async {
      final rows = await previewOf('front,back\na,b');
      await decks.sub(leaf.id, 'child');

      expect(
        transferReason(
          await commit(
            deckId: leaf.id,
            preview: rows,
            includeDuplicates: false,
          ),
        ),
        TransferRejection.targetRejected,
      );
    },
  );
}
