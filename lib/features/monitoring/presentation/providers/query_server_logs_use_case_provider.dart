import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/features/monitoring/di/monitoring_repository_provider.dart';
import 'package:memox/features/monitoring/domain/usecases/query_server_logs_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'query_server_logs_use_case_provider.g.dart';

@riverpod
QueryServerLogsUseCase queryServerLogsUseCase(Ref ref) =>
    QueryServerLogsUseCase(
      ref.watch(monitoringRepositoryProvider),
      ref.watch(dayClockProvider),
    );
