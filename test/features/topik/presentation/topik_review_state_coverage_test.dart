import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';

// The States rows of screen 39 (TOPIK review) whose detail file cites no
// executed test: groupCollapsed / scriptHidden and pictureOption.

final _en = lookupAppLocalizations(const Locale('en'));

/// A picture the app bundles, standing for a content asset.
const _picture = 'assets/brand/google_g.png';

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  TopikTest test, {
  Map<int, int> answers = const {},
}) async {
  final done = await topikSeedSubmitted(env, test, answers: answers);
  await pumpLibraryScreen(
    tester,
    env,
    TopikReviewScreen(
      attemptId: done.id,
      onBack: () {},
      onBackToSummary: () {},
    ),
    overrides: [
      ...topikContentOverrides([test]),
      topikAudioRepositoryProvider.overrideWithValue(
        FakeTopikAudioRepository(),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

Finder _pictures() => find.byWidgetPredicate(
  (widget) =>
      widget is Image &&
      widget.image is AssetImage &&
      (widget.image as AssetImage).assetName == _picture,
);

void main() {
  libraryTest('groupCollapsed: Hide passage folds the shared pane to its '
      'instruction and Show passage opens it again', (tester, env) async {
    final reading = topikTestFixture();
    await _pump(tester, env, reading);
    final group = reading.groups.first;

    expect(find.text(group.passage!.textKo!), findsOneWidget);
    expect(find.text(group.instructionKo), findsOneWidget);

    await tester.tap(byControlLabel(_en.topikHidePassage));
    await tester.pumpAndSettle();

    expect(find.text(group.passage!.textKo!), findsNothing);
    expect(find.text(group.instructionKo), findsOneWidget);
    expect(byControlLabel(_en.topikShowPassage), findsOneWidget);
    expect(byControlLabel(_en.topikHidePassage), findsNothing);
    // The question below is untouched.
    expect(find.textContaining('(1)'), findsOneWidget);

    await tester.tap(byControlLabel(_en.topikShowPassage));
    await tester.pumpAndSettle();

    expect(find.text(group.passage!.textKo!), findsOneWidget);
  });

  libraryTest('scriptHidden: Hide script hides a listening group\'s script; '
      'the choice is remembered for that group while the review is open', (
    tester,
    env,
  ) async {
    final listening = topikTestFixture(section: TopikSection.listening);
    await _pump(tester, env, listening);
    final script = listening.groups.first.script!;

    expect(find.text(script), findsOneWidget);

    await tester.tap(find.text(_en.topikHideScript));
    await tester.pumpAndSettle();

    expect(find.text(script), findsNothing);
    expect(find.text(_en.topikShowScript), findsOneWidget);

    // Another group has its own choice: its script is open by default.
    await tester.tap(find.text(_en.topikNext));
    await tester.pumpAndSettle();
    expect(find.text(script), findsOneWidget);
    expect(find.text(_en.topikHideScript), findsOneWidget);

    // Back on the first group, its script is still hidden.
    await tester.tap(find.text(_en.topikPrevious));
    await tester.pumpAndSettle();
    expect(find.text(script), findsNothing);
    expect(find.text(_en.topikShowScript), findsOneWidget);

    await tester.tap(find.text(_en.topikShowScript));
    await tester.pumpAndSettle();
    expect(find.text(script), findsOneWidget);
  });

  libraryTest('pictureOption: a passage and options that are pictures draw '
      'them, read "Picture" to TalkBack, and keep their review tones', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    final json = topikTestJson();
    groupJson(json, 'g1')['passage'] = {'image': _picture};
    questionJson(json, 1)['options'] = [
      for (var idx = 1; idx <= 4; idx++) {'idx': idx, 'image': _picture},
    ];
    final test = topikTestOfFixtureJson(json);
    final first = test.questions.first;
    final wrong = first.answerIdx % 4 + 1;
    await _pump(tester, env, test, answers: {first.no: wrong});

    // The group's passage and the four options.
    expect(_pictures(), findsNWidgets(5));
    expect(find.bySemanticsLabel(_en.topikPicture), findsOneWidget);
    for (var idx = 1; idx <= 4; idx++) {
      final label = idx == first.answerIdx
          ? _en.topikOptionReviewLabel(
              idx,
              _en.topikPicture,
              _en.topikRightState,
            )
          : idx == wrong
          ? _en.topikOptionReviewLabel(
              idx,
              _en.topikPicture,
              _en.topikYourWrongState,
            )
          : _en.topikOptionLabel(idx, _en.topikPicture);
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
