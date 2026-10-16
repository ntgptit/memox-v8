import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_summary_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_topik_summary_use_case_provider.g.dart';

@riverpod
WatchTopikSummaryUseCase watchTopikSummaryUseCase(Ref ref) =>
    WatchTopikSummaryUseCase(ref.watch(topikAttemptRepositoryProvider));
