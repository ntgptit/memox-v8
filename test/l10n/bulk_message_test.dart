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

  test('a message that ends in a period does not double it', () {
    expect(
      en.bulkToast(en.exportHandedOver(3), 1),
      'Handed 3 cards to the system. 1 was already gone.',
    );
    expect(
      vi.bulkToast(vi.exportHandedOver(3), 2),
      'Đã giao 3 thẻ cho hệ thống. 2 thẻ đã không còn.',
    );
  });

  test('no bulk message, in either language, joins its note with ".."', () {
    for (final l10n in [en, vi]) {
      for (final message in [
        l10n.cardMovedToast(2, 'Verbs'),
        l10n.cardFlaggedToast(2),
        l10n.cardTaggedToast(2, 'greetings'),
        l10n.cardsTrashedToast(2),
        l10n.exportHandedOver(2),
        l10n.importUndoneToast(2),
      ]) {
        expect(l10n.bulkToast(message, 1), isNot(contains('..')));
        expect(l10n.bulkToast(message, 3), isNot(contains('..')));
      }
    }
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
