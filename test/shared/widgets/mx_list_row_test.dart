import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';

import '../../support/widget_harness.dart';

const _first = ValueKey('row-1');
const _second = ValueKey('row-2');

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('one-line title and sub; 16 inset; 48 floor', (tester) async {
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
    expect(
      tester.getSize(find.byType(MxListRow)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('a long title stays one line at 2x; rows keep one height', (
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
      textScale: 2,
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

  testWidgets('divider unless last; disabled dims and ignores taps', (
    tester,
  ) async {
    BoxBorder? edge() =>
        (tester
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: find.byType(MxListRow),
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .border;

    await pumpMx(tester, _width(const MxListRow(title: 'Kana')));
    expect(edge(), isNotNull);
    await pumpMx(
      tester,
      _width(const MxListRow(title: 'Kana', hasDivider: false)),
    );
    expect(edge(), isNull);

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
    expect(spans[1].style!.fontWeight, FontWeight.w700);
    expect(spans[1].style!.color, MxDerivedColors.primaryInkOf(scheme));
    expect((title.maxLines, title.overflow), (1, TextOverflow.ellipsis));
  });

  testWidgets('a title match lies inside the title', (tester) async {
    await pumpMx(
      tester,
      _width(const MxListRow(title: 'abc', titleMatch: (2, 4))),
    );

    expect(tester.takeException(), isAssertionError);
  });
}
