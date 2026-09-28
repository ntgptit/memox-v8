import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/states/study_start_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_entry_banner_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// Screen 14's refusal banner: UC-STUDY-003 E1.

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  libraryTest('self-assess no longer offered says the review algorithm '
      'changed, not that the session ended (UC-STUDY-003 E1)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(
        body: StudyEntryBannerWidget(
          start: StudyStartState(
            status: StudyStartStatus.refused,
            refusal: StudyRejection.modeNotOffered,
          ),
        ),
      ),
    );

    expect(find.text(_en.studyEntryRefusedNotOfferedTitle), findsOneWidget);
    expect(find.text(_en.studyEntryRefusedNotOfferedBody), findsOneWidget);
    expect(find.text(_en.studyEntryRefusedSessionTitle), findsNothing);
  });
}
