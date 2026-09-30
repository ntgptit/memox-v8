import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/set_log_status_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'set_log_status_use_case_provider.g.dart';

@riverpod
SetLogStatusUseCase setLogStatusUseCase(Ref ref) =>
    SetLogStatusUseCase(ref.watch(monitoringRepositoryProvider));
