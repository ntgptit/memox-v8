import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/di/topik_content_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_topik_test_detail_use_case_provider.g.dart';

@riverpod
WatchTopikTestDetailUseCase watchTopikTestDetailUseCase(Ref ref) =>
    WatchTopikTestDetailUseCase(
      ref.watch(topikContentRepositoryProvider),
      ref.watch(topikAttemptRepositoryProvider),
    );
