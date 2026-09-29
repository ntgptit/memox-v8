import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/features/monitoring/di/auth_session_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

part 'is_admin_provider.g.dart';

const _adminRole = 'admin';

/// Whether [session]'s account is an admin (ADR-018 §7): `app_metadata.role`,
/// which only the service role and the dashboard can set.
bool isAdminSession(Session? session) =>
    session?.user.appMetadata['role'] == _adminRole;

/// Whether to show the Monitoring entry: the session's account is an admin.
/// False for a build with no Supabase project. It only decides visibility;
/// the RPCs check the role again (`FORBIDDEN`).
@Riverpod(keepAlive: true)
bool isAdmin(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) return false;
  return isAdminSession(ref.watch(authSessionProvider).value);
}
