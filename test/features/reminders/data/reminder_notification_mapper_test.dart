import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/data/mappers/reminder_notification_mapper.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

void main() {
  const korean = ReminderDigest(
    deckName: 'Korean',
    dueCount: 86,
    otherDeckCount: 2,
  );

  test('the kit\'s sentence, in English (reminders spec D9)', () {
    expect(
      reminderNotificationBody(korean, const Locale('en')),
      '86 cards are due in Korean, and 2 other decks have cards waiting.',
    );
  });

  test('one card and no other deck says so, in the singular', () {
    const one = ReminderDigest(
      deckName: 'Korean',
      dueCount: 1,
      otherDeckCount: 0,
    );
    expect(
      reminderNotificationBody(one, const Locale('en')),
      '1 card is due in Korean.',
    );
  });

  test('one other deck is singular too', () {
    const two = ReminderDigest(
      deckName: 'Korean',
      dueCount: 3,
      otherDeckCount: 1,
    );
    expect(
      reminderNotificationBody(two, const Locale('en')),
      '3 cards are due in Korean, and 1 other deck has cards waiting.',
    );
  });

  test('the same sentence in Vietnamese', () {
    expect(
      reminderNotificationBody(korean, const Locale('vi')),
      '86 thẻ đến hạn trong Korean, và 2 deck khác có thẻ đang chờ.',
    );
  });
}
