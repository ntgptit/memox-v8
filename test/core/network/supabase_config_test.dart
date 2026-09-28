import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/network/supabase_config.dart';

void main() {
  test('is enabled only when both the URL and the key are set', () {
    expect(
      const SupabaseConfig(url: 'u', publishableKey: 'k').isEnabled,
      isTrue,
    );
    expect(
      const SupabaseConfig(url: '', publishableKey: 'k').isEnabled,
      isFalse,
    );
    expect(
      const SupabaseConfig(url: 'u', publishableKey: '').isEnabled,
      isFalse,
    );
  });

  test('a test build names no project', () {
    expect(SupabaseConfig.environment.isEnabled, isFalse);
  });
}
