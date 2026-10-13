import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/usecases/set_log_sql_statements_use_case.dart';
import 'package:memox/features/settings/presentation/providers/set_log_sql_statements_use_case_provider.dart';
import 'package:memox/features/settings/presentation/widgets/items/sql_log_row_widget.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/library_harness.dart';
import '../../../support/settings_fakes.dart';

// SQL log switch spec §5: the row shows the account's value, saves the
// flipped one, and a failed save says so while the row keeps its value.
void main() {
  Future<int> flag(LibraryEnv env) async =>
      (await env.db.select(env.db.appSettings).getSingle()).logSqlStatements;

  Future<FlakySettingsRepository> pump(
    WidgetTester tester,
    LibraryEnv env, {
    bool isFailing = false,
  }) async {
    final repository = FlakySettingsRepository(SettingsRepositoryImpl(env.db))
      ..isFailing = isFailing;
    await pumpLibraryScreen(
      tester,
      env,
      const Scaffold(body: SqlLogRowWidget()),
      overrides: [
        setLogSqlStatementsUseCaseProvider.overrideWithValue(
          SetLogSqlStatementsUseCase(repository),
        ),
      ],
    );
    return repository;
  }

  libraryTest("shows the row's value and saves the flipped one", (
    tester,
    env,
  ) async {
    final repository = await pump(tester, env);
    expect(find.text('Log SQL statements'), findsOneWidget);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isTrue);

    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.pump();

    expect(repository.writes, 1);
    expect(await flag(env), 0);
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isFalse);
  });

  libraryTest('a failed save shows the snackbar and keeps the value', (
    tester,
    env,
  ) async {
    await pump(tester, env, isFailing: true);

    await tester.tap(find.byType(MxToggle));
    await tester.pump();
    await tester.pump();

    expect(
      find.text("Couldn't change that. The switch is unchanged."),
      findsOneWidget,
    );
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).isOn, isTrue);
    expect(await flag(env), 1);
  });
}
