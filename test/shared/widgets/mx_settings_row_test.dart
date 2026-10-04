import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

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
  testWidgets('navigation shows the chevron and opens', (tester) async {
    var opened = 0;
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.navigation(
          title: 'Account',
          icon: Icons.person,
          onTap: () => opened++,
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    await tester.tap(find.text('Account'));
    expect(opened, 1);
  });

  testWidgets('an action row shows no chevron and is a button', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.action(
          title: 'Sign out',
          icon: Icons.logout,
          onTap: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(
      tester.getSemantics(find.text('Sign out')),
      isSemantics(label: 'Sign out', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('a following value reads in full in on-surface-variant', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        const MxSettingsRow.value(
          title: 'Review order',
          icon: Icons.sort,
          value: 'Due first',
        ),
      ),
    );
    expect(_opacityOver(tester, find.text('Due first')), 1);
    expect(
      tester.widget<Text>(find.text('Due first')).style?.color,
      mxThemes['light']!.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('the whole toggle row is one switch', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    final List<bool> changes = [];
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.toggle(
          title: 'Daily reminder',
          subtitle: 'At 20:00',
          icon: Icons.notifications,
          isOn: false,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.text('Daily reminder'));
    await tester.tap(find.byType(MxToggle));
    expect(changes, [true, true]);
    expect(
      tester.getSemantics(find.text('Daily reminder')),
      isSemantics(
        label: 'Daily reminder\nAt 20:00',
        hasToggledState: true,
        isToggled: false,
      ),
    );
    semantics.dispose();
  });

  testWidgets('disabled dims tile, label and chevron, not the reason', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.navigation(
          title: 'Sync',
          subtitle: 'Available when you are online',
          icon: Icons.sync,
          onTap: () {},
          isEnabled: false,
        ),
      ),
    );
    expect(_opacityOver(tester, find.text('Sync')), AppOpacity.disabled);
    expect(_opacityOver(tester, find.byType(MxIconTile)), AppOpacity.disabled);
    expect(
      _opacityOver(tester, find.byIcon(Icons.chevron_right)),
      AppOpacity.disabled,
    );
    expect(_opacityOver(tester, find.text('Available when you are online')), 1);
  });

  testWidgets('a disabled toggle is not dimmed twice', (tester) async {
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.toggle(
          title: 'Daily reminder',
          icon: Icons.notifications,
          isOn: true,
          onChanged: (_) {},
          isEnabled: false,
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.byType(MxToggle),
        matching: find.descendant(
          of: find.byType(MxSettingsRow),
          matching: find.byType(Opacity),
        ),
      ),
      findsNothing,
    );
    expect(tester.widget<MxToggle>(find.byType(MxToggle)).onChanged, isNull);
  });

  testWidgets('at twice the text the label wraps beside its value', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MxSettingsRow.value(
            title: 'Cards per session',
            icon: Icons.layers,
            value: '20',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a long value wraps beside the label instead of overflowing', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _in(
        const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: MxSettingsRow.value(
            title: 'Card language',
            icon: Icons.translate,
            value: 'Brazilian Portuguese, São Paulo',
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('the label keeps one line and is read whole; the reason two', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    const String long = 'Show the answer side first when a card is new to you';
    await pumpMx(
      tester,
      _in(
        MxSettingsRow.navigation(
          title: long,
          subtitle:
              'Applies to every deck, the ones you add later included, '
              'until you change it here again',
          icon: Icons.flip,
          onTap: () {},
        ),
      ),
    );
    expect(tester.widget<Text>(find.text(long)).maxLines, 1);
    expect(tester.widget<Text>(find.textContaining('Applies')).maxLines, 2);
    expect(tester.getSemantics(find.text(long)).label, startsWith('$long\n'));
    semantics.dispose();
  });

  testWidgets('a toggle that cannot change now reads disabled', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      _in(
        const MxSettingsRow.toggle(
          title: 'Daily reminder',
          icon: Icons.notifications,
          isOn: false,
          onChanged: null,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.text('Daily reminder')),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    semantics.dispose();
  });

  testWidgets('the keyboard ring sits inside the row, clear of a card clip', (
    tester,
  ) async {
    final Widget row = _in(
      MxSettingsRow.navigation(
        title: 'Account',
        icon: Icons.person,
        onTap: () {},
      ),
    );
    await pumpMx(tester, row);
    await expectMxKeyboardRingOnly(
      tester,
      row,
      painted: tester.getSize(find.byType(MxSettingsRow)),
      isInset: true,
    );
  });
}
