import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/router/app_routes.dart';

/// The pure helpers of [AppRoutes]. Moved unchanged from the route tests SP2
/// deleted with the legacy screens (spec 2026-10-04-sp2 §4.1 rule 4).
void main() {
  test('only a location inside the app is a way back (P3b minor M1)', () {
    for (final inside in ['/study', '/settings/account', '/decks?x=1']) {
      expect(AppRoutes.inAppOr(inside, AppRoutes.decks), inside);
    }
    for (final outside in [
      null,
      '',
      'study',
      '//evil.example/x',
      'https://evil.example/x',
      'memox://app/study',
      '/\\evil.example',
    ]) {
      expect(AppRoutes.inAppOr(outside, AppRoutes.decks), AppRoutes.decks);
    }
  });

  test('a log\'s path names it, and the buffer is a query', () {
    expect(AppRoutes.settingsMonitoringLog('abc'), '/settings/monitoring/abc');
    expect(
      AppRoutes.settingsMonitoringLog('abc', isLocal: true),
      '/settings/monitoring/abc?local=1',
    );
    expect(AppRoutes.isLocalLog({'local': '1'}), isTrue);
    expect(AppRoutes.isLocalLog({}), isFalse);
    expect(AppRoutes.isLocalLog({'local': '0'}), isFalse);
  });
}
