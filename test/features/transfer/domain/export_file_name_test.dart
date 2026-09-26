import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

// UC-TRANSFER-002 step 5: the file's name, from the deck's name and the
// day (BR-TRANSFER-013; transfer spec D15).

final _day = DateTime(2026, 9, 26, 23, 59);

String _nameOf(String deckName, [TransferFormat format = TransferFormat.csv]) =>
    exportFileName(deckName: deckName, now: _day, format: format);

void main() {
  test(
    'the deck keeps its spelling; the local day and the extension follow',
    () {
      expect(_nameOf('Nhà hàng'), 'Nhà hàng 2026-09-26.csv');
      expect(_nameOf('명사', TransferFormat.tsv), '명사 2026-09-26.tsv');
      expect(
        exportFileName(
          deckName: 'x',
          now: DateTime(2026, 1, 5),
          format: TransferFormat.csv,
        ),
        'x 2026-01-05.csv',
      );
    },
  );

  test('path separators, characters no file system takes and control '
      'characters go; whitespace runs become one space', () {
    expect(_nameOf(r'a/b\c:d*e?f"g<h>i|j'), 'abcdefghij 2026-09-26.csv');
    expect(_nameOf('a\u0000b\u007Fc\u009Fd'), 'abcd 2026-09-26.csv');
    expect(_nameOf('Nhà \t\n  hàng'), 'Nhà hàng 2026-09-26.csv');
    expect(_nameOf('a / b'), 'a b 2026-09-26.csv');
  });

  test('leading and trailing spaces and dots go, and a name with nothing '
      'left is cards', () {
    expect(_nameOf(' . .hidden. . '), 'hidden 2026-09-26.csv');
    expect(_nameOf('/:*?'), 'cards 2026-09-26.csv');
    expect(_nameOf('  ...  '), 'cards 2026-09-26.csv');
  });

  test('the name is cut to 200 UTF-8 bytes on a whole character', () {
    for (final grapheme in ['Ệ', '😀', 'é', '👨‍👩‍👧']) {
      final name = _nameOf('a${grapheme * 200}');
      final kept = name.substring(0, name.length - ' 2026-09-26.csv'.length);

      expect(
        utf8.encode(kept).length,
        lessThanOrEqualTo(200),
        reason: grapheme,
      );
      expect(
        utf8.encode('$kept$grapheme').length,
        greaterThan(200),
        reason: grapheme,
      );
      expect(
        kept.characters.skip(1).every((each) => each == grapheme),
        isTrue,
        reason: grapheme,
      );
    }
  });
}
