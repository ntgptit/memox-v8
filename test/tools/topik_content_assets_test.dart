import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tools/topik/topik_lint.dart';

// BR-TOPIK-008, spec §13.4: no content pack that breaks a rule can merge,
// and every folder it needs is declared, so the app bundles what the gate saw.

void main() {
  test('every bundled TOPIK pack passes and every folder is declared', () {
    final report = lintTopikContent(
      contentRoot: Directory('assets/topik'),
      bundleRoot: Directory.current,
      declaredAssetFolders: declaredAssetFoldersOf(
        File('pubspec.yaml').readAsStringSync(),
      ),
    );
    expect(report.issues.where((issue) => issue.isError), isEmpty);
  });
}
