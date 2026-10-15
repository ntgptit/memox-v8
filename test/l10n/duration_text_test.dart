import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

// BR-TOPIK-025: 42s, 3m 05s, 1h 02m 11s, in the interface language.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('English reads seconds, minutes and hours, zero-padded after the first unit', () {
    expect(en.duration(0), '0s');
    expect(en.duration(42000), '42s');
    expect(en.duration(185000), '3m 05s');
    expect(en.duration(3731000), '1h 02m 11s');
    expect(en.duration(3600000), '1h 00m 00s');
  });

  test('Vietnamese reads the same steps', () {
    expect(vi.duration(42000), '42 giây');
    expect(vi.duration(185000), '3 phút 05 giây');
    expect(vi.duration(3731000), '1 giờ 02 phút 11 giây');
  });
}
