import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_repository_provider.g.dart';

@riverpod
StudySessionRepository studySessionRepository(Ref ref) =>
    StudySessionRepositoryImpl(
      ref.watch(databaseProvider),
      ref.watch(scheduleRepositoryProvider),
      ref.watch(cardRepositoryProvider),
    );
