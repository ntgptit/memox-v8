import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
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
import '../../../support/test_database.dart';

// The import use cases run over the real repositories, so each test asserts
// what the person sees (UC-TRANSFER-001).

DateTime _now() => DateTime(2026, 9, 26);

T _ok<T>(Outcome<T, TransferRejection> result) =>
    (result as Ok<T, TransferRejection>).value;

TransferRejection _reason(Outcome<Object?, TransferRejection> result) =>
    (result as Rejected<Object?, TransferRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  const files = TransferFileRepositoryImpl();
  late ReadImportSourceUseCase read;
  late PreviewImportUseCase preview;
  late CommitImportUseCase commit;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    read = const ReadImportSourceUseCase(files);
    preview = PreviewImportUseCase(cards);
    commit = CommitImportUseCase(cards);
  });
  tearDown(() => db.close());

  Future<ImportPreview> previewOf(String text) async {
    final table = _ok(await read(PastedSource(text)));
    return _ok(
      await preview(
        deckId: leaf.id,
        table: table,
        mapping: ColumnMapping.fromHeader(table.rows.first),
        hasHeaderRow: true,
      ),
    );
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

    final summary = _ok(
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
  });

  test('a clean source ends on success; a blank row alone does not make it partial', () async {
    final summary = _ok(
      await commit(
        deckId: leaf.id,
        preview: await previewOf('front,back\na,b\n,\nc,d'),
        includeDuplicates: false,
      ),
    );

    expect(summary.kind, ImportSummaryKind.success);
  });

  test(
    'rows that became duplicates after the preview end on none (spec §8.1)',
    () async {
      final rows = await previewOf('front,back\na,b');
      await insertCard(db, id: 'raced', deckId: leaf.id, front: 'a', back: 'b');

      final summary = _ok(
        await commit(deckId: leaf.id, preview: rows, includeDuplicates: false),
      );

      expect((summary.written, summary.kind), (0, ImportSummaryKind.none));
    },
  );

  test('an unmapped face, and a preview with nothing to write, are refused before any write', () async {
    final table = _ok(await read(const PastedSource('term,meaning\na,b')));
    expect(
      _reason(
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
      _reason(
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
    final table = _ok(await read(const PastedSource('front,back\n')));

    expect(
      _reason(
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
        _reason(
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
