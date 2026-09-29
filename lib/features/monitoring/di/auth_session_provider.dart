import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_session_provider.g.dart';

/// The Supabase session now, and again whenever it changes: a sign-in, a
/// sign-out or a token refresh (which is how a role set on the account
/// arrives). Read only when this build names a Supabase project; a test
/// overrides it, since `Supabase.instance` is a singleton.
@Riverpod(keepAlive: true)
Stream<Session?> authSession(Ref ref) async* {
  final auth = Supabase.instance.client.auth;
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((state) => state.session);
}
