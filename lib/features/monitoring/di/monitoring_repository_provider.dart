import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/features/monitoring/data/datasources/monitoring_remote_data_source.dart';
import 'package:memox/features/monitoring/data/repositories/monitoring_repository_impl.dart';
import 'package:memox/features/monitoring/domain/repositories/monitoring_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'monitoring_repository_provider.g.dart';

/// The admin RPCs through the Supabase project main.dart initialized, and
/// the device's log buffer. Read only from Monitoring's screens, which only
/// an admin of a build with Supabase reaches.
@riverpod
MonitoringRepository monitoringRepository(Ref ref) {
  final client = Supabase.instance.client;
  return MonitoringRepositoryImpl(
    remote: MonitoringRemoteDataSource(
      rpc: (function, params) => client.rpc<Object?>(function, params: params),
      hasSession: () => client.auth.currentSession != null,
    ),
    local: ref.watch(logDatabaseProvider),
  );
}
