import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/entities/app_settings_entity.dart';

import 'library_harness.dart';

/// The settings [env]'s database holds now. The store answers on the real
/// event loop, not the widget test's fake clock.
Future<AppSettingsEntity?> storedSettings(
  WidgetTester tester,
  LibraryEnv env,
) => tester.runAsync(
  () => SettingsRepositoryImpl(env.db).watchAppSettings().first,
);

/// The card limit [env]'s database holds now; call it inside `runAsync`.
Future<int> storedCardLimit(LibraryEnv env) async =>
    (await SettingsRepositoryImpl(
      env.db,
    ).watchAppSettings().first).studyDefaults.cardLimit;
