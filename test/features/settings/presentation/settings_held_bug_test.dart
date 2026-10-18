import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/effective_study_options_model.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';
import 'package:memox/features/settings/domain/usecases/set_log_sql_statements_use_case.dart';
import 'package:memox/features/settings/presentation/controllers/settings_controller.dart';
import 'package:memox/features/settings/presentation/controllers/sql_log_controller.dart';
import 'package:memox/features/settings/presentation/controllers/study_options_controller.dart';
import 'package:memox/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';
import 'package:memox/features/settings/presentation/providers/study_options_provider.dart';
import 'package:memox/features/settings/presentation/states/settings_state.dart';
import 'package:memox/features/settings/presentation/states/study_options_state.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/held_bug.dart';
import '../../../support/held_bug_capture.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';

/// The real settings store, but its SQL log and root options writes die on
/// a bug, not a Failure (ADR-016). Nothing else is called.
final class _BuggyStore implements SettingsRepository {
  _BuggyStore(this._inner);

  final SettingsRepository _inner;

  @override
  Stream<AppSettingsEntity> watchAppSettings() => _inner.watchAppSettings();

  @override
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
      _inner.watchStudyOptions(deckId: deckId);

  @override
  Future<EffectiveStudyOptions?> studyOptionsOf({required String deckId}) =>
      _inner.studyOptionsOf(deckId: deckId);

  @override
  Future<Outcome<void, SettingsRejection>> setLogSqlStatements({
    required bool enabled,
  }) async => throw heldBug();

  @override
  Future<Outcome<void, SettingsRejection>> saveRootStudyOptions({
    required String rootDeckId,
    required StudyOptions options,
  }) async => throw heldBug();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// LIB-6: a held write that meets a bug releases its flow and reports the
// bug (runHeld). Settings' writes end as they do for a Failure (E2).
void main() {
  late LibraryEnv env;
  setUp(() => env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday)));
  tearDown(() => env.db.close());

  ProviderContainer buggy() => libraryContainer(
    env,
    overrides: [
      settingsRepositoryProvider.overrideWithValue(
        _BuggyStore(SettingsRepositoryImpl(env.db)),
      ),
    ],
  );

  test('a submit that dies on a bug is no longer busy and says the save '
      'failed, with Retry (_submit)', () async {
    final container = buggy();
    container.listen(settingsControllerProvider, (_, _) {});
    await container.read(appSettingsProvider.future);
    final reported = captureReportedBugs();

    final hasReset = await container
        .read(settingsControllerProvider.notifier)
        .reset(() async => throw heldBug());

    expect(hasReset, isFalse);
    expectOneBugReported(reported);
    final state = container.read(settingsControllerProvider);
    expect(state.isBusy(SettingsSubmit.reset), isFalse);
    expect(state.notice, isA<SettingsSaveFailed>());
    expect(state.notice!.kind, SettingsSubmit.reset);
  });

  test('a Save that dies on a bug is no longer saving and fails with Retry '
      'save, the draft kept (save)', () async {
    final root = await env.decks.root('Korean');
    final sub = await env.decks.sub(root.id, 'Words');
    final container = buggy();
    final provider = studyOptionsControllerProvider(sub.id);
    container.listen(provider, (_, _) {});
    await container.read(studyOptionsProvider(sub.id).future);
    await container.read(appSettingsProvider.future);
    final controller = container.read(provider.notifier)
      ..useAppDefaults(isOn: false)
      ..stepCardLimit(5);
    final reported = captureReportedBugs();

    await controller.save();

    expectOneBugReported(reported);
    final state = container.read(provider);
    expect(state.isSaving, isFalse);
    expect(state.save, StudyOptionsSave.failed);
    expect(state.cardLimit, 25);
  });

  test('a SQL log save that dies on a bug is no longer saving and reports '
      'the failure once (set)', () async {
    final container = ProviderContainer(
      overrides: [
        setLogSqlStatementsUseCaseProvider.overrideWithValue(
          SetLogSqlStatementsUseCase(
            _BuggyStore(SettingsRepositoryImpl(env.db)),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sqlLogControllerProvider, (_, _) {});
    final reported = captureReportedBugs();

    await container.read(sqlLogControllerProvider.notifier).set(enabled: false);

    expectOneBugReported(reported);
    final state = container.read(sqlLogControllerProvider);
    expect(state.isSaving, isFalse);
    expect(state.hasFailure, isTrue);
  });
}
