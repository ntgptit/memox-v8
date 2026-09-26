import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/placeholder_screen.dart';
import 'package:memox/features/settings/presentation/screens/settings_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

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
}
