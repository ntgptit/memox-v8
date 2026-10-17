import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../tools/design/design_doc.dart';

// DESIGN.md's frontmatter and the token part of .impeccable/design.json are
// rendered from the production ForUI themes (ADR-026); the committed files
// must equal that rendering. Rewrite them after a palette, type or spacing
// change with:
//   MEMOX_WRITE_DESIGN_DOCS=1 flutter test test/tools/design_doc_test.dart
const String _designPath = 'DESIGN.md';
const String _sidecarPath = '.impeccable/design.json';
const String _writeFlag = 'MEMOX_WRITE_DESIGN_DOCS';

bool get _writing => Platform.environment[_writeFlag] == '1';

/// [document]'s frontmatter, `---` through the closing `---` line.
String _frontmatterOf(String document) {
  final end = document.indexOf('\n---\n', 4);
  if (!document.startsWith('---\n') || end < 0) return '';
  return document.substring(0, end + 5);
}

void main() {
  test('DESIGN.md frontmatter equals the rendering of the production '
      'theme', () {
    final file = File(_designPath);
    final document = file.readAsStringSync();
    final committed = _frontmatterOf(document);
    final rendered = renderFrontmatter(buildLightTheme());
    if (_writing && committed != rendered) {
      file.writeAsStringSync(rendered + document.substring(committed.length));
      return;
    }
    expect(
      committed,
      rendered,
      reason: 'run with $_writeFlag=1 to rewrite the frontmatter',
    );
  });

  test('.impeccable/design.json equals the rendering of the production '
      'themes, its narrative kept', () {
    final file = File(_sidecarPath);
    final committed = file.readAsStringSync();
    final narrative =
        (jsonDecode(committed) as Map<String, Object?>)['narrative']!
            as Map<String, Object?>;
    final rendered = renderSidecar(
      buildLightTheme(),
      buildDarkTheme(),
      narrative,
    );
    if (_writing && committed != rendered) {
      file.writeAsStringSync(rendered);
      return;
    }
    expect(
      committed,
      rendered,
      reason: 'run with $_writeFlag=1 to rewrite the sidecar',
    );
  });

  test('every colour of the frontmatter is a palette value', () {
    final front = renderFrontmatter(buildLightTheme());
    expect(front, contains('primary: "#564BCB"'));
    expect(front, contains('barrier: "#00000033"'));
    expect(front, contains('success: "#006C49"'));
  });
}
