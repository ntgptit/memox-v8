import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/reminder_settings_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));
final _vi = lookupAppLocalizations(const Locale('vi'));

const _dark = AppSettingsEntity(
  studyDefaults: StudyOptions.defaults,
  theme: ThemeChoice.dark,
  language: LanguageChoice.system,
  reminder: ReminderSettings.defaults,
);

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(MxBottomNav))).brightness;

Finder _tab(String label) =>
    find.descendant(of: find.byType(MxBottomNav), matching: find.text(label));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

void main() {
  libraryTest('the first frame already paints the stored theme (FE-A3 D5)', (
    tester,
    env,
  ) async {
    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await pumpMemoxApp(tester, env, initialSettings: _dark, isSettled: false);

    expect(_brightness(tester), Brightness.dark);
  });

  libraryTest('a theme change keeps the open deck; System follows the '
      'platform (BR-SETTINGS-005, UC A2)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpMemoxApp(tester, env);
    await tester.tap(find.text('Korean'));
    await tester.pumpAndSettle();
    expect(_barTitle('Korean'), findsOneWidget);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.dark);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);
    expect(_barTitle('Korean'), findsOneWidget);

    await SettingsRepositoryImpl(env.db).setTheme(theme: ThemeChoice.system);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(_brightness(tester), Brightness.light);
  });

  libraryTest('a language change applies at once and survives a restart; '
      'System falls back to English (BR-SETTINGS-006)', (tester, env) async {
    await pumpMemoxApp(tester, env);
    await SettingsRepositoryImpl(env.db)
        .setLanguage(language: LanguageChoice.vi);
    await tester.pumpAndSettle();
    expect(_tab(_vi.navLibrary), findsOneWidget);

    // A new app over the same database.
    await tester.pumpWidget(const SizedBox());
    await pumpMemoxApp(tester, env);
    expect(_tab(_vi.navLibrary), findsOneWidget);

    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await SettingsRepositoryImpl(env.db)
        .setLanguage(language: LanguageChoice.system);
    await tester.pumpAndSettle();
    expect(_tab(_en.navLibrary), findsOneWidget);
  });
}
