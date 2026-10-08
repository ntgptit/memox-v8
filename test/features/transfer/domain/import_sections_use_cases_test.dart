import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The sectioned import use cases over the real repositories (spec 2026-10-08,
// UC-TRANSFER-001 A6, E7, E9).

DateTime _now() => DateTime(2026, 9, 26);

T _ok<T>(Outcome<T, TransferRejection> result) =>
    (result as Ok<T, TransferRejection>).value;

TransferRejection _reason(Outcome<Object?, TransferRejection> result) =>
    (result as Rejected<Object?, TransferRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardTransferRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  const files = TransferFileRepositoryImpl();
  late ReadImportSourceUseCase read;
  late PreviewImportUseCase preview;
  late CommitImportUseCase commit;
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
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    read = const ReadImportSourceUseCase(files);
    preview = PreviewImportUseCase(cards);
    commit = CommitImportUseCase(cards);
  });
  tearDown(() => db.close());

  const faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});
  const sheet = 'Term,Meaning\n*Part 1,\na,b\nc,d\n*관용어,\ne,f\n';

  Future<ImportPlan> planOf(String deckId, String text) async {
    final table = _ok(await read(PastedSource(text)));
    return _ok(
      await preview(
        deckId: deckId,
        table: table,
        mapping: faces,
        hasHeaderRow: true,
      ),
    );
  }

  test('a sectioned file from a root makes its decks (A6)', () async {
    final plan = await planOf(root.id, sheet);
    final rows = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {},
    );

    final summary = _ok(
      await commit(deckId: root.id, preview: rows, includeDuplicates: false),
    );

    expect(summary.written, 3);
    expect(
      [for (final d in summary.decks) (d.name, d.isNew, d.written)],
      [('Part 1', true, 2), ('관용어', true, 1)],
    );
  });

  test('sections from a deck of cards are refused at preview (E7)', () async {
    await insertCard(db, id: 'x', deckId: leaf.id, front: 'a', back: 'b');
    final table = _ok(await read(const PastedSource(sheet)));

    expect(
      _reason(
        await preview(
          deckId: leaf.id,
          table: table,
          mapping: faces,
          hasHeaderRow: true,
        ),
      ),
      TransferRejection.sectionsNeedDeckContainer,
    );
  });

  test('an undecided clash refuses the commit (U6)', () async {
    await decks.sub(root.id, 'Part 1');
    final plan = await planOf(root.id, sheet);
    final rows = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {},
    );

    expect(
      _reason(
        await commit(deckId: root.id, preview: rows, includeDuplicates: false),
      ),
      TransferRejection.sectionChoiceMissing,
    );
  });

  test('a chosen deck that moved before the commit refuses it, nothing '
      'written (E9)', () async {
    final part = await decks.sub(root.id, 'Part 1');
    final plan = await planOf(root.id, sheet);
    final rows = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {0: ImportSectionChoice.addToExisting},
    );
    final other = await decks.root('Other');
    await decks.moveDeck(deckId: part.id, newParentId: other.id);

    expect(
      _reason(
        await commit(deckId: root.id, preview: rows, includeDuplicates: false),
      ),
      TransferRejection.sectionTargetChanged,
    );
    expect(
      (await db.customSelect('SELECT COUNT(*) AS n FROM card').getSingle())
          .read<int>('n'),
      0,
    );
  });

  test('a flat file from a root goes into one default deck (§4.2)', () async {
    final plan = await planOf(root.id, 'Term,Meaning\na,b\n');
    final summary = _ok(
      await commit(
        deckId: root.id,
        preview: plan.preview(
          defaultDeckName: 'Uncategorized',
          choices: const {},
        ),
        includeDuplicates: false,
      ),
    );

    expect(
      [for (final d in summary.decks) (d.name, d.written)],
      [('Uncategorized', 1)],
    );
  });

  test(
    'sections into a deck at level 10 are refused at preview (E8)',
    () async {
      var deepest = leaf;
      for (var level = 3; level <= DeckEntity.maxDepth; level++) {
        deepest = await decks.sub(deepest.id, 'L$level');
      }
      final table = _ok(await read(const PastedSource(sheet)));

      expect(
        _reason(
          await preview(
            deckId: deepest.id,
            table: table,
            mapping: faces,
            hasHeaderRow: true,
          ),
        ),
        TransferRejection.depthExceeded,
      );
    },
  );
}
