import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/reminders/data/repositories/unsupported_reminder_platform_repository_impl.dart';
import 'package:memox/features/reminders/domain/failures/reminder_failure.dart';
import 'package:memox/features/reminders/domain/models/reminder_digest_model.dart';
import 'package:memox/features/reminders/domain/models/reminder_platform_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';

// The platform side where there are no reminders: Web, and every platform
// until BE-B5b (reminders spec D7).

Matcher _refusedAsUnsupported() =>
    isA<Rejected<void, ReminderRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      ReminderRejection.unsupported,
    );

void main() {
  const platform = UnsupportedReminderPlatformRepositoryImpl();

  test('an unsupported platform says so, and never pretends to be on '
      '(BR-REMINDER-012, UC-REMINDER-001 E2)', () async {
    expect(await platform.capability(), ReminderCapability.unsupported);
    expect(await platform.requestPermission(), ReminderPermission.denied);
  });

  test('every other call is refused with its reason, never thrown '
      '(BR-REMINDER-012)', () async {
    const digest = ReminderDigest(
      deckName: 'Korean',
      dueCount: 3,
      otherDeckCount: 0,
    );

    expect(
      await platform.schedule(at: DateTime(2026, 9, 26, 20)),
      _refusedAsUnsupported(),
    );
    expect(await platform.cancel(), _refusedAsUnsupported());
    expect(
      await platform.show(digest: digest, language: LanguageChoice.en),
      _refusedAsUnsupported(),
    );
  });
}
