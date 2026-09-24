import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/usecases/reset_app_settings_use_case.dart';
import 'package:memox/features/settings/domain/usecases/save_study_defaults_use_case.dart';
import 'package:memox/features/settings/domain/usecases/set_language_use_case.dart';
import 'package:memox/features/settings/domain/usecases/set_theme_use_case.dart';
import 'package:memox/features/settings/domain/usecases/watch_app_settings_use_case.dart';

import '../../../support/test_database.dart';

// The five use cases of the settings row, through the real repository: what
// a person sees on the Settings tab after each action (UC-SETTINGS-001).

void main() {
  late AppDatabase db;
  late SettingsRepositoryImpl settings;
  setUp(() {
    db = openTestDatabase();
    settings = SettingsRepositoryImpl(db, now: () => DateTime(2026, 9, 24));
  });
  tearDown(() => db.close());

  test('the Settings tab shows every save, then the defaults again after '
      'Reset to defaults (UC-SETTINGS-001 steps 1-5, A3)', () async {
    final seen = <AppSettingsEntity>[];
    final subscription = WatchAppSettingsUseCase(settings)().listen(seen.add);
    await pumpEventQueue();

    final saved = await SaveStudyDefaultsUseCase(settings)(
      options: const StudyOptions(
        cardLimit: 5,
        newCardOrder: NewCardOrder.random,
      ),
    );
    await pumpEventQueue();
    await SetThemeUseCase(settings)(theme: ThemeChoice.dark);
    await pumpEventQueue();
    await SetLanguageUseCase(settings)(language: LanguageChoice.vi);
    await pumpEventQueue();
    await ResetAppSettingsUseCase(settings)();
    await pumpEventQueue();
    await subscription.cancel();

    expect(saved, isA<Ok<void, SettingsRejection>>());
    expect(
      [
        for (final current in seen)
          (current.studyDefaults.cardLimit, current.theme, current.language),
      ],
      [
        (20, ThemeChoice.system, LanguageChoice.system),
        (5, ThemeChoice.system, LanguageChoice.system),
        (5, ThemeChoice.dark, LanguageChoice.system),
        (5, ThemeChoice.dark, LanguageChoice.vi),
        (20, ThemeChoice.system, LanguageChoice.system),
      ],
    );
  });

  test('SaveStudyDefaultsUseCase refuses a card limit of 0 '
      '(UC-SETTINGS-001 E1)', () async {
    final result = await SaveStudyDefaultsUseCase(settings)(
      options: const StudyOptions(
        cardLimit: 0,
        newCardOrder: NewCardOrder.created,
      ),
    );

    expect(
      result,
      isA<Rejected<void, SettingsRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        SettingsRejection.cardLimitOutOfRange,
      ),
    );
  });
}
