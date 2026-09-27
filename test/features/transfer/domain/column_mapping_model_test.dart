import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';

void main() {
  test('a header equal to a canonical name after the fold maps to it (UC-TRANSFER-001 step 4)', () {
    final mapping = ColumnMapping.fromHeader([
      ' Front',
      'BACK',
      'notes',
      'Tags',
    ]);

    expect(mapping.fieldByColumn, {
      0: TransferField.front,
      1: TransferField.back,
      3: TransferField.tags,
    });
    expect(mapping.isComplete, isTrue);
  });

  test('nothing else is guessed: term and meaning stay unmapped', () {
    final mapping = ColumnMapping.fromHeader(['term', 'meaning']);

    expect(mapping.fieldByColumn, isEmpty);
    expect(mapping.isComplete, isFalse);
  });

  test('the first column wins a field named twice', () {
    expect(ColumnMapping.fromHeader(['front', 'front', 'back']).fieldByColumn, {
      0: TransferField.front,
      2: TransferField.back,
    });
  });

  test('a field takes one column: assigning it elsewhere moves it (BR-TRANSFER-002)', () {
    final mapping = ColumnMapping.fromHeader(['front', 'back', 'x'])
        .assign(2, TransferField.back);

    expect(mapping.fieldByColumn, {
      0: TransferField.front,
      2: TransferField.back,
    });
    expect(mapping.assign(0, null).isComplete, isFalse);
  });

  test(
    'columns are named A, B … Z, AA, AB when the first row is data (A3)',
    () {
      expect([0, 1, 25, 26, 27, 51, 52].map(columnLetter), [
        'A',
        'B',
        'Z',
        'AA',
        'AB',
        'AZ',
        'BA',
      ]);
    },
  );
}
