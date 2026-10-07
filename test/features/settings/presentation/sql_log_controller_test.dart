import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/usecases/set_log_sql_statements_use_case.dart';
import 'package:memox/features/settings/presentation/controllers/sql_log_controller.dart';
import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';

import '../../../support/settings_fakes.dart';
import '../../../support/test_database.dart';

// SQL log switch spec §5: one save at a time; a failure is reported once.
void main() {
  late AppDatabase db;
  late FlakySettingsRepository repository;
  late ProviderContainer container;

  setUp(() {
    db = openTestDatabase();
    repository = FlakySettingsRepository(SettingsRepositoryImpl(db));
    container = ProviderContainer(
      overrides: [
        setLogSqlStatementsUseCaseProvider.overrideWithValue(
          SetLogSqlStatementsUseCase(repository),
        ),
      ],
    );
    addTearDown(container.dispose);
  });
  tearDown(() => db.close());

  Future<int> flag() async =>
      (await db.select(db.appSettings).getSingle()).logSqlStatements;

  test('set saves once and ignores a second tap while saving', () async {
    repository.hold = Completer<void>();
    final controller = container.read(sqlLogControllerProvider.notifier);
    final first = controller.set(enabled: false);
    expect(container.read(sqlLogControllerProvider).isSaving, isTrue);
    await controller.set(enabled: true);
    repository.hold!.complete();
    await first;
    expect(repository.writes, 1);
    expect(await flag(), 0);
    expect(container.read(sqlLogControllerProvider).isSaving, isFalse);
  });

  test('a failed save is reported, then dismissed', () async {
    repository.isFailing = true;
    final controller = container.read(sqlLogControllerProvider.notifier);
    await controller.set(enabled: false);
    expect(container.read(sqlLogControllerProvider).hasFailure, isTrue);
    expect(container.read(sqlLogControllerProvider).isSaving, isFalse);
    expect(await flag(), 1);
    controller.dismissFailure();
    expect(container.read(sqlLogControllerProvider).hasFailure, isFalse);
  });
}
