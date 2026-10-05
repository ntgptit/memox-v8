import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/relative_time.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));
  final now = DateTime.utc(2026, 10, 5, 12);

  String ago(Duration elapsed, [AppLocalizations? l10n]) =>
      (l10n ?? en).ago(now.subtract(elapsed), now);

  test('how long ago steps from minutes to years (DEV-170)', () {
    expect(ago(const Duration(seconds: 20)), 'just now');
    expect(ago(const Duration(minutes: 1)), '1 minute ago');
    expect(ago(const Duration(minutes: 59)), '59 minutes ago');
    expect(ago(const Duration(hours: 1)), '1 hour ago');
    expect(ago(const Duration(hours: 23)), '23 hours ago');
    expect(ago(const Duration(days: 1)), 'yesterday');
    expect(ago(const Duration(days: 29)), '29 days ago');
    expect(ago(const Duration(days: 30)), '1 month ago');
    expect(ago(const Duration(days: 364)), '12 months ago');
    expect(ago(const Duration(days: 365)), '1 year ago');
    expect(ago(const Duration(days: 800)), '2 years ago');
  });

  test('a time ahead of now reads as just now', () {
    expect(en.ago(now.add(const Duration(minutes: 5)), now), 'just now');
  });

  test('Vietnamese reads the same steps', () {
    expect(ago(const Duration(days: 3), vi), '3 ngày trước');
    expect(ago(const Duration(days: 61), vi), '2 tháng trước');
  });
}
