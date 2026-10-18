import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/features/settings/presentation/screens/study_defaults_screen.dart';
import 'package:memox/features/settings/presentation/screens/study_options_screen.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/network/supabase_config.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/app_harness.dart';
import '../support/forui_expect.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The routes around Settings (FE-A3).
void main() {
  libraryTest('the Settings tab is screen 23', (tester, env) async {
    await pumpMemoxApp(tester, env);
    await tapAndSettle(tester, bottomTab(_en.navSettings));

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  // A row of the hub opens its page above the shell, titled with the row;
  // Back returns. [screen] is the page's own widget, when the row has one.
  for (final (name, row, screen) in [
    (
      '${_en.settingsTheme} opens its page above the shell; Back returns (D2)',
      _en.settingsTheme,
      null,
    ),
    (
      '${_en.settingsLanguage} opens its page above the shell; Back returns '
          '(D2)',
      _en.settingsLanguage,
      null,
    ),
    (
      'the Study defaults row opens screen 23a above the shell; Back returns '
          '(settings hub spec D1)',
      _en.settingsStudyDefaults,
      find.byType(StudyDefaultsScreen),
    ),
  ]) {
    libraryTest(name, (tester, env) async {
      await pumpMemoxApp(tester, env);
      await tapAndSettle(tester, bottomTab(_en.navSettings));

      await tapAndSettle(tester, find.text(row));
      if (screen != null) expect(screen, findsOneWidget);
      expect(barTitle(row), findsOneWidget);
      expect(find.byType(MxBottomNav), findsNothing);

      await tapAndSettle(tester, byControlLabel(_en.commonBack));
      if (screen != null) expect(screen, findsNothing);
      expect(barTitle(_en.navSettings), findsOneWidget);
      expect(find.byType(MxBottomNav), findsOneWidget);
    });
  }

  libraryTest('a build without Supabase composes no account row: the hub '
      'has no Account & sync section (settings hub spec §5.1)', (
    tester,
    env,
  ) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: '', publishableKey: ''),
        ),
      ],
    );
    await tapAndSettle(tester, bottomTab(_en.navSettings));

    expect(find.text(_en.settingsAccountSync.toUpperCase()), findsNothing);
    expect(find.text(_en.settingsStudySection.toUpperCase()), findsOneWidget);
  });

  libraryTest('a deck\'s Study options opens screen 15 above the shell; '
      'Back returns to the deck (FE-A3 D3)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await tapAndSettle(tester, find.text('Korean'));
    await tapAndSettle(tester, byControlLabel(_en.deckActions));
    await tapAndSettle(
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
    await tapAndSettle(tester, byControlLabel(_en.commonBack));
    expect(find.byType(StudyOptionsScreen), findsNothing);
    expect(barTitle('Korean'), findsOneWidget);
  });

  libraryTest('screen 14\'s icon opens screen 15; Back returns to the '
      'entry (FE-A3 D3)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await tapAndSettle(tester, find.text('Korean'));
    await tapAndSettle(tester, byControlLabel(_en.deckActions));
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(MxActionSheetCommandRow),
        matching: find.text(_en.studyThisDeck),
      ),
    );
    await tapAndSettle(tester, byControlLabel(_en.deckStudyOptions));

    expect(find.byType(StudyOptionsScreen), findsOneWidget);
    await tapAndSettle(tester, byControlLabel(_en.commonBack));
    expect(find.byType(StudyEntryScreen), findsOneWidget);
  });
}
