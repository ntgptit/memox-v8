import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/get_pending_log_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_pending_log_use_case_provider.g.dart';

@riverpod
GetPendingLogUseCase getPendingLogUseCase(Ref ref) =>
    GetPendingLogUseCase(ref.watch(monitoringRepositoryProvider));
