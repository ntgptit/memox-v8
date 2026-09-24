import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repository_provider.g.dart';

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepositoryImpl(ref.watch(databaseProvider));
