import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

void main() {
  test('a file name ends in the format it is read as, ignoring case (E1)', () {
    expect(TransferFormat.ofFileName('vocab.XLSX'), TransferFormat.xlsx);
    expect(TransferFormat.ofFileName('a.b.tsv'), TransferFormat.tsv);
    expect(TransferFormat.ofFileName('deck.apkg'), isNull);
    expect(TransferFormat.ofFileName('noextension'), isNull);
  });
}
