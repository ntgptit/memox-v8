import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/widget_harness.dart';

// M3F-17: a disabled or busy row answers no tap on its target or its
// controls, keeps its nodes for TalkBack, and says it is disabled.

Widget _width(Widget child) => SizedBox(width: 360, child: child);

void main() {
  testWidgets(
    'M3F-17: a disabled list row blocks its trailing control and says it is '
    'disabled, and TalkBack still reads it',
    (tester) async {
      final handle = tester.ensureSemantics();
      var rowTaps = 0;
      var menuTaps = 0;
      await pumpMx(
        tester,
        _width(
          MxListRow(
            title: 'Grammar',
            subtitle: 'Cannot hold another deck',
            isEnabled: false,
            onTap: () => rowTaps++,
            trailing: MxIconButton(
              icon: AppIcons.more,
              semanticLabel: 'Deck actions',
              onPressed: () => menuTaps++,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MxIconButton), warnIfMissed: false);
      await tester.tap(find.text('Grammar'), warnIfMissed: false);
      expect((rowTaps, menuTaps), (0, 0));

      final row = tester.getSemantics(find.text('Grammar'));
      expect(
        row,
        isSemantics(
          label: 'Grammar\nCannot hold another deck',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Deck actions')),
        isSemantics(label: 'Deck actions', hasTapAction: false),
      );
      handle.dispose();
    },
  );

  testWidgets('M3F-17: a disabled list row with no tap still says it is '
      'disabled and keeps its trailing control inert', (tester) async {
    final handle = tester.ensureSemantics();
    var menuTaps = 0;
    await pumpMx(
      tester,
      _width(
        MxListRow(
          title: 'Grammar',
          isEnabled: false,
          trailing: MxIconButton(
            icon: AppIcons.more,
            semanticLabel: 'Deck actions',
            onPressed: () => menuTaps++,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(MxIconButton), warnIfMissed: false);
    expect(menuTaps, 0);
    expect(
      tester.getSemantics(find.text('Grammar')),
      isSemantics(label: 'Grammar', hasEnabledState: true, isEnabled: false),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Deck actions')),
      isSemantics(label: 'Deck actions', hasTapAction: false),
    );
    handle.dispose();
  });

  testWidgets(
    'M3F-17: a busy list row ignores its tap and says it is disabled, without '
    'dimming',
    (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpMx(
        tester,
        _width(MxListRow(title: 'Work', isBusy: true, onTap: () => taps++)),
      );
      await tester.tap(find.text('Work'), warnIfMissed: false);
      expect(taps, 0);
      expect(
        tester.getSemantics(find.text('Work')),
        isSemantics(
          label: 'Work',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      expect(
        find.ancestor(of: find.text('Work'), matching: find.byType(Opacity)),
        findsNothing,
      );
      handle.dispose();
    },
  );

  testWidgets(
    'M3F-17: a disabled settings row blocks its trailing and wide controls '
    'and says it is disabled; TalkBack still reads them',
    (tester) async {
      final handle = tester.ensureSemantics();
      var toggles = 0;
      var steps = 0;
      for (final (trailing, wide) in <(Widget?, Widget?)>[
        (
          MxToggle(
            isOn: true,
            onChanged: (_) => toggles++,
            semanticLabel: 'Daily reminder',
          ),
          null,
        ),
        (
          null,
          MxButton(
            label: 'Step',
            size: MxButtonSize.small,
            onPressed: () => steps++,
          ),
        ),
      ]) {
        await pumpMx(
          tester,
          _width(
            MxSettingsRow(
              label: 'Reminder',
              subtitle: 'Turn it on first',
              isEnabled: false,
              trailing: trailing,
              wideControl: wide,
            ),
          ),
        );
        await tester.tap(
          find.byType(trailing == null ? MxButton : MxToggle),
          warnIfMissed: false,
        );
        expect((toggles, steps), (0, 0));
        expect(
          tester.getSemantics(find.text('Reminder')),
          isSemantics(
            label: 'Reminder\nTurn it on first',
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
      }
      expect(
        tester.getSemantics(find.text('Step')),
        isSemantics(label: 'Step', hasTapAction: false),
      );
      handle.dispose();
    },
  );

  testWidgets(
    'M3F-17: the toggle of a disabled settings row keeps its own node, its '
    'label and its on state, with no tap action',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(
        tester,
        _width(
          MxSettingsRow(
            label: 'Reminder',
            isEnabled: false,
            trailing: MxToggle(
              isOn: true,
              onChanged: (_) {},
              semanticLabel: 'Daily reminder',
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(MxToggle)),
        isSemantics(
          label: 'Daily reminder',
          hasToggledState: true,
          isToggled: true,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    },
  );

  testWidgets(
    'M3F-17: a disabled navigating settings row is a disabled button with no '
    'tap action',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpMx(
        tester,
        _width(
          MxSettingsRow(label: 'Language', isEnabled: false, onTap: () {}),
        ),
      );
      expect(
        tester.getSemantics(find.text('Language')),
        isSemantics(
          label: 'Language',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    },
  );
}
