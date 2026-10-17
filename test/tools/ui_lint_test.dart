import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/ui_lint/ui_rules.dart';

String _abs(String p) => File(p).absolute.path;

// Not `_abs('.')`, which ends in `/.` and leaves every reported path absolute.
final String _root = Directory.current.absolute.path;

const String _negative = 'tools/ui_lint/fixtures/negative';

// The positive fixtures mirror the repository tree (lib/shared/widgets/...),
// so they are linted from their own root and the owner paths apply to them.
const String _positive = 'tools/ui_lint/fixtures/positive';

List<String> _dartFiles(String dir) => [
  for (final entity in Directory(dir).listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart')) entity.absolute.path,
];

// Each lintPaths call builds a cold analysis context, about 9 s before the
// first file resolves, so each fixture folder is resolved once for every test
// that reads it (lazy: on the first test that awaits it).
final Future<List<UiViolation>> _negativeHits = lintPaths(
  _dartFiles(_negative),
  root: _root,
  allowlist: const [],
);

final Future<List<UiViolation>> _positiveHits = lintPaths(
  _dartFiles(_positive),
  root: _abs(_positive),
  allowlist: const [],
);

int _count(List<UiViolation> violations, String file, String rule) =>
    violations.where((v) => v.path.endsWith(file) && v.rule == rule).length;

void main() {
  test('every negative fixture trips the rule its name carries', () async {
    final violations = await _negativeHits;
    for (final file in Directory(_negative).listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      final rule = name.substring(0, 5).toUpperCase();
      expect(
        _count(violations, name, rule),
        isPositive,
        reason: '$name should trip $rule',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
    'aliased Cupertino import and Switch.adaptive are both caught',
    () async {
      final violations = await _negativeHits;
      expect(_count(violations, 'uil02_aliased_import.dart', 'UIL02'), 2);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('positive fixtures are clean', () async {
    expect(await _positiveHits, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a fixture with several constructs reports every one of them', () async {
    final violations = await _negativeHits;
    const expected = {
      'uil01_overlay_bypass.dart': 10,
      'uil01_forui_overlay.dart': 4,
      'uil01_overlay_route_subclass.dart': 3,
      'uil02_cupertino_adaptive.dart': 17,
      // A whole import, a prefix, ElevatedButton in a show list, an src/
      // import, and Scaffold outside the shell.
      'uil03_material_import.dart': 5,
      'uil04_literal_barrier.dart': 5,
      'uil05_theme_platform.dart': 2,
      'uil05_seed_scheme.dart': 2,
      'uil05_theme_construction.dart': 4,
    };
    for (final MapEntry(key: file, value: count) in expected.entries) {
      final rule = file.substring(0, 5).toUpperCase();
      expect(_count(violations, file, rule), count, reason: file);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('the theme owner, the overlay adapter, the shell, the app root and '
      'a feature each pass the rules their path allows', () async {
    final linted = {
      for (final path in _dartFiles(_positive))
        relativeToRoot(path, _abs(_positive)),
    };
    expect(linted, {
      'lib/app/app.dart',
      'lib/core/theme/app_theme.dart',
      'lib/features/deck/deck_list.dart',
      'lib/shared/widgets/mx_app_shell.dart',
      'lib/shared/widgets/mx_dialog.dart',
    });
  });

  test('the same constructs fail outside their owners', () async {
    final violations = await _negativeHits;
    // A ForUI import in a file outside lib/core/theme, lib/shared, lib/app.
    expect(_count(violations, 'uil06_forui_import.dart', 'UIL06'), 1);
    expect(_count(violations, 'uil01_forui_overlay.dart', 'UIL06'), 1);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a Windows path becomes a forward-slash path relative to the root', () {
    const found = r'C:\x\lib\core\theme\f.dart';
    expect(relativeToRoot(found, r'C:\x'), 'lib/core/theme/f.dart');
    expect(relativeToRoot(found, 'C:\\x\\'), 'lib/core/theme/f.dart');
    expect(relativeToRoot('/x/lib/a.dart', '/x'), 'lib/a.dart');
  });

  test('an allowlist entry matches a path whichever separator it uses', () {
    const violation = UiViolation(
      rule: 'UIL01',
      path: 'lib/shared/widgets/mx_dialog.dart',
      line: 18,
      message: 'm',
    );
    const entry = AllowEntry(
      file: r'lib\shared\widgets\mx_dialog.dart',
      rule: 'UIL01',
      reason: 'r',
      owner: 'o',
      review: '2027-01-01',
    );
    expect(applyAllowlist([violation], [entry]), isEmpty);
  });

  test('an allowlist entry without a reason is rejected', () {
    final file = File('${Directory.systemTemp.createTempSync().path}/a.json')
      ..writeAsStringSync('[{"file":"lib/x.dart","rule":"UIL01"}]');
    expect(() => loadAllowlist(file.path), throwsFormatException);
  });

  group('allowlist review date', () {
    const violation = UiViolation(
      rule: 'UIL01',
      path: 'lib/x.dart',
      line: 1,
      message: 'm',
    );
    AllowEntry entry(String review) => AllowEntry(
      file: 'lib/x.dart',
      rule: 'UIL01',
      reason: 'r',
      owner: 'o',
      review: review,
    );

    test('an entry whose review day has passed is reported as UIL00', () {
      final result = applyAllowlist(
        [violation],
        [entry('2026-10-14')],
        today: DateTime(2026, 10, 15),
      );
      expect(result.map((v) => v.rule), ['UIL00']);
      expect(result.single.message, contains('expired'));
      expect(result.single.message, contains('2026-10-14'));
    });

    test('an entry reviewed today or later stays silent', () {
      for (final review in ['2026-10-15', '2027-04-15']) {
        final result = applyAllowlist(
          [violation],
          [entry(review)],
          today: DateTime(2026, 10, 15),
        );
        expect(result, isEmpty, reason: review);
      }
    });

    test('a date that is not strictly YYYY-MM-DD is rejected', () {
      final dir = Directory.systemTemp.createTempSync();
      for (final review in [
        '2027-4-15',
        '2027/04/15',
        '20270415',
        '2027-04-15T00:00:00',
        '2027-02-30',
        '2027-13-01',
        ' 2027-04-15',
      ]) {
        final file = File('${dir.path}/a.json')
          ..writeAsStringSync(
            '[{"file":"lib/x.dart","rule":"UIL01","reason":"r",'
            '"owner":"o","review":"$review"}]',
          );
        expect(
          () => loadAllowlist(file.path),
          throwsFormatException,
          reason: review,
        );
      }
    });

    test('the committed allowlist loads and has not expired', () {
      final entries = loadAllowlist('tools/ui_lint/allowlist.json');
      final result = applyAllowlist(
        const [],
        entries,
        today: DateTime(2026, 10, 15),
      );
      expect(result.where((v) => v.message.contains('expired')), isEmpty);
    });
  });

  group('a lint of some files (dod_check.sh --changed)', () {
    const entry = AllowEntry(
      file: 'lib/shared/widgets/mx_dialog.dart',
      rule: 'UIL01',
      reason: 'r',
      owner: 'o',
      review: '2027-01-01',
    );

    test('an entry for a file outside the linted ones is not stale', () {
      final result = applyAllowlist(
        const [],
        [entry],
        today: DateTime(2026, 10, 15),
        linted: const {'lib/features/deck/a.dart'},
      );
      expect(result, isEmpty);
    });

    test('an entry for a linted file that covers nothing is stale', () {
      final result = applyAllowlist(
        const [],
        [entry],
        today: DateTime(2026, 10, 15),
        linted: const {'lib/shared/widgets/mx_dialog.dart'},
      );
      expect(result.single.message, contains('stale'));
    });

    test('an expired entry is reported whichever files were linted', () {
      final result = applyAllowlist(
        const [],
        [entry],
        today: DateTime(2027, 01, 02),
        linted: const {},
      );
      expect(result.single.message, contains('expired'));
    });

    test('no file to lint resolves nothing and reports only expiry', () async {
      final result = await lintPaths(
        const [],
        root: _root,
        allowlist: [entry],
        today: DateTime(2026, 10, 15),
        partial: true,
      );
      expect(result, isEmpty);
    });
  });

  test('an allowlist entry that suppresses nothing is reported', () async {
    final violations = await lintPaths(
      [_abs('$_positive/lib/features/deck/deck_list.dart')],
      root: _abs(_positive),
      allowlist: [
        const AllowEntry(
          file: 'lib/features/deck/deck_list.dart',
          rule: 'UIL01',
          reason: 'r',
          owner: 'o',
          review: '2027-01-01',
        ),
      ],
    );
    expect(violations.single.rule, 'UIL00');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
