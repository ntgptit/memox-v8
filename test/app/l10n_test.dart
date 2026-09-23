import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Iterable<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((key) => !key.startsWith('@'));

void main() {
  test('every template key has a description and a Vietnamese value', () {
    final en = _arb('en');
    final vi = _arb('vi');

    for (final key in _keys(en)) {
      final meta = en['@$key'] as Map<String, dynamic>?;
      expect(meta?['description'], isA<String>(), reason: key);
      expect(
        vi[key],
        isA<String>().having((v) => v.trim(), 'value', isNotEmpty),
        reason: key,
      );
    }
    expect(_keys(vi).toSet(), _keys(en).toSet());
  });

  test('the tab labels follow navigation.md in both languages', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final vi = lookupAppLocalizations(const Locale('vi'));

    expect(
      [en.navLibrary, en.navStudy, en.navProgress, en.navSettings],
      ['Library', 'Study', 'Progress', 'Settings'],
    );
    expect(
      [vi.navLibrary, vi.navStudy, vi.navProgress, vi.navSettings],
      ['Thư viện', 'Học', 'Tiến độ', 'Cài đặt'],
    );
  });

  testWidgets('context.l10n resolves the active locale', (tester) async {
    late String title;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            title = context.l10n.placeholderTitle;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(title, 'Sắp có');
  });
}
