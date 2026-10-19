import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/email_text.dart';

// A long address wraps before its domain (audit 2026-10-19, G5).
void main() {
  test('a zero-width space after the first @, nothing else changes', () {
    for (final (email, shown) in [
      ('ann.nguyen@example.com', 'ann.nguyen@​example.com'),
      ('no-at-sign', 'no-at-sign'),
      ('a@b@c', 'a@​b@c'),
    ]) {
      expect(wrappableEmail(email), shown, reason: email);
    }
  });
}
