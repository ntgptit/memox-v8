import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

// The settings vocabulary: the bounds of BR-STUDY-003, the enums whose names
// are the codes `app_settings` stores, and the defaults of UC-SETTINGS-001.

StudyOptions _options(int cardLimit) =>
    StudyOptions(cardLimit: cardLimit, newCardOrder: NewCardOrder.created);

void main() {
  group('StudyOptions.check (BR-STUDY-003: 1 to 200)', () {
    test('accepts both bounds and the default', () {
      for (final limit in [1, 20, 200]) {
        expect(
          _options(limit).check(),
          isA<Ok<void, SettingsRejection>>(),
          reason: 'card limit $limit',
        );
      }
    });

    test('refuses a limit below 1 or above 200', () {
      for (final limit in [-1, 0, 201]) {
        expect(
          _options(limit).check(),
          isA<Rejected<void, SettingsRejection>>().having(
            (rejected) => rejected.reason,
            'reason',
            SettingsRejection.cardLimitOutOfRange,
          ),
          reason: 'card limit $limit',
        );
      }
    });
  });

  test('the study defaults are 20 cards in created order '
      '(BR-STUDY-003, BR-STUDY-057)', () {
    expect(StudyOptions.defaults.cardLimit, 20);
    expect(StudyOptions.defaults.newCardOrder, NewCardOrder.created);
  });

  test('the app defaults are the study defaults, the system theme and the '
      'system language (BR-SETTINGS-005, BR-SETTINGS-006)', () {
    const defaults = AppSettingsEntity.defaults;
    expect(defaults.studyDefaults.cardLimit, StudyOptions.defaults.cardLimit);
    expect(
      defaults.studyDefaults.newCardOrder,
      StudyOptions.defaults.newCardOrder,
    );
    expect(defaults.theme, ThemeChoice.system);
    expect(defaults.language, LanguageChoice.system);
  });

  test('the enum names are the codes app_settings stores', () {
    expect(
      [for (final order in NewCardOrder.values) order.name],
      ['created', 'random'],
    );
    expect(
      [for (final theme in ThemeChoice.values) theme.name],
      ['system', 'light', 'dark'],
    );
    expect(
      [for (final language in LanguageChoice.values) language.name],
      ['system', 'en', 'vi'],
    );
  });

  test('only a root override offers Use app defaults (UC-SETTINGS-001 A1)', () {
    EffectiveStudyOptions from(StudyOptionsSource source) =>
        EffectiveStudyOptions(
          rootDeckId: 'root',
          options: StudyOptions.defaults,
          source: source,
        );

    expect(from(StudyOptionsSource.appDefaults).hasRootOverride, isFalse);
    expect(from(StudyOptionsSource.rootOverride).hasRootOverride, isTrue);
    expect(
      from(StudyOptionsSource.unreadableRootOverride).hasRootOverride,
      isTrue,
    );
  });
}
