import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import 'support/mx_harness.dart';

Widget _in(Widget row) => SizedBox(width: 380, child: row);

double _opacityOver(WidgetTester tester, Finder finder) {
  final Finder dim = find.ancestor(of: finder, matching: find.byType(Opacity));
  if (dim.evaluate().isEmpty) {
    return 1;
  }
  return tester.widget<Opacity>(dim.first).opacity;
}

void main() {
  testWidgets('48 at least; 16 across and 12 down', (tester) async {
    await pumpMx(tester, _in(const MxListRow(title: 'Spanish')));
    final Rect row = tester.getRect(find.byType(MxListRow));
    final Rect title = tester.getRect(find.text('Spanish'));
    expect(row.height, greaterThanOrEqualTo(AppSize.tapTarget));
    expect(title.left - row.left, 16);
    expect(title.top - row.top, 12);
  });

  testWidgets('a leading tile is the medium icon tile, 12 from the text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(const MxListRow(title: 'Spanish', icon: Icons.style)),
    );
    final Rect tile = tester.getRect(find.byType(MxIconTile));
    expect(tile.width, AppSize.iconTileMedium);
    expect(tester.getRect(find.text('Spanish')).left - tile.right, 12);
  });

  testWidgets('the title keeps one line and is read whole', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    const String long =
        'Irregular verbs of the past tense with every exception, chapter twelve';
    await pumpMx(
      tester,
      _in(const MxListRow(title: long, subtitle: 'Due today')),
    );
    expect(tester.renderObject<RenderParagraph>(find.text(long)).maxLines, 1);
    expect(
      tester.getSemantics(find.byType(MxListRow)),
      isSemantics(label: '$long\nDue today'),
    );
    semantics.dispose();
  });

  testWidgets('the subtitle wraps to two lines at most', (tester) async {
    await pumpMx(
      tester,
      _in(
        const MxListRow(
          title: 'Spanish',
          subtitle:
              'Was in Library › Languages › Spanish › Verbs, removed on Monday '
              'by you, and kept for thirty days before it goes for good',
        ),
      ),
    );
    expect(tester.widget<Text>(find.textContaining('Was in')).maxLines, 2);
  });

  testWidgets('a tappable row is a button with the keyboard ring', (
    tester,
  ) async {
    var taps = 0;
    final Widget row = _in(
      MxListRow(
        title: 'Spanish',
        trailing: const MxListRowTrailing.chevron(),
        onTap: () => taps++,
      ),
    );
    await pumpMx(tester, row);
    await tester.tap(find.text('Spanish'));
    expect(taps, 1);
    await expectMxKeyboardRingOnly(
      tester,
      row,
      painted: tester.getSize(find.byType(MxListRow)),
    );
  });

  testWidgets('a disabled row dims its mark and title, never its subtitle', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MxListRow(
          title: 'Spanish',
          subtitle: 'Available when you are online',
          icon: Icons.cloud,
          trailing: const MxListRowTrailing.chevron(),
          onTap: () {},
          isEnabled: false,
        ),
      ),
    );
    expect(_opacityOver(tester, find.text('Spanish')), AppOpacity.disabled);
    expect(_opacityOver(tester, find.byType(MxIconTile)), AppOpacity.disabled);
    expect(
      _opacityOver(tester, find.byIcon(Icons.chevron_right)),
      AppOpacity.disabled,
    );
    expect(_opacityOver(tester, find.text('Available when you are online')), 1);
  });

  testWidgets('a selecting row reads checked', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _in(MxListRow(title: 'hola', isChecked: true, onTap: () {})),
    );
    expect(
      tester.getSemantics(find.text('hola')),
      isSemantics(isChecked: true, hasCheckedState: true, isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('a badge and a value read with the row', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _in(
        const MxListRow(
          title: 'Spanish',
          trailing: MxListRowTrailing.badge('3 days left', MxBadgeTone.warning),
        ),
      ),
    );
    expect(find.byType(MxBadge), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Spanish')),
      isSemantics(label: 'Spanish\n3 days left'),
    );
    await pumpMx(
      tester,
      _in(
        const MxListRow(
          title: 'Cards',
          trailing: MxListRowTrailing.value('120'),
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('120')).style?.color,
      mxThemes['light']!.colorScheme.onSurfaceVariant,
    );
    semantics.dispose();
  });

  testWidgets('a trailing action is its own node beside the row', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    var opened = 0;
    var more = 0;
    await pumpMx(
      tester,
      _in(
        MxListRow(
          title: 'Spanish',
          onTap: () => opened++,
          trailing: MxListRowTrailing.iconButton(
            MxIconButton(
              icon: Icons.more_vert,
              semanticLabel: 'More for Spanish',
              onPressed: () => more++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    expect((opened, more), (0, 1));
    expect(
      tester.getSemantics(find.text('Spanish')).label,
      isNot(contains('More for Spanish')),
    );
    semantics.dispose();
  });

  testWidgets('in right-to-left text the chevron leads from the left', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MxListRow(
          title: 'Spanish',
          trailing: const MxListRowTrailing.chevron(),
          onTap: () {},
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    expect(
      tester.getRect(find.byIcon(Icons.chevron_right)).left,
      lessThan(tester.getRect(find.text('Spanish')).left),
    );
  });

  testWidgets('a disabled row does not run its tap', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      _in(MxListRow(title: 'Sync', onTap: () => taps++, isEnabled: false)),
    );
    await tester.tap(find.text('Sync'));
    expect(taps, 0);
  });

  testWidgets('at twice the text a full row neither clips nor overflows', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MxListRow(
            title: 'Japanese kana',
            subtitle: '46 cards · reviewed today',
            icon: Icons.style,
            trailing: const MxListRowTrailing.badge('3 days left'),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long value wraps beside the title instead of overflowing', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MxListRow(
            title: 'Card language',
            trailing: MxListRowTrailing.value(
              'Brazilian Portuguese, São Paulo',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
