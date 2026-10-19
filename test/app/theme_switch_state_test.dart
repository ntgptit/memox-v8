import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../support/app_harness.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/study_entry_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Brightness _brightness(WidgetTester tester, Finder inside) =>
    Theme.of(tester.element(inside.first)).brightness;

EditableText _field(WidgetTester tester, int index) =>
    tester.widget<EditableText>(find.byType(EditableText).at(index));

String _text(WidgetTester tester, int index) =>
    _field(tester, index).controller.text;

// BR-SETTINGS-005: the theme applies at once, over the screen that is open.
// What the person has typed, and where the focus sits, is state of that
// screen and must not be rebuilt away with the theme.
void main() {
  libraryTest('a theme change keeps what was typed in the card editor and '
      'its focus', (tester, env) async {
    await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
    await pumpMemoxApp(tester, env);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Words'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxButton, _en.deckNewCard));
    await tester.pumpAndSettle();
    expect(_barTitle(_en.cardAddTitle), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'bap');
    await tester.enterText(find.byType(EditableText).at(1), 'rice');
    await tester.enterText(find.byType(EditableText).at(0), 'bap bap');
    await tester.pump();
    expect(_field(tester, 0).focusNode.hasFocus, isTrue);
    expect(_brightness(tester, find.byType(EditableText)), Brightness.light);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await tester.pumpAndSettle();

    expect(_brightness(tester, find.byType(EditableText)), Brightness.dark);
    expect(_barTitle(_en.cardAddTitle), findsOneWidget);
    expect(_text(tester, 0), 'bap bap');
    expect(_text(tester, 1), 'rice');
    expect(_field(tester, 0).focusNode.hasFocus, isTrue);

    // The same field takes the next keystroke: its connection survived.
    await tester.enterText(find.byType(EditableText).at(0), 'bap bap bap');
    await tester.pump();
    expect(_text(tester, 0), 'bap bap bap');
  });

  libraryTest('a theme change keeps the answer typed in a Fill session and '
      'its focus', (tester, env) async {
    final id = await openFiveDueReview(
      env.db,
      env.decks,
      libraryToday,
      StudyMode.fill,
    );
    await pumpMemoxApp(tester, env);
    unawaited(
      GoRouter.of(tester.element(find.byType(MxBottomNav)))
          .push(AppRoutes.studySession(id)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);

    await tester.enterText(find.byType(FTextField), 'ter');
    await tester.pump();
    expect(_field(tester, 0).focusNode.hasFocus, isTrue);
    expect(_brightness(tester, find.byType(EditableText)), Brightness.light);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await tester.pumpAndSettle();

    expect(_brightness(tester, find.byType(EditableText)), Brightness.dark);
    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.text('apple'), findsOneWidget);
    expect(_text(tester, 0), 'ter');
    expect(_field(tester, 0).focusNode.hasFocus, isTrue);
  });

  libraryTest('a theme change keeps a revealed Self-assess answer on the same '
      'card', (tester, env) async {
    final id = await openSelfAssessReview(env.db, env.decks, libraryToday);
    await pumpMemoxApp(tester, env);
    unawaited(
      GoRouter.of(tester.element(find.byType(MxBottomNav)))
          .push(AppRoutes.studySession(id)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.studySelfAssessShowAnswer));
    await tester.pumpAndSettle();
    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('meaning 1'), findsOneWidget);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await tester.pumpAndSettle();

    expect(find.byType(StudySessionScreen), findsOneWidget);
    expect(find.text('term 1'), findsOneWidget);
    expect(find.text('meaning 1'), findsOneWidget);
    expect(find.text(_en.studySelfAssessShowAnswer), findsNothing);
    expect(find.text(_en.cardActionGood), findsOneWidget);
  });
}
