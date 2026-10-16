import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Expects one [Text] found by [finder], breaking only where a word ends
/// (The Wrap Rule): a glued run longer than its line is broken inside a word,
/// which is the defect this catches.
void expectBreaksOnlyBetweenWords(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: finder, matching: find.byType(RichText)).first,
  );
  // The same text laid out at the paragraph's width, to read its lines.
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
    locale: paragraph.locale,
    strutStyle: paragraph.strutStyle,
    textWidthBasis: paragraph.textWidthBasis,
  )..layout(maxWidth: paragraph.size.width);
  addTearDown(painter.dispose);
  final text = paragraph.text.toPlainText();
  final breaks = <int>{};
  for (var offset = 0; offset < text.length; offset++) {
    final end = painter.getLineBoundary(TextPosition(offset: offset)).end;
    if (end > 0 && end < text.length) breaks.add(end);
  }
  bool isWordCharacter(String character) =>
      RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(character);
  for (final end in breaks) {
    expect(
      isWordCharacter(text[end - 1]) && isWordCharacter(text[end]),
      isFalse,
      reason:
          'a line breaks inside a word: "${text.substring(0, end)}|'
          '${text.substring(end)}"',
    );
  }
}
