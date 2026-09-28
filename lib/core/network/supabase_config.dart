/// Where the Supabase project lives (ADR-015). Sync runs only when a build
/// defines both `--dart-define=SUPABASE_URL=…` and
/// `--dart-define=SUPABASE_PUBLISHABLE_KEY=…`.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  static const environment = SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  final String url;
  final String publishableKey;

  bool get isEnabled => url.isNotEmpty && publishableKey.isNotEmpty;
}
