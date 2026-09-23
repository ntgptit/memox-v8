@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

import 'package:memox/shared/widgets/mx_icon_button.dart';

import 'package:memox/shared/widgets/mx_list_row.dart';

import 'package:memox/shared/widgets/mx_settings_row.dart';

import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';

import 'package:memox/shared/widgets/mx_toggle.dart';

import 'package:memox/shared/widgets/mx_stepper.dart';

import 'package:memox/shared/widgets/mx_section.dart';

import 'package:memox/shared/widgets/mx_list_section_header.dart';

import 'package:memox/shared/widgets/mx_note.dart';

import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxCard and MxIconTile', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_card_icon_tile',
      const Column(
        spacing: 16,
        children: [
          MxCard(child: SizedBox(height: 56)),
          MxCard(isHero: true, child: SizedBox(height: 56)),
          Row(
            spacing: 12,
            children: [
              MxIconTile(icon: AppIcons.library),
              MxIconTile(icon: AppIcons.reminder, size: MxIconTileSize.medium),
              MxIconTile(icon: AppIcons.library, size: MxIconTileSize.large),
              MxIconTile(icon: AppIcons.folder, seed: Color(0xFF0E9F6E)),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('MxListRow states in a full-bleed card', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_list_row',
      MxCard(
        isFullBleed: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MxListRow(
              title: 'Kanji N5',
              subtitle: '42 cards · 12 due',
              leading: const MxIconTile(icon: AppIcons.library),
              hasChevron: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'A deck name long enough to be cut with an ellipsis',
              subtitle: 'Nested three levels deep under Japanese',
              leading: const MxIconTile(
                icon: AppIcons.folder,
                seed: Color(0xFF0E9F6E),
              ),
              trailing: MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'Deck actions',
                onPressed: () {},
              ),
              onTap: () {},
            ),
            MxListRow(
              title: 'Importing',
              subtitle: '120 of 300 cards',
              leading: const MxIconTile(icon: AppIcons.library),
              isBusy: true,
              onTap: () {},
            ),
            MxListRow(
              title: 'Grammar',
              subtitle: 'Cannot hold another deck',
              leading: const MxIconTile(icon: AppIcons.folder),
              isEnabled: false,
              onTap: () {},
              hasDivider: false,
            ),
          ],
        ),
      ),
    );
  });

  testWidgets('MxSettingsRow and MxActionSheetCommandRow', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_settings_command_rows',
      Column(
        spacing: 16,
        children: [
          MxCard(
            isFullBleed: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MxSettingsRow(
                  label: 'Daily reminder',
                  subtitle: 'One nudge at the time you choose',
                  icon: AppIcons.reminder,
                  trailing: MxToggle(
                    isOn: true,
                    onChanged: (_) {},
                    semanticLabel: 'Daily reminder',
                  ),
                ),
                MxSettingsRow(
                  label: 'Language',
                  icon: AppIcons.library,
                  onTap: () {},
                ),
                MxSettingsRow(
                  label: 'Cards per session',
                  icon: AppIcons.library,
                  wideControl: MxStepper(
                    value: 20,
                    decrementLabel: 'Fewer',
                    incrementLabel: 'More',
                    onDecrement: () {},
                    onIncrement: () {},
                  ),
                ),
                const MxSettingsRow(
                  label: 'Unavailable while notifications are off',
                  icon: AppIcons.reminder,
                  isEnabled: false,
                ),
              ],
            ),
          ),
          MxCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MxActionSheetCommandRow(
                  icon: AppIcons.edit,
                  label: 'Rename',
                  subtitle: 'Change the deck name',
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.folder,
                  label: 'Move',
                  hasChevron: true,
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.delete,
                  label: 'Delete',
                  subtitle: 'Recoverable for 30 days',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('MxSection, MxListSectionHeader and MxNote', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_section_header_note',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MxListSectionHeader(
            label: 'Decks',
            trailing: MxChipTrigger(
              label: 'Sort: Due',
              icon: AppIcons.sort,
              onPressed: () {},
            ),
          ),
          MxSection(
            title: 'Reminders',
            note: 'Changes apply to future sessions.',
            children: [
              MxSettingsRow(
                label: 'Daily reminder',
                icon: AppIcons.reminder,
                trailing: MxToggle(
                  isOn: true,
                  onChanged: (_) {},
                  semanticLabel: 'Daily reminder',
                ),
              ),
              MxSettingsRow(
                label: 'Reminder time',
                icon: AppIcons.reminder,
                onTap: () {},
              ),
            ],
          ),
          const MxSection(
            children: [
              MxSettingsRow(label: 'Untitled group', icon: AppIcons.library),
            ],
          ),
          const MxNote(
            text:
                'Deleted decks stay recoverable for 30 days, then they are '
                'removed for good together with their cards.',
          ),
        ],
      ),
    );
  });
}
