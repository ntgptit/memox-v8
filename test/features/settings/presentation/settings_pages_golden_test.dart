@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/screens/language_screen.dart';
import 'package:memox/features/settings/presentation/screens/theme_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('settings theme, system chosen, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const ThemeScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_theme_system_$theme.png',
        );
      });
    });

    libraryTest('settings theme, dark chosen, $theme', (tester, env) async {
      await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const ThemeScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_theme_dark_$theme.png',
        );
      });
    });

    libraryTest('settings theme, light chosen, $theme', (tester, env) async {
      await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.light);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, const ThemeScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_theme_light_$theme.png',
        );
      });
    });

    libraryTest('settings language, English chosen, $theme', (
      tester,
      env,
    ) async {
      await SettingsRepositoryImpl(env.db)
          .setLanguage(language: LanguageChoice.en);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const LanguageScreen(),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/settings_language_english_$theme.png',
        );
      });
    });

    libraryTest('settings language, phone in Vietnamese, $theme', (
      tester,
      env,
    ) async {
      tester.platformDispatcher.localeTestValue = const Locale('vi');
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const LanguageScreen(),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/settings_language_system_$theme.png',
        );
      });
    });

    libraryTest('settings language, switched, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          const LanguageScreen(),
          brightness,
        );
        await tester.tap(find.text(_en.languageVietnamese));
        await _settle(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/settings_language_switched_$theme.png',
        );
      });
    });
  }
}
