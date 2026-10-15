import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/duration_parts.dart';

// BR-TOPIK-025: whole seconds, truncated; hours do not wrap.
void main() {
  (int, int, int) parts(int ms) {
    final p = DurationParts.ofMilliseconds(ms);
    return (p.hours, p.minutes, p.seconds);
  }

  test('splits milliseconds into hours, minutes and whole seconds', () {
    expect(parts(0), (0, 0, 0));
    expect(parts(42000), (0, 0, 42));
    expect(parts(59999), (0, 0, 59));
    expect(parts(185000), (0, 3, 5));
    expect(parts(3731000), (1, 2, 11));
    expect(parts(90000000), (25, 0, 0));
  });

  test('a negative duration is an error', () {
    expect(() => DurationParts.ofMilliseconds(-1), throwsArgumentError);
  });
}
