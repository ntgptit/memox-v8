import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/language_choice_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/models/theme_choice_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';

/// The real settings store, counting its writes, with every write failing
/// while [isFailing] is on (UC-SETTINGS-001 E2).
final class FlakySettingsRepository implements SettingsRepository {
  FlakySettingsRepository(this._inner);

  final SettingsRepository _inner;
  var isFailing = false;
  var writes = 0;

  /// While set, every write waits for it: a write still running.
  Completer<void>? hold;

  /// A path, so a test can check no message shows it (BR-CORE-005).
  static const failure = UnknownDatabaseFailure(cause: '/data/memox.sqlite');

  Future<Outcome<void, SettingsRejection>> _write(
    Future<Outcome<void, SettingsRejection>> Function() run,
  ) async {
    writes++;
    if (hold case final gate?) await gate.future;
    if (isFailing) throw failure;
    return run();
  }

  @override
  Stream<AppSettingsEntity> watchAppSettings() => _inner.watchAppSettings();

  @override
  Future<Outcome<void, SettingsRejection>> saveStudyDefaults({
    required StudyOptions options,
  }) => _write(() => _inner.saveStudyDefaults(options: options));

  @override
  Future<Outcome<void, SettingsRejection>> setTheme({
    required ThemeChoice theme,
  }) => _write(() => _inner.setTheme(theme: theme));

  @override
  Future<Outcome<void, SettingsRejection>> setLanguage({
    required LanguageChoice language,
  }) => _write(() => _inner.setLanguage(language: language));

  @override
  Future<Outcome<void, SettingsRejection>> resetToDefaults() =>
      _write(_inner.resetToDefaults);

  @override
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
      _inner.watchStudyOptions(deckId: deckId);

  @override
  Future<EffectiveStudyOptions?> studyOptionsOf({required String deckId}) =>
      _inner.studyOptionsOf(deckId: deckId);

  @override
  Future<Outcome<void, SettingsRejection>> saveRootStudyOptions({
    required String rootDeckId,
    required StudyOptions options,
  }) => _write(
    () => _inner.saveRootStudyOptions(rootDeckId: rootDeckId, options: options),
  );

  @override
  Future<Outcome<void, SettingsRejection>> clearRootStudyOptions({
    required String rootDeckId,
  }) => _write(() => _inner.clearRootStudyOptions(rootDeckId: rootDeckId));
}
