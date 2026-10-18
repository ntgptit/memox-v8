import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/screens/language_screen.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// A failed-save toast's Retry acts on the screen's controller: once the
// screen leaves, the toast leaves with it, so no Retry reads a disposed
// screen (closing acceptance 2026-10-18 NEW-1).

final _en = lookupAppLocalizations(const Locale('en'));

/// Fails the next save on [screen], tapping [choice]; then leaves it.
Future<void> _failThenLeave(
  WidgetTester tester,
  LibraryEnv env,
  Widget screen,
  String choice,
  String failed,
) async {
  final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
    ..isFailing = true;
  await pumpLibraryScreen(
    tester,
    env,
    screen,
    overrides: [settingsRepositoryProvider.overrideWithValue(store)],
  );
  await tester.tap(find.text(choice));
  await tester.pumpAndSettle();
  expect(find.text(failed), findsOneWidget);

  unawaited(
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const SizedBox()),
        ),
  );
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('Theme: the failed-save toast leaves with the screen, so no '
      'Retry reads it once gone', (tester, env) async {
    await _failThenLeave(
      tester,
      env,
      const ThemeScreen(),
      _en.settingsThemeDark,
      _en.settingsThemeSaveFailed,
    );

    expect(find.byType(ThemeScreen), findsNothing);
    expect(find.text(_en.settingsThemeSaveFailed), findsNothing);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(tester.takeException(), isNull);
  });

  libraryTest('Language: the failed-save toast leaves with the screen', (
    tester,
    env,
  ) async {
    await _failThenLeave(
      tester,
      env,
      const LanguageScreen(),
      _en.languageVietnamese,
      _en.settingsLanguageSaveFailed,
    );

    expect(find.byType(LanguageScreen), findsNothing);
    expect(find.text(_en.settingsLanguageSaveFailed), findsNothing);
    expect(find.text(_en.commonRetry), findsNothing);
  });
}
