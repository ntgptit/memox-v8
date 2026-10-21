import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expects no text under [finder] to be cut: none past its last line, where
/// an ellipsis or a hidden line would stand. A layout that chose a width for
/// it from a measurement short of what is drawn cuts it (owner 2026-10-21).
void expectNoTextCut(WidgetTester tester, Finder finder, {String? reason}) {
  final paragraphs = tester.renderObjectList<RenderParagraph>(
    find.descendant(
      of: finder,
      matching: find.byType(RichText),
      matchRoot: true,
    ),
  );
  for (final paragraph in paragraphs) {
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: '${reason ?? ''} "${paragraph.text.toPlainText()}" is cut',
    );
  }
}
