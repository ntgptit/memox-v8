import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/presentation/providers/study_home_provider.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';

// Screen 13's practice slot (detail file 13, TOPIK entry; DEV-394): `app/`
// hands a feature's entry in, and the screen shows it only with data.

final _en = lookupAppLocalizations(const Locale('en'));

/// Screen 13 with a feature's practice entry in its slot (TOPIK, DEV-394).
StudyHomeScreen _screenWithPractice(Widget practiceEntry) => StudyHomeScreen(
  onOpenSession: (_) {},
  onOpenDeck: (_) {},
  onOpenLibrary: () {},
  onOpenStarterDecks: () {},
  onOpenSync: () {},
  practiceEntry: practiceEntry,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  libraryTest('the practice slot shows under the content in a state with '
      'data, even with no deck (detail file 13)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screenWithPractice(const Text('practice-entry')),
    );
    await _settle(tester);

    expect(find.text('practice-entry'), findsOneWidget);
  });

  libraryTest('the practice slot is absent on a read that fails (detail '
      'file 13)', (tester, env) async {
    await pumpLibraryScreen(
      tester,
      env,
      _screenWithPractice(const Text('practice-entry')),
      overrides: [
        studyHomeProvider.overrideWith(
          (ref) => Stream<StudyHome>.error(StateError('read failed')),
        ),
      ],
    );
    await _settle(tester);

    expect(find.text(_en.studyHomeErrorTitle), findsOneWidget);
    expect(find.text('practice-entry'), findsNothing);
  });

  libraryTest('the practice slot is absent while loading', (tester, env) async {
    final never = StreamController<StudyHome>();
    addTearDown(never.close);
    await pumpLibraryScreen(
      tester,
      env,
      _screenWithPractice(const Text('practice-entry')),
      overrides: [studyHomeProvider.overrideWith((ref) => never.stream)],
    );
    await _settle(tester);

    expect(find.text('practice-entry'), findsNothing);
  });
}
