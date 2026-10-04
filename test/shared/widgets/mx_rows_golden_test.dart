@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import 'support/mx_harness.dart';

Widget _column(List<Widget> children) => SizedBox(
  width: 380,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: children,
  ),
);

/// The command rows sit on the sheet ground, as they do in a sheet.
class _OnSheet extends StatelessWidget {
  const _OnSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: child,
  );
}

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('list_row', 'forms'): () => _column([
      const MxListRow(title: 'Spanish'),
      MxListRow(
        title: 'Japanese kana',
        subtitle: '46 cards · reviewed today',
        icon: Icons.style,
        trailing: const MxListRowTrailing.chevron(),
        onTap: () {},
      ),
      MxListRow(
        title: 'hola',
        subtitle: 'hello',
        isChecked: true,
        onTap: () {},
      ),
      const MxListRow(
        title: 'French verbs',
        subtitle: 'Was in Library › Languages › French, removed on Monday',
        icon: Icons.delete_outline,
        iconTone: MxIconTileTone.warning,
        trailing: MxListRowTrailing.badge('3 days left', MxBadgeTone.warning),
      ),
      const MxListRow(
        title: 'Total cards',
        trailing: MxListRowTrailing.value('1,204'),
      ),
      MxListRow(
        title: 'verbs',
        subtitle: '120 cards',
        onTap: () {},
        trailing: MxListRowTrailing.iconButton(
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: 'More for verbs',
            onPressed: () {},
          ),
        ),
      ),
      MxListRow(
        title: 'Sync history',
        subtitle: 'Available when you are online',
        icon: Icons.cloud_outlined,
        trailing: const MxListRowTrailing.chevron(),
        onTap: () {},
        isEnabled: false,
      ),
    ]),
    ('list_section_header', 'forms'): () => _column([
      const MxListSectionHeader(title: 'Recent'),
      MxListSectionHeader(
        title: 'Cards',
        trigger: MxChipTrigger(label: 'Newest first', onOpen: () {}),
      ),
    ]),
    ('settings_row', 'kinds'): () => _column([
      MxSettingsRow.navigation(
        title: 'Account',
        subtitle: 'Signed in',
        icon: Icons.person_outline,
        onTap: () {},
      ),
      MxSettingsRow.action(
        title: 'Export cards',
        icon: Icons.upload_outlined,
        onTap: () {},
      ),
      const MxSettingsRow.value(
        title: 'Review order',
        icon: Icons.sort,
        value: 'Due first',
      ),
      MxSettingsRow.toggle(
        title: 'Daily reminder',
        subtitle: 'At 20:00',
        icon: Icons.notifications_none,
        isOn: true,
        onChanged: (_) {},
      ),
      MxSettingsRow.toggle(
        title: 'Sync over mobile data',
        subtitle: 'Available when you are online',
        icon: Icons.sync,
        isOn: false,
        onChanged: (_) {},
        isEnabled: false,
      ),
    ]),
    ('action_sheet_command_row', 'forms'): () => _column([
      _OnSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            MxActionSheetCommandRow(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: Icons.tune,
              label: 'Study options',
              subtitle: 'Cards per session · new-card order',
              onTap: () {},
            ),
            MxActionSheetCommandRow(
              icon: Icons.delete_forever_outlined,
              label: 'Delete forever',
              subtitle: 'Cannot be undone · history lost',
              isDestructive: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    ]),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
