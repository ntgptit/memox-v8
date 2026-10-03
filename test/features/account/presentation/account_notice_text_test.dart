import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// SP2b 2.47: the server may have taken a deletion whose session was dead, so
// "Nothing changed" would be a false state.
void main() {
  test('a deletion refused without a session says it is unconfirmed', () {
    expect(
      accountNoticeText(_en, const DeleteRefused(SessionInvalidFailure())),
      _en.accountDeleteUnknown,
    );
  });

  test('a deletion that timed out may have reached the server: it is '
      'unconfirmed too, while a connection that never opened is not '
      '(final fix 8)', () {
    expect(
      accountNoticeText(
        _en,
        DeleteRefused(OfflineFailure(cause: TimeoutException('slow'))),
      ),
      _en.accountDeleteUnknown,
    );
    expect(
      accountNoticeText(
        _en,
        const DeleteRefused(OfflineFailure(cause: SocketException('down'))),
      ),
      _en.accountDeleteRefused,
    );
  });

  test('every other refusal keeps "Nothing changed"', () {
    for (final failure in const <Failure>[
      OfflineFailure(cause: 'x'),
      ServerFailure(cause: 'x'),
      LastAdminFailure(),
    ]) {
      expect(
        accountNoticeText(_en, DeleteRefused(failure)),
        _en.accountDeleteRefused,
        reason: failure.runtimeType.toString(),
      );
    }
  });

  test('a refused merge keeps its own line', () {
    expect(
      accountNoticeText(_en, const MergeNotDone()),
      _en.accountMergeNotDone,
    );
  });
}
