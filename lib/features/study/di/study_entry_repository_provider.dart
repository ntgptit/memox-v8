import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_repository_provider.g.dart';

@riverpod
StudyEntryRepository studyEntryRepository(Ref ref) => StudyEntryRepositoryImpl(
  ref.watch(databaseProvider),
  ref.watch(settingsRepositoryProvider),
);
