import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/get_server_log_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_server_log_use_case_provider.g.dart';

@riverpod
GetServerLogUseCase getServerLogUseCase(Ref ref) =>
    GetServerLogUseCase(ref.watch(monitoringRepositoryProvider));
