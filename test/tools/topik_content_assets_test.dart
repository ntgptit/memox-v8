import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/topik/topik_lint.dart';

// BR-TOPIK-008: no content pack that breaks a rule can merge.

void main() {
  test('every bundled TOPIK pack passes the content check', () {
    final report = lintTopikContent(
      contentRoot: Directory('assets/topik'),
      bundleRoot: Directory.current,
    );
    expect(report.issues.where((issue) => issue.isError), isEmpty);
  });
}
