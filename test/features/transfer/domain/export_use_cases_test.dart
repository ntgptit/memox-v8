import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/build_export_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The export use case runs over the real repositories, and its file is read
// back through the import use cases (UC-TRANSFER-002).

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
  late BuildExportUseCase export;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardTransferRepositoryImpl(
      db,
      CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: _now),
        TagRepositoryImpl(db, now: _now),
        now: _now,
      ),
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    read = const ReadImportSourceUseCase(files);
    preview = PreviewImportUseCase(cards);
    export = BuildExportUseCase(cards, files);
  });
  tearDown(() => db.close());

  group('export (UC-TRANSFER-002)', () {
    test('a deck exports, and importing the file into an empty deck gives the same content', () async {
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: '=1+1',
        back: '001',
        example: 'e, "q"',
        createdAt: DateTime(2026, 9, 1),
      );
      await insertCard(
        db,
        id: 'b',
        deckId: leaf.id,
        front: 'b',
        back: 'x\ny',
        createdAt: DateTime(2026, 9, 2),
      );
      await TagRepositoryImpl(
        db,
        now: _now,
      ).replaceForCard(cardId: 'a', names: ['a;b', r'c\d'], now: _now());
      final target = await decks.sub(root.id, 'copy');

      for (final format in TransferFormat.values) {
        final artifact = _ok(
          await export(deckId: leaf.id, format: format, today: _now()),
        );
        expect(artifact.fileName, 'Nhà-hàng-2026-09-26.${format.extension}');

        final table = _ok(
          await read(FileSource(bytes: artifact.bytes, format: format)),
        );
        expect(table.rows, [
          ['front', 'back', 'example', 'hint', 'pronunciation', 'tags'],
          ['=1+1', '001', 'e, "q"', '', '', r'a\;b;c\\d'],
          ['b', 'x\ny', '', '', '', ''],
        ]);
        final rows = _ok(
          await preview(
            deckId: target.id,
            table: table,
            mapping: ColumnMapping.fromHeader(table.rows.first),
            hasHeaderRow: true,
          ),
        );
        expect(rows.rows.first.draft!.tagNames, ['a;b', r'c\d']);
      }
    });

    test(
      'the same deck exports the same CSV bytes twice (BR-TRANSFER-010)',
      () async {
        await insertCard(db, id: 'a', deckId: leaf.id);
        Future<Uint8List> bytes() async => _ok(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
          ),
        ).bytes;

        expect(await bytes(), await bytes());
        expect(
          utf8.decode((await bytes()).sublist(3)).split('\r\n').first,
          'front,back,example,hint,pronunciation,tags',
        );
      },
    );

    test('an empty deck, an empty selection and a stale selection are refused (E5, E6)', () async {
      expect(
        _reason(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
          ),
        ),
        TransferRejection.emptyScope,
      );
      expect(
        _reason(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
            cardIds: const {},
          ),
        ),
        TransferRejection.emptyScope,
      );
      await insertCard(db, id: 'a', deckId: leaf.id);
      expect(
        _reason(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
            cardIds: const {'a', 'gone'},
          ),
        ),
        TransferRejection.staleSelection,
      );
    });
  });
}
