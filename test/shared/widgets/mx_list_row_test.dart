import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';

import '../../support/theme_expect.dart';

import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../support/widget_harness.dart';

const _first = ValueKey('row-1');
const _second = ValueKey('row-2');

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  final scheme = lightColorScheme;

  testWidgets('one-line title and sub; 16 inset; 72 two-line floor', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxListRow(
          title: 'Kanji N5',
          subtitle: '42 cards',
          leading: MxIconTile(icon: AppIcons.library),
        ),
      ),
    );
    final title = tester.widget<Text>(find.text('Kanji N5'));
    final sub = tester.widget<Text>(find.text('42 cards'));

    expect((title.maxLines, title.overflow), (1, TextOverflow.ellipsis));
    expect((sub.maxLines, sub.overflow), (1, TextOverflow.ellipsis));
    expect(title.style!.fontSize, 14);
    expect(sub.style!.color, scheme.onSurfaceVariant);
    expect(
      tester.getTopLeft(find.byType(MxIconTile)).dx -
          tester.getTopLeft(find.byType(MxListRow)).dx,
      16,
    );
    expect(
      tester.getTopLeft(find.text('42 cards')).dy -
          tester.getBottomLeft(find.text('Kanji N5')).dy,
      2,
    );
    expect(tester.getSize(find.byType(MxListRow)).height, 72);
  });

  testWidgets('M3 list item heights: 56 for one line, 72 with a supporting '
      'line or a meta slot', (tester) async {
    await pumpMx(tester, _width(const MxListRow(title: 'Kanji N5')));
    expect(tester.getSize(find.byType(MxListRow)).height, 56);

    await pumpMx(
      tester,
      _width(const MxListRow(title: 'Kanji N5', subtitle: '42 cards')),
    );
    expect(tester.getSize(find.byType(MxListRow)).height, 72);

    await pumpMx(
      tester,
      _width(const MxListRow(title: 'Kanji N5', meta: Text('42 cards'))),
    );
    expect(tester.getSize(find.byType(MxListRow)).height, 72);
  });

  testWidgets('a long title stays one line; rows keep one height', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        Column(
          children: [
            MxListRow(
              key: _first,
              title: List.filled(12, 'Từ vựng tiếng Nhật').join(' '),
              subtitle: '42 cards',
            ),
            const MxListRow(key: _second, title: 'Kana', subtitle: '46 cards'),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(_first)).height,
      tester.getSize(find.byKey(_second)).height,
    );
  });

  testWidgets('a trailing control keeps its own node and tap (RF3)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var rowTaps = 0;
    var menuTaps = 0;
    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Kanji N5',
          subtitle: '42 cards',
          onTap: () => rowTaps++,
          trailing: MxIconButton(
            icon: AppIcons.more,
            semanticLabel: 'Deck actions',
            onPressed: () => menuTaps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Deck actions'));
    expect((rowTaps, menuTaps), (0, 1));
    await tester.tap(find.text('Kanji N5'));
    expect(rowTaps, 1);

    final row = tester.getSemantics(find.text('Kanji N5'));
    expect(row, isSemantics(label: 'Kanji N5\n42 cards', isButton: true));
    expect(
      tester.getSemantics(find.byTooltip('Deck actions')).id,
      isNot(row.id),
    );
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets('a 48 trailing control does not grow the row', (tester) async {
    await pumpMx(
      tester,
      _width(
        Column(
          children: [
            MxListRow(
              key: _first,
              title: 'Kanji N5',
              subtitle: '42 cards',
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'Deck actions',
                onPressed: () {},
              ),
              onTap: () {},
            ),
            MxListRow(
              key: _second,
              title: 'Kana',
              subtitle: '46 cards',
              hasChevron: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(_first)).height,
      tester.getSize(find.byKey(_second)).height,
    );
  });

  testWidgets('chevron and busy spinner fill the trailing slot', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(MxListRow(title: 'Kanji N5', hasChevron: true, onTap: () {})),
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.chevronRight)).color,
      scheme.onSurfaceVariant,
    );

    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Kanji N5',
          hasChevron: true,
          isBusy: true,
          onTap: () {},
        ),
      ),
    );
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
  });

  testWidgets('disabled dims and ignores taps', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Grammar',
          subtitle: 'Cannot hold another deck',
          isEnabled: false,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.text('Grammar'), warnIfMissed: false);
    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Grammar'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });

  testWidgets('a disabled row keeps its subtitle at full strength and dims its '
      'leading, title and chevron (DEV-230)', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Grammar',
          subtitle: 'Holds other decks',
          leading: const MxIconTile(icon: AppIcons.library),
          hasChevron: true,
          isEnabled: false,
          onTap: () {},
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.text('Holds other decks'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    for (final dimmed in [
      find.text('Grammar'),
      find.byType(MxIconTile),
      find.byIcon(AppIcons.chevronRight),
    ]) {
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: dimmed, matching: find.byType(Opacity)),
            )
            .opacity,
        0.38,
      );
    }
  });

  testWidgets('a disabled row keeps its meta at full strength (DEV-230)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Kana',
          meta: const Text('No cards yet', key: ValueKey('meta')),
          isEnabled: false,
          onTap: () {},
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('meta')),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(of: find.text('Kana'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
  });

  test('subtitle or meta, trailing or chevron', () {
    expect(
      () => MxListRow(title: 'a', subtitle: 'b', meta: const SizedBox()),
      throwsAssertionError,
    );
    expect(
      () => MxListRow(title: 'a', trailing: const SizedBox(), hasChevron: true),
      throwsAssertionError,
    );
  });

  testWidgets('a title match is drawn in the match role, on one line', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(const MxListRow(title: 'Academic words', titleMatch: (9, 14))),
    );
    final title = tester.widget<Text>(find.text('Academic words'));
    final spans = (title.textSpan! as TextSpan).children!.cast<TextSpan>();

    expect([for (final span in spans) span.text], ['Academic ', 'words', '']);
    expect(
      spans[1].style!.fontWeight,
      tester.element(find.text('Academic words')).texts.itemTitle.fontWeight,
    );
    expect(spans[1].style!.color, accentOf(scheme));
    expect((title.maxLines, title.overflow), (1, TextOverflow.ellipsis));
  });

  testWidgets('a title match lies inside the title', (tester) async {
    await pumpMx(
      tester,
      _width(const MxListRow(title: 'abc', titleMatch: (2, 4))),
    );

    expect(tester.takeException(), isAssertionError);
  });
  testWidgets('a user-named row may take two lines and keeps its divider', (
    tester,
  ) async {
    const name = 'Cấu trúc thường gặp trong đề thi TOPIK II phần đọc hiểu';
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxListRow(title: name, subtitle: '12 cards', titleMaxLines: 2),
      ),
    );
    final text = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == name,
      ),
    );

    expect(text.maxLines, 2);
    expect(text.softWrap, isTrue);
    expect(
      tester.getSize(find.byType(MxListRow)).height,
      greaterThanOrEqualTo(const AppDimens().sizeControl),
    );
  });

  // A badge of 1 to 3 digits leads the TOPIK test rows: the title column must
  // not follow its width (impeccable 2026-10-17).
  testWidgets('hasStableLeading: leadings of 20 and 36 start the title at the '
      'same x, a list row wide from the row start', (tester) async {
    Widget row(Key key, double lead, {bool isStable = true}) => MxListRow(
      key: key,
      title: 'Title',
      hasStableLeading: isStable,
      leading: SizedBox(key: ValueKey('lead-$lead'), width: lead, height: 22),
    );
    await pumpMx(
      tester,
      _width(Column(children: [row(_first, 20), row(_second, 36)])),
    );
    final titles = find.text('Title');
    final first = tester.getTopLeft(titles.at(0)).dx;
    final second = tester.getTopLeft(titles.at(1)).dx;

    expect(first, second);
    // 16 inset + the list-row column + the 12 gap.
    expect(first, 16 + const AppDimens().sizeListRow + 12);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('lead-20.0'))).dx,
      tester.getTopLeft(find.byKey(_first)).dx + 16,
      reason: 'the leading stays on the screen margin',
    );
  });

  testWidgets('hasStableLeading holds a "#100" badge as well as a "#96" one', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const Column(
          children: [
            MxListRow(
              title: 'Title',
              hasStableLeading: true,
              leading: MxBadge(label: '#96'),
            ),
            MxListRow(
              title: 'Title',
              hasStableLeading: true,
              leading: MxBadge(label: '#100'),
            ),
          ],
        ),
      ),
    );
    final titles = find.text('Title');

    expect(
      tester.getTopLeft(titles.at(0)).dx,
      tester.getTopLeft(titles.at(1)).dx,
    );
  });

  testWidgets('without hasStableLeading the leading keeps its own width', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const Column(
          children: [
            MxListRow(title: 'Title', leading: SizedBox(width: 20, height: 22)),
            MxListRow(title: 'Title', leading: SizedBox(width: 36, height: 22)),
          ],
        ),
      ),
    );
    final titles = find.text('Title');

    expect(
      tester.getTopLeft(titles.at(1)).dx - tester.getTopLeft(titles.at(0)).dx,
      16,
    );
  });
}
