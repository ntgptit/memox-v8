import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

String _name(String deckName, [TransferFormat format = TransferFormat.csv]) =>
    exportFileName(
      deckName: deckName,
      date: DateTime(2026, 9, 6),
      format: format,
    );

void main() {
  test('the sanitized deck name, the local date and the extension (BR-TRANSFER-013)', () {
    expect(_name('Nhà hàng'), 'Nhà-hàng-2026-09-06.csv');
    expect(
      _name('한국어 TOPIK I', TransferFormat.xlsx),
      '한국어-TOPIK-I-2026-09-06.xlsx',
    );
  });

  test(
    'separators, control and refused characters go; white space collapses',
    () {
      expect(
        _name(' a/b\\c:d*e?"f<g>h|i\tj\u0007k  '),
        'a-b-c-d-e-f-g-h-i-j-k-2026-09-06.csv',
      );
    },
  );

  test('a name that sanitizes to nothing becomes cards', () {
    expect(_name(' /\\: '), 'cards-2026-09-06.csv');
  });
}
