import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_home_repository_provider.g.dart';

@riverpod
StudyHomeRepository studyHomeRepository(Ref ref) =>
    StudyHomeRepositoryImpl(ref.watch(databaseProvider));
