import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_unavailable.dart';

import '../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('a not-yet control reads its hint to TalkBack (spec A4)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: Center(
          child: MxUnavailable(
            hint: _en.commonNotAvailableYet,
            child: const MxButton(label: 'Export', onPressed: null),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(MxButton)),
      isSemantics(hint: _en.commonNotAvailableYet),
    );
  });
}
