import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';

/// The stored codes are the enum names, and the table's `CHECK` constraints
/// keep them valid: an unknown code is corrupt data and throws.
AppSettingsEntity appSettingsOf(AppSetting row) => AppSettingsEntity(
  studyDefaults: StudyOptions(
    cardLimit: row.cardLimit,
    newCardOrder: NewCardOrder.values.byName(row.newCardOrder),
  ),
  theme: ThemeChoice.values.byName(row.themeMode),
  language: LanguageChoice.values.byName(row.language),
);
