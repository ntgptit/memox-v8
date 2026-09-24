import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/datasources/settings_dao.dart';
import 'package:memox/features/settings/data/mappers/app_settings_mapper.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// Every save is one transaction of its own (BR-SETTINGS-007): its rule is
/// checked inside it, and a refusal writes nothing.
final class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = SettingsDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final SettingsDao _dao;
  final DateTime Function() _now;

  @override
  Stream<AppSettingsEntity> watchAppSettings() =>
      _dao.watchRow().map(appSettingsOf).mapDatabaseErrors();

  @override
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  }) {
    final at = _now();
    return _write(() async {
      if (options.check() case Rejected(:final reason)) return Rejected(reason);
      await _dao.updateRow(
        AppSettingsCompanion(
          cardLimit: Value(options.cardLimit),
          newCardOrder: Value(options.newCardOrder.name),
          updatedAt: Value(at),
        ),
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  }) => _save(AppSettingsCompanion(themeMode: Value(theme.name)));

  @override
  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  }) => _save(AppSettingsCompanion(language: Value(language.name)));

  @override
  Future<Outcome<void, SettingsRejection>> resetToDefaults() {
    const defaults = AppSettingsEntity.defaults;
    return _save(
      AppSettingsCompanion(
        cardLimit: Value(defaults.studyDefaults.cardLimit),
        newCardOrder: Value(defaults.studyDefaults.newCardOrder.name),
        themeMode: Value(defaults.theme.name),
        language: Value(defaults.language.name),
      ),
    );
  }

  /// [values] and `updated_at`, in one transaction of their own.
  Future<Outcome<void, SettingsRejection>> _save(AppSettingsCompanion values) {
    final at = _now();
    return _write(() async {
      await _dao.updateRow(values.copyWith(updatedAt: Value(at)));
      return const Ok(null);
    });
  }

  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
