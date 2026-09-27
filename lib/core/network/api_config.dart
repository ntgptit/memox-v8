/// Where the MemoX API lives. Sync runs only when a build defines
/// `--dart-define=API_BASE_URL=…` (app deck-sync spec §2).
class ApiConfig {
  const ApiConfig(this.baseUrl);

  static const environment = ApiConfig(String.fromEnvironment('API_BASE_URL'));

  final String baseUrl;

  bool get isEnabled => baseUrl.isNotEmpty;
}
