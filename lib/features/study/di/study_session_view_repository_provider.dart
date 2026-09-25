import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_view_repository_provider.g.dart';

@riverpod
StudySessionViewRepository studySessionViewRepository(Ref ref) =>
    StudySessionViewRepositoryImpl(ref.watch(databaseProvider));
