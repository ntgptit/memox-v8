import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/placeholder_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The routes around Settings (FE-A3).
void main() {
  libraryTest('the Settings tab is screen 23, not a placeholder', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(tester, env);
    await _tap(tester, _tab(_en.navSettings));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byType(PlaceholderScreen), findsNothing);
  });

  for (final (row, title) in [
    (_en.settingsTheme, _en.settingsTheme),
    (_en.settingsLanguage, _en.settingsLanguage),
  ]) {
    libraryTest('$row opens its page above the shell; Back returns (D2)', (
      tester,
      env,
    ) async {
      await pumpMemoxApp(tester, env);
      await _tap(tester, _tab(_en.navSettings));

      await _tap(tester, find.text(row));
      expect(_barTitle(title), findsOneWidget);
      expect(find.byType(MxBottomNav), findsNothing);

      await _tap(tester, find.byTooltip(_en.commonBack));
      expect(_barTitle(_en.navSettings), findsOneWidget);
      expect(find.byType(MxBottomNav), findsOneWidget);
    });
  }

  libraryTest('a deck\'s Study options opens screen 15 above the shell; '
      'Back returns to the deck (FE-A3 D3)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.byTooltip(_en.deckActions));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxActionSheetCommandRow),
        matching: find.text(_en.deckStudyOptions),
      ),
    );

    expect(find.byType(StudyOptionsScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    // The path from the deck feature, ending at this page (C6).
    expect(
      find.descendant(
        of: find.byType(MxBreadcrumb),
        matching: find.text(_en.deckStudyOptions),
      ),
      findsOneWidget,
    );
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(StudyOptionsScreen), findsNothing);
    expect(_barTitle('Korean'), findsOneWidget);
  });

  libraryTest('screen 14\'s icon opens screen 15; Back returns to the '
      'entry (FE-A3 D3)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.byTooltip(_en.deckActions));
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxActionSheetCommandRow),
        matching: find.text(_en.studyThisDeck),
      ),
    );
    await _tap(tester, find.byTooltip(_en.deckStudyOptions));

    expect(find.byType(StudyOptionsScreen), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(StudyEntryScreen), findsOneWidget);
  });
}
