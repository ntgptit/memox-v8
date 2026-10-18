import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/reminders/data/mappers/reminder_notification_mapper.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';

void main() {
  // (digest, locale) -> the notification body.
  final bodies = [
    (
      name: "the kit's sentence, in English (reminders spec D9)",
      digest: const ReminderDigest(
        deckName: 'Korean',
        dueCount: 86,
        otherDeckCount: 2,
      ),
      locale: const Locale('en'),
      body: '86 cards are due in Korean, and 2 other decks have cards waiting.',
    ),
    (
      name: 'one card and no other deck says so, in the singular',
      digest: const ReminderDigest(
        deckName: 'Korean',
        dueCount: 1,
        otherDeckCount: 0,
      ),
      locale: const Locale('en'),
      body: '1 card is due in Korean.',
    ),
    (
      name: 'one other deck is singular too',
      digest: const ReminderDigest(
        deckName: 'Korean',
        dueCount: 3,
        otherDeckCount: 1,
      ),
      locale: const Locale('en'),
      body: '3 cards are due in Korean, and 1 other deck has cards waiting.',
    ),
    (
      name: 'the same sentence in Vietnamese',
      digest: const ReminderDigest(
        deckName: 'Korean',
        dueCount: 86,
        otherDeckCount: 2,
      ),
      locale: const Locale('vi'),
      body: '86 thẻ đến hạn trong Korean, và 2 deck khác có thẻ đang chờ.',
    ),
  ];
  for (final c in bodies) {
    test(c.name, () {
      expect(reminderNotificationBody(c.digest, c.locale), c.body);
    });
  }
}
