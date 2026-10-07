import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/widget_harness.dart';

const _controlKey = ValueKey('wide-control');

Widget _width(Widget child) => SizedBox(width: 360, child: child);

MxToggle _toggle() =>
    MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'Daily reminder');

void main() {
  testWidgets('a 36 tile centred in the 40 column; label 16; sub 4 below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Daily reminder',
          subtitle: 'One nudge a day',
          icon: AppIcons.reminder,
        ),
      ),
    );
    final row = tester.getTopLeft(find.byType(MxSettingsRow));

    expect(tester.getSize(find.byType(MxIconTile)), const Size.square(36));
    expect(tester.getTopLeft(find.byType(MxIconTile)).dx - row.dx, 18);
    expect(tester.getTopLeft(find.text('Daily reminder')).dx - row.dx, 72);
    expect(
      tester.widget<Text>(find.text('Daily reminder')).style!.fontSize,
      16,
    );
    expect(
      tester.getTopLeft(find.text('One nudge a day')).dy -
          tester.getBottomLeft(find.text('Daily reminder')).dy,
      4,
    );
    expect(
      tester.getSize(find.byType(MxSettingsRow)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the chevron shows only on a row that navigates', (tester) async {
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: 'Language', onTap: () {})),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);

    await pumpMx(
      tester,
      _width(MxSettingsRow(label: 'Daily reminder', trailing: _toggle())),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);

    await pumpMx(tester, _width(const MxSettingsRow(label: 'Version')));
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('a trailing toggle does not grow the row (Task 3 rule)', (
    tester,
  ) async {
    await pumpMx(tester, _width(const MxSettingsRow(label: 'Version')));
    final plain = tester.getSize(find.byType(MxSettingsRow)).height;
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: 'Daily reminder', trailing: _toggle())),
    );

    expect(plain, 48);
    expect(tester.getSize(find.byType(MxSettingsRow)).height, plain);
  });

  testWidgets('a long label wraps; the trailing control keeps its size', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: 'Reminder', trailing: _toggle())),
    );
    final toggle = tester.getSize(find.byType(MxToggle));
    final oneLine = tester.getSize(find.text('Reminder')).height;

    final long = List.filled(8, 'Nhắc học hằng ngày').join(' ');
    await pumpMx(
      tester,
      _width(MxSettingsRow(label: long, trailing: _toggle())),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MxToggle)), toggle);
    expect(tester.getSize(find.text(long)).height, greaterThan(oneLine * 2));
  });

  testWidgets('a wide control drops onto its own line, 12 below', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Cards per session',
          icon: AppIcons.library,
          wideControl: SizedBox(key: _controlKey, width: 120, height: 36),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_controlKey)).dy -
          tester.getBottomLeft(find.text('Cards per session')).dy,
      12,
    );
    expect(
      tester.getTopLeft(find.byKey(_controlKey)).dx,
      tester.getTopLeft(find.text('Cards per session')).dx,
    );
  });

  testWidgets('with a wide control the tile sits at the top, beside the '
      'label, as in kit 23', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Cards per session',
          subtitle: '1 to 200 · default 20',
          icon: AppIcons.library,
          wideControl: SizedBox(key: _controlKey, width: 120, height: 36),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(MxIconTile)).dy -
          tester.getTopLeft(find.byType(MxSettingsRow)).dy,
      12,
    );
  });

  testWidgets('dimmed at 0.38 while unavailable', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      _width(
        MxSettingsRow(label: 'Language', isEnabled: false, onTap: () => taps++),
      ),
    );
    await tester.tap(find.text('Language'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Language'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });
  testWidgets('at normal text the trailing control stays beside the label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxSettingsRow(
        label: 'Daily reminder',
        trailing: MxToggle(
          isOn: true,
          semanticLabel: 'Daily reminder',
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byType(MxToggle)).dy,
      lessThan(tester.getBottomLeft(find.text('Daily reminder')).dy),
    );
  });

  testWidgets('a disabled row keeps its subtitle at full ink (critique '
      '2026-09-30, screen 24)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Time',
          subtitle: 'Turn the reminder on to choose a time',
          icon: AppIcons.clock,
          isEnabled: false,
        ),
      ),
    );
    expect(
      find.ancestor(
        of: find.text('Turn the reminder on to choose a time'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.text('Time'),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });

  testWidgets('an action row shows no chevron', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSettingsRow(label: 'Reset options', isAction: true, onTap: () {}),
      ),
    );
    expect(find.byIcon(AppIcons.chevronRight), findsNothing);
  });

  testWidgets('a disabled row does not dim its control twice (critique '
      '2026-09-30 part 3a)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Time',
          subtitle: 'Turn the reminder on to choose a time',
          icon: AppIcons.clock,
          isEnabled: false,
          trailing: MxButton(
            label: '20:00',
            size: MxButtonSize.compact,
            onPressed: null,
          ),
        ),
      ),
    );
    expect(
      find.ancestor(of: find.text('20:00'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
  });

  testWidgets("a disabled row's non-control trailing still dims", (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Time',
          isEnabled: false,
          trailing: Text('20:00'),
        ),
      ),
    );
    expect(
      find.ancestor(of: find.text('20:00'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
  });

  testWidgets('a control under a Semantics label is not dimmed twice either, '
      "as the reminder's time button is (critique 2026-09-30 part 3a)", (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSettingsRow(
          label: 'Time',
          isEnabled: false,
          trailing: Semantics(
            label: 'Reminder time, 20:00',
            excludeSemantics: true,
            button: true,
            child: const MxButton(
              label: '20:00',
              size: MxButtonSize.compact,
              onPressed: null,
            ),
          ),
        ),
      ),
    );
    expect(
      find.ancestor(of: find.text('20:00'), matching: find.byType(Opacity)),
      findsOneWidget,
    );
  });

  testWidgets('iconTone reaches the lead tile, and a disabled row still dims '
      'it (critique 2026-09-30 tone pass, T4)', (tester) async {
    await pumpMx(
      tester,
      _width(const MxSettingsRow(label: 'Sync', icon: AppIcons.sync)),
    );
    expect(
      tester.widget<MxIconTile>(find.byType(MxIconTile)).tone,
      MxIconTileTone.tinted,
    );

    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Sync',
          icon: AppIcons.sync,
          iconTone: MxIconTileTone.success,
          isEnabled: false,
        ),
      ),
    );
    expect(
      tester.widget<MxIconTile>(find.byType(MxIconTile)).tone,
      MxIconTileTone.success,
    );
    expect(
      find.ancestor(
        of: find.byType(MxIconTile),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a message sits under the text and the trailing control, from '
      'the label\'s start to the row\'s end (Study options compaction)', (
    tester,
  ) async {
    const messageKey = ValueKey('message');
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Cards per session',
          icon: AppIcons.library,
          trailing: SizedBox(key: _controlKey, width: 140, height: 44),
          message: SizedBox(key: messageKey, height: 20),
        ),
      ),
    );
    final label = tester.getRect(find.text('Cards per session'));
    final control = tester.getRect(find.byKey(_controlKey));
    final message = tester.getRect(find.byKey(messageKey));

    // The control stays beside the label.
    expect(control.left, greaterThan(label.left));
    expect(control.top, lessThan(label.bottom));
    // The message starts under the label and runs under the control.
    expect(message.left, label.left);
    expect(message.right, greaterThanOrEqualTo(control.right));
    expect(message.top, greaterThanOrEqualTo(control.bottom));
    expect(message.top, greaterThanOrEqualTo(label.bottom));
  });

  testWidgets('a field message\'s glyph lines up with the label (audit '
      '2026-10-07)', (tester) async {
    await pumpMx(
      tester,
      _width(
        const MxSettingsRow(
          label: 'Cards',
          icon: AppIcons.library,
          trailing: SizedBox(key: _controlKey, width: 140, height: 44),
          message: MxFieldMessage(message: 'Enter a number from 1 to 200'),
        ),
      ),
    );
    final glyph = find.descendant(
      of: find.byType(MxFieldMessage),
      matching: find.byType(Icon),
    );

    expect(
      tester.getTopLeft(glyph).dx,
      tester.getTopLeft(find.text('Cards')).dx,
    );
  });
}
