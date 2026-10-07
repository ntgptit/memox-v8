import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/speech/di/speech_providers.dart';
import 'package:memox/core/speech/speech_language.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study/presentation/widgets/support/study_speak_button_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_speech_synthesizer.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_entry_fixtures.dart';
import '../../../support/study_fixtures.dart';

// BR-STUDY-078…082, BR-SETTINGS-009; study speech spec §5.

final _en = lookupAppLocalizations(const Locale('en'));

/// A learning session of [count] cards on Korean › Lesson, whose root reads
/// in [language] when given.
Future<String> _learning(
  LibraryEnv env, {
  int count = 3,
  SpeechLanguage? language,
}) async {
  final root = await env.decks.root('Korean');
  final leaf = await env.decks.sub(root.id, 'Lesson');
  for (var i = 1; i <= count; i++) {
    await insertCard(
      env.db,
      id: 'c$i',
      deckId: leaf.id,
      front: 'front $i',
      back: 'back $i',
    );
  }
  if (language != null) {
    await SettingsRepositoryImpl(env.db).saveRootStudyOptions(
      rootDeckId: root.id,
      options: StudyOptions(
        cardLimit: 20,
        newCardOrder: NewCardOrder.created,
        speechLanguage: language,
      ),
    );
  }
  final opened = await studyEntryRepository(
    env.db,
    env.clock.now,
  ).openLearningSession(deckId: leaf.id);
  return (opened as Ok<String, StudyRejection>).value;
}

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  String id,
  FakeSpeechSynthesizer speech,
) async {
  await pumpLibraryScreen(
    tester,
    env,
    _screen(id),
    overrides: [speechSynthesizerProvider.overrideWithValue(speech)],
  );
  await tester.pumpAndSettle();
}

/// The term on screen: the session's order is the queue's, not the
/// insertion order, so the tests read it rather than assume it.
String _front(WidgetTester tester) => tester
    .widgetList<Text>(find.textContaining(RegExp(r'^front ')))
    .single
    .data!;

Future<void> _swipeLeft(WidgetTester tester) async {
  await tester.drag(find.byType(StudyBrowseWidget), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('the first card of a learning session is read once, in the '
      "root's language (BR-STUDY-078, BR-SETTINGS-009)", (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    final id = await _learning(env, language: SpeechLanguage.koKr);
    await _pump(tester, env, id, speech);

    expect(speech.spoken, [(_front(tester), SpeechLanguage.koKr)]);
  });

  libraryTest('each new card is read, and only once', (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    final id = await _learning(env);
    await _pump(tester, env, id, speech);
    final shown = [_front(tester)];
    await _swipeLeft(tester);
    shown.add(_front(tester));
    await _swipeLeft(tester);
    shown.add(_front(tester));

    expect(shown.toSet(), hasLength(3));
    expect(speech.spoken.map((s) => s.$1).toList(), shown);
  });

  libraryTest('with the switch off nothing is read, but the speaker button '
      'reads on tap (BR-STUDY-079)', (tester, env) async {
    final speech = FakeSpeechSynthesizer();
    await SettingsRepositoryImpl(env.db).setSpeechAutoPlay(isOn: false);
    final id = await _learning(env);
    await _pump(tester, env, id, speech);
    expect(speech.spoken, isEmpty);

    await tester.tap(find.byType(StudySpeakButtonWidget));
    await tester.pumpAndSettle();

    expect(speech.spoken, [(_front(tester), SpeechLanguage.enUs)]);
    expect(find.byTooltip(_en.studySpeakTerm), findsOneWidget);
  });

  libraryTest('a review session reads nothing (BR-STUDY-078)', (
    tester,
    env,
  ) async {
    final speech = FakeSpeechSynthesizer();
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await _pump(tester, env, id, speech);

    expect(speech.spoken, isEmpty);
    expect(find.byType(StudySpeakButtonWidget), findsOneWidget);
  });

  libraryTest('ending the session stops the voice (BR-STUDY-082)', (
    tester,
    env,
  ) async {
    final speech = FakeSpeechSynthesizer();
    final id = await _learning(env);
    await _pump(tester, env, id, speech);
    final stopsBefore = speech.stops;

    // ✕ then Stop: the session is abandoned and the summary shows.
    await tester.tap(find.byTooltip(_en.studySessionClose));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.studyExitStop));
    await tester.pumpAndSettle();

    expect(speech.stops, greaterThan(stopsBefore));
    expect(find.byType(StudySpeakButtonWidget), findsNothing);
  });
}
