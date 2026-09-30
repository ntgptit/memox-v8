import 'package:memox/core/network/supabase_client.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/repositories/user_role_repository_impl.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_role_repository_provider.g.dart';

/// The role RPCs through the Supabase project main.dart initialized; read
/// only from screen 33, which only an admin reaches.
@riverpod
UserRoleRepository userRoleRepository(Ref ref) => UserRoleRepositoryImpl(
  UserRoleRemoteDataSource(rpc: supabaseRpc, hasSession: hasSupabaseSession),
);
