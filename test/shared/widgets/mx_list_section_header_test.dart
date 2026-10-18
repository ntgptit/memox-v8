import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';

import '../../support/widget_harness.dart';

const _countKey = ValueKey('count');

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  testWidgets(
    'an uppercase labelSmall overline that reads the original label',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(tester, _width(const MxListSectionHeader(label: 'Hôm nay')));
      final text = tester.widget<Text>(find.text('HÔM NAY'));

      expect(text.style, tester.element(find.text('HÔM NAY')).texts.meta);
      expect(
        tester.getSemantics(find.text('HÔM NAY')),
        isSemantics(label: 'Hôm nay'),
      );
      handle.dispose();
    },
  );

  // SW-REV-006: the label that introduces a list is a heading, so TalkBack
  // can move between sections.
  testWidgets('the label is a heading for screen readers (audit 2026-10-07)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _width(const MxListSectionHeader(label: 'Decks')));

    expect(
      tester.getSemantics(find.text('DECKS')),
      isSemantics(label: 'Decks', isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('padding 0 4 8, or 2 4 8 after a filter band', (tester) async {
    await pumpMx(tester, _width(const MxListSectionHeader(label: 'Decks')));
    final header = tester.getTopLeft(find.byType(MxListSectionHeader));
    final label = tester.getRect(find.text('DECKS'));
    expect(label.topLeft - header, const Offset(4, 0));
    expect(
      tester.getSize(find.byType(MxListSectionHeader)).height,
      label.height + 8,
    );

    await pumpMx(
      tester,
      _width(
        const MxListSectionHeader(label: 'Decks', isAfterFilterBand: true),
      ),
    );
    expect(
      tester.getTopLeft(find.text('DECKS')) -
          tester.getTopLeft(find.byType(MxListSectionHeader)),
      const Offset(4, 2),
    );
  });

  testWidgets('the trailing affordance sits at the end, 4 inset', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxListSectionHeader(
          label: 'Decks',
          trailing: Text(12.toString(), key: _countKey),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_countKey)).dx -
          tester.getTopRight(find.text('DECKS')).dx,
      greaterThanOrEqualTo(8),
    );
    expect(tester.getTopRight(find.byKey(_countKey)).dx, 356);
  });

  testWidgets('a trailing too wide for the row moves under the label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxListSectionHeader(
          label: 'Decks',
          trailing: SizedBox(key: _countKey, width: 340, height: 20),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.byKey(_countKey)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('DECKS')).dy),
    );
  });
}
