import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/startup_settings.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';

import '../support/fake_day_clock.dart';
import '../support/library_harness.dart';
import '../support/settings_fakes.dart';
import '../support/test_database.dart';

void main() {
  test('the stored theme and language are read before the first frame '
      '(FE-A3 D5)', () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    addTearDown(env.db.close);
    final store = SettingsRepositoryImpl(env.db);
    await store.setTheme(theme: ThemeChoice.dark);
    await store.setLanguage(language: LanguageChoice.vi);

    final settings = await readStartupSettings(libraryContainer(env));

    expect(settings!.theme, ThemeChoice.dark);
    expect(settings.language, LanguageChoice.vi);
  });

  test('a failed read starts the app on the platform, with no invented '
      'value (E3)', () async {
    final env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    addTearDown(env.db.close);
    final container = libraryContainer(
      env,
      overrides: [
        appSettingsProvider.overrideWith(
          (ref) => Stream.error(FlakySettingsRepository.failure),
        ),
      ],
    );

    expect(await readStartupSettings(container), isNull);
  });
}
