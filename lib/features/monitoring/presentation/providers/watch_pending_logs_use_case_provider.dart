import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/watch_pending_logs_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'watch_pending_logs_use_case_provider.g.dart';

@riverpod
WatchPendingLogsUseCase watchPendingLogsUseCase(Ref ref) =>
    WatchPendingLogsUseCase(ref.watch(monitoringRepositoryProvider));
