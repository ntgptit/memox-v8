import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

ImportPreview _preview(
  List<List<String>> rows, {
  bool hasHeaderRow = true,
  Set<({String front, String back})> existing = const {},
}) => buildImportPreview(
  table: SourceTable(rows: rows),
  mapping: hasHeaderRow
      ? ColumnMapping.fromHeader(rows.first)
      : const ColumnMapping({0: TransferField.front, 1: TransferField.back}),
  hasHeaderRow: hasHeaderRow,
  existing: existing,
);

void main() {
  test('each row gets one status, in order (UC-TRANSFER-001 step 5)', () {
    final preview = _preview(
      [
        ['front', 'back', 'tags'],
        ['menu', 'thực đơn', 'food; noun'],
        ['bill', '', ''],
        ['Reservation', 'Sự đặt chỗ', ''],
        ['', '  ', ''],
        ['menu ', ' Thực đơn', ''],
        ['a' * 61, 'too long', ''],
      ],
      existing: {(front: 'reservation', back: 'sự đặt chỗ')},
    );

    expect(preview.rows.map((row) => (row.rowNumber, row.kind)), [
      (2, ImportRowKind.ready),
      (3, ImportRowKind.invalid),
      (4, ImportRowKind.duplicateInDeck),
      (5, ImportRowKind.blank),
      (6, ImportRowKind.duplicateInSource),
      (7, ImportRowKind.invalid),
    ]);
    expect(preview.rows[1].reason, CardRejection.blankContent);
    expect(preview.rows[4].firstRowNumber, 2);
    expect(preview.rows[5].reason, CardRejection.frontTooLong);
    expect(preview.rows[0].draft!.tagNames, ['food', 'noun']);
    expect(
      (
        preview.total,
        preview.ready,
        preview.invalid,
        preview.duplicates,
        preview.blank,
      ),
      (6, 1, 2, 2, 1),
    );
  });

  test('duplicates are skipped by default and written with Include duplicates (A4)', () {
    final preview = _preview([
      ['front', 'back'],
      ['a', 'b'],
      ['A', 'B'],
    ]);

    expect(preview.willWrite(includeDuplicates: false), 1);
    expect(preview.willWrite(includeDuplicates: true), 2);
    expect(
      preview
          .draftsToWrite(includeDuplicates: true)
          .map((draft) => draft.front),
      ['a', 'A'],
    );
  });

  test('an invalid row never shadows a later valid one as its duplicate', () {
    final preview = _preview([
      ['front', 'back', 'tags'],
      ['a', 'b', List.filled(11, 't').indexed.map((e) => 't${e.$1}').join(';')],
      ['a', 'b', ''],
    ]);

    expect(preview.rows.map((row) => row.kind), [
      ImportRowKind.invalid,
      ImportRowKind.ready,
    ]);
    expect(preview.rows.first.reason, CardRejection.tooManyTags);
  });

  test('without a header row the first row is data (A3)', () {
    final preview = _preview([
      ['a', 'b'],
      ['c', 'd'],
    ], hasHeaderRow: false);

    expect(preview.rows.map((row) => row.rowNumber), [1, 2]);
    expect(preview.ready, 2);
  });

  test('a source whose data rows are all blank is empty (E2)', () {
    expect(
      _preview([
        ['front', 'back'],
        ['', ''],
      ]).isEmpty,
      isTrue,
    );
    expect(
      _preview([
        ['front', 'back'],
      ]).isEmpty,
      isTrue,
    );
  });

  test('a short row reads its missing cells as empty', () {
    final preview = _preview([
      ['front', 'back', 'hint'],
      ['a', 'b'],
    ]);

    expect(preview.rows.single.kind, ImportRowKind.ready);
    expect(preview.rows.single.draft!.hint, isNull);
  });
}
