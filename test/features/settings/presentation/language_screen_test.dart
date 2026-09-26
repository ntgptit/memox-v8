import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/presentation/screens/language_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

MxOptionRow _row(WidgetTester tester, String title) => tester.widget(
  find.ancestor(of: find.text(title), matching: find.byType(MxOptionRow)),
);

void main() {
  libraryTest('a tap switches the language and the toast reads in it '
      '(UC-SETTINGS-001 step 5)', (tester, env) async {
    await pumpLibraryScreen(tester, env, const LanguageScreen());
    expect(_row(tester, _en.settingsLanguageSystem).isSelected, isTrue);

    await tester.tap(find.text(_en.languageVietnamese));
    await tester.pumpAndSettle();

    expect(_row(tester, _en.languageVietnamese).isSelected, isTrue);
    expect(find.text(_vi.settingsLanguageSwitched), findsOneWidget);
  });

  libraryTest('Follow the system names the phone language, or says the app '
      'lacks it (FE-A3 D8)', (tester, env) async {
    tester.platformDispatcher
      ..localeTestValue = const Locale('vi')
      ..localesTestValue = const [Locale('vi')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpLibraryScreen(tester, env, const LanguageScreen());
    expect(
      find.text(_en.settingsLanguagePhoneIs(_en.languageVietnamese)),
      findsOneWidget,
    );

    tester.platformDispatcher
      ..localeTestValue = const Locale('fr')
      ..localesTestValue = const [Locale('fr')];
    await pumpLibraryScreen(tester, env, const LanguageScreen());
    expect(find.text(_en.settingsLanguageUnavailable), findsOneWidget);
  });

  libraryTest('a language named the same in the UI language has no second '
      'line', (tester, env) async {
    await pumpLibraryScreen(tester, env, const LanguageScreen());

    expect(_row(tester, _en.languageEnglish).description, isNull);
    expect(
      _row(tester, _en.languageVietnamese).description,
      _en.settingsLanguageVietnameseName,
    );
  });

  libraryTest('a second tap while a switch runs changes neither the store '
      'nor the language the toast names (A4)', (tester, env) async {
    final gate = Completer<void>();
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..hold = gate;
    await pumpLibraryScreen(
      tester,
      env,
      const LanguageScreen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text(_en.languageEnglish));
    await tester.pump();
    await tester.tap(find.text(_en.languageVietnamese));
    await tester.pump();

    store.hold = null;
    gate.complete();
    await tester.pumpAndSettle();

    expect(store.writes, 1);
    expect(find.text(_en.settingsLanguageSwitched), findsOneWidget);
    expect(
      find.text(
        lookupAppLocalizations(const Locale('vi')).settingsLanguageSwitched,
      ),
      findsNothing,
    );
  });

  libraryTest('a failed save keeps the stored language and offers Retry '
      '(E2)', (tester, env) async {
    final store = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = true;
    await pumpLibraryScreen(
      tester,
      env,
      const LanguageScreen(),
      overrides: [settingsRepositoryProvider.overrideWithValue(store)],
    );
    await tester.tap(find.text(_en.languageVietnamese));
    await tester.pumpAndSettle();

    expect(find.text(_en.settingsLanguageSaveFailed), findsOneWidget);
    expect(_row(tester, _en.settingsLanguageSystem).isSelected, isTrue);

    store.isFailing = false;
    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(_row(tester, _en.languageVietnamese).isSelected, isTrue);
  });
}
