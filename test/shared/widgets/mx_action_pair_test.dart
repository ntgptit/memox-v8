import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/widget_harness.dart';

MxButton _button(String label, {IconData? icon}) => MxButton(
  label: label,
  icon: icon,
  isBlock: true,
  isSingleLine: true,
  onPressed: () {},
);

Widget _bar(MxActionPair pair) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: pair);

Finder _labelled(String label) => find.widgetWithText(MxButton, label);

void main() {
  testWidgets('short labels sit side by side at equal widths, 8 apart', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _bar(MxActionPair(leading: _button('Back'), trailing: _button('Done'))),
    );
    final back = tester.getRect(_labelled('Back'));
    final done = tester.getRect(_labelled('Done'));

    expect(back.top, done.top);
    expect(back.width, done.width);
    expect(done.left - back.right, 8);
    expect(back.width + done.width + 8, 328);
  });

  testWidgets('side by side honours the flex shares', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Study'),
          trailing: _button('Done'),
          leadingFlex: 5,
          trailingFlex: 6,
        ),
      ),
    );
    final study = tester.getRect(_labelled('Study'));
    final done = tester.getRect(_labelled('Done'));

    expect(study.width / done.width, closeTo(5 / 6, 0.02));
  });

  testWidgets('a label that cannot fit its share stacks the pair, leading on '
      'top, full width, 8 apart', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Học lại bộ thẻ này', icon: Icons.play_arrow),
          trailing: _button('Xoá vĩnh viễn khỏi thùng rác', icon: Icons.delete),
        ),
      ),
    );
    final top = tester.getRect(_labelled('Học lại bộ thẻ này'));
    final bottom = tester.getRect(_labelled('Xoá vĩnh viễn khỏi thùng rác'));

    expect(top.width, 328);
    expect(bottom.width, 328);
    expect(bottom.top - top.bottom, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 2.0 stacks a pair that fits at 1.0', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Import another'),
          trailing: _button('View cards', icon: Icons.style),
        ),
      ),
      textScale: 2,
    );
    final first = tester.getRect(_labelled('Import another'));
    final second = tester.getRect(_labelled('View cards'));

    expect(second.top, greaterThan(first.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('no leading: the trailing button alone, full width', (
    tester,
  ) async {
    await pumpMx(tester, _bar(MxActionPair(trailing: _button('Close'))));

    expect(tester.getSize(find.byType(MxButton)).width, 328);
  });

  testWidgets('no paired label is ever ellipsized or wrapped', (tester) async {
    await pumpMx(
      tester,
      _bar(
        MxActionPair(
          leading: _button('Restore 2 cards', icon: Icons.restore),
          trailing: _button('Delete for good', icon: Icons.delete),
        ),
      ),
    );
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    }
    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.byType(RichText),
    );
    for (final paragraph in paragraphs) {
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  });
}
