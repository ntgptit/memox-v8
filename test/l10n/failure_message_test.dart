import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

void main() {
  for (final locale in const [Locale('en'), Locale('vi')]) {
    test('each failure reads as plain ${locale.languageCode} copy', () {
      final l10n = lookupAppLocalizations(locale);
      final failures = [
        const ConstraintFailure(cause: 'CHECK constraint failed: deck'),
        const DatabaseLockedFailure(cause: 'database is locked'),
        const UnknownDatabaseFailure(cause: '/data/app/memox.sqlite'),
        const SessionInvalidFailure(cause: 'refresh_token_not_found'),
        const IdentityTakenFailure(method: IdentityMethod.google),
        const InvalidCodeFailure(cause: 'otp_expired'),
        const LastAdminFailure(cause: 'LAST_ADMIN'),
        const UnsentChangesFailure(count: 3),
        const MutationBlockedFailure(),
      ];

      for (final failure in failures) {
        final copy = l10n.failure(failure);
        expect(copy.trim(), isNotEmpty);
        expect(copy, isNot(contains('/')));
        expect(copy.toLowerCase(), isNot(contains('sql')));
        expect(copy.toLowerCase(), isNot(contains('constraint failed')));
      }
    });
  }
}
