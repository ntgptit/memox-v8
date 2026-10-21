import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/study/presentation/widgets/support/study_whole_word_text_widget.dart';

import '../../../support/widget_harness.dart';
import '../../../support/wrap_rule.dart';

// A study face's text that must stay whole wraps between words, and a word
// wider than the space draws the text just small enough to fit it (FE-A6
// D19). Owner 2026-10-21: the fit is measured as the text is drawn, so the
// system's bold text never breaks the word it was sized for. In the term
// role (500) of Guess and Recall, as bold draws it heavier.

const _text = 'Internationalisation và đa ngôn ngữ';

void main() {
  for (final isBold in [false, true]) {
    for (final textScale in [1.0, 1.3, 2.0]) {
      testWidgets('no word breaks inside, at any width (bold $isBold, scale '
          '$textScale)', (tester) async {
        for (var width = 120.0; width <= 320; width += 4) {
          await pumpMx(
            tester,
            SizedBox(
              width: width,
              child: Builder(
                builder: (context) =>
                    StudyWholeWordTextWidget(_text, style: context.texts.term),
              ),
            ),
            textScale: textScale,
            isBoldText: isBold,
          );
          expectBreaksOnlyBetweenWords(tester, find.text(_text));
          expect(tester.takeException(), isNull, reason: 'width $width');
        }
      });
    }
  }
}
