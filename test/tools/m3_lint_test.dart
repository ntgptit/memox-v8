import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/m3_lint/m3_rules.dart';

String _abs(String p) => File(p).absolute.path;

Future<List<M3Violation>> _lint(String dir) {
  final files = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map((f) => f.absolute.path)
      .toList();
  return lintPaths(files, root: _abs('.'), allowlist: const []);
}

void main() {
  test('every negative fixture trips the rule its name carries', () async {
    final violations = await _lint('tools/m3_lint/fixtures/negative');
    final dir = Directory('tools/m3_lint/fixtures/negative');
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      final rule = name.substring(0, 5).toUpperCase();
      final hits = violations.where(
        (v) => v.path.endsWith(name) && v.rule == rule,
      );
      expect(hits, isNotEmpty, reason: '$name should trip $rule');
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test(
    'aliased Cupertino import and Switch.adaptive are both caught',
    () async {
      final violations = await _lint('tools/m3_lint/fixtures/negative');
      final aliased = violations
          .where((v) => v.path.endsWith('m3l02_aliased_import.dart'))
          .toList();
      expect(aliased.length, 2);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('positive fixtures are clean', () async {
    expect(await _lint('tools/m3_lint/fixtures/positive'), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a fixture with several constructs reports every one of them', () async {
    final violations = await _lint('tools/m3_lint/fixtures/negative');
    const expected = {
      'm3l01_overlay_bypass.dart': 7,
      'm3l01_overlay_route_subclass.dart': 3,
      'm3l02_cupertino_adaptive.dart': 17,
      'm3l04_literal_barrier.dart': 5,
      'm3l05_theme_platform.dart': 2,
      'm3l06_seed_scheme.dart': 2,
    };
    for (final entry in expected.entries) {
      final rule = entry.key.substring(0, 5).toUpperCase();
      final count = violations.where(
        (v) => v.path.endsWith(entry.key) && v.rule == rule,
      );
      expect(count.length, entry.value, reason: entry.key);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a Windows path becomes a forward-slash path relative to the root', () {
    const found = r'C:\x\lib\core\theme\f.dart';
    expect(relativeToRoot(found, r'C:\x'), 'lib/core/theme/f.dart');
    expect(relativeToRoot(found, 'C:\\x\\'), 'lib/core/theme/f.dart');
    expect(relativeToRoot('/x/lib/a.dart', '/x'), 'lib/a.dart');
  });

  test('an allowlist entry matches a path whichever separator it uses', () {
    const violation = M3Violation(
      rule: 'M3L01',
      path: 'lib/shared/widgets/mx_dialog.dart',
      line: 18,
      message: 'm',
    );
    const entry = AllowEntry(
      file: r'lib\shared\widgets\mx_dialog.dart',
      rule: 'M3L01',
      reason: 'r',
      owner: 'o',
      review: '2027-01-01',
    );
    expect(applyAllowlist([violation], [entry]), isEmpty);
  });

  test('an allowlist entry without a reason is rejected', () {
    final file = File('${Directory.systemTemp.createTempSync().path}/a.json')
      ..writeAsStringSync('[{"file":"lib/x.dart","rule":"M3L01"}]');
    expect(() => loadAllowlist(file.path), throwsFormatException);
  });

  group('allowlist review date', () {
    const violation = M3Violation(
      rule: 'M3L01',
      path: 'lib/x.dart',
      line: 1,
      message: 'm',
    );
    AllowEntry entry(String review) => AllowEntry(
      file: 'lib/x.dart',
      rule: 'M3L01',
      reason: 'r',
      owner: 'o',
      review: review,
    );

    test('an entry whose review day has passed is reported as M3L00', () {
      final result = applyAllowlist(
        [violation],
        [entry('2026-10-14')],
        today: DateTime(2026, 10, 15),
      );
      expect(result.map((v) => v.rule), ['M3L00']);
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
            '[{"file":"lib/x.dart","rule":"M3L01","reason":"r",'
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
      final entries = loadAllowlist('tools/m3_lint/allowlist.json');
      expect(entries, isNotEmpty);
      final result = applyAllowlist(
        const [],
        entries,
        today: DateTime(2026, 10, 15),
      );
      expect(result.where((v) => v.message.contains('expired')), isEmpty);
    });
  });

  test('an allowlist entry that suppresses nothing is reported', () async {
    final violations = await lintPaths(
      [_abs('tools/m3_lint/fixtures/positive/material_dialog_ok.dart')],
      root: _abs('.'),
      allowlist: [
        const AllowEntry(
          file: 'tools/m3_lint/fixtures/positive/material_dialog_ok.dart',
          rule: 'M3L01',
          reason: 'r',
          owner: 'o',
          review: '2027-01-01',
        ),
      ],
    );
    expect(violations.single.rule, 'M3L00');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
