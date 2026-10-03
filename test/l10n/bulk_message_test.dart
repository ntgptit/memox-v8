import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('a bulk toast is the message alone when nothing was skipped', () {
    expect(en.bulkToast('2 cards moved to Verbs', 0), '2 cards moved to Verbs');
  });

  test('it adds how many were already gone, as a plural', () {
    expect(
      en.bulkToast('2 cards moved to Verbs', 1),
      '2 cards moved to Verbs. 1 was already gone.',
    );
    expect(
      en.bulkToast('2 cards moved to Verbs', 3),
      '2 cards moved to Verbs. 3 were already gone.',
    );
  });

  test('the Vietnamese copy carries the same count', () {
    expect(
      vi.bulkToast('Đã chuyển 2 thẻ vào Verbs', 3),
      'Đã chuyển 2 thẻ vào Verbs. 3 thẻ đã không còn.',
    );
  });

  test('when every selected card is gone the copy says nothing changed', () {
    expect(
      en.cardBulkAllGone(3),
      'The 3 selected cards are already gone. Nothing changed.',
    );
    expect(
      vi.cardBulkAllGone(3),
      '3 thẻ đã chọn đều đã không còn. Chưa có gì thay đổi.',
    );
  });
}
