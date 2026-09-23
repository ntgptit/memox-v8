@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxButton tones, sizes and states', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_button',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          for (final tone in MxButtonTone.values)
            MxButton(label: tone.name, tone: tone, onPressed: () {}),
          MxButton(
            label: 'Small',
            size: MxButtonSize.small,
            icon: AppIcons.add,
            onPressed: () {},
          ),
          MxButton(
            label: 'Compact',
            size: MxButtonSize.compact,
            onPressed: () {},
          ),
          MxButton(label: 'Chip', size: MxButtonSize.chip, onPressed: () {}),
          MxButton(label: 'Reveal', size: MxButtonSize.study, onPressed: () {}),
          const MxButton(label: 'Disabled', onPressed: null),
          MxButton(label: 'Saving', isLoading: true, onPressed: () {}),
          MxButton(
            label: 'Start review',
            icon: AppIcons.play,
            isBlock: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  });

  testWidgets('MxIconButton resting and disabled', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_icon_button',
      Row(
        children: [
          MxIconButton(
            icon: AppIcons.back,
            semanticLabel: 'Back',
            onPressed: () {},
          ),
          MxIconButton(
            icon: AppIcons.search,
            semanticLabel: 'Search',
            onPressed: () {},
          ),
          MxIconButton(
            icon: AppIcons.more,
            semanticLabel: 'More',
            onPressed: () {},
          ),
          const MxIconButton(
            icon: AppIcons.close,
            semanticLabel: 'Close',
            onPressed: null,
          ),
        ],
      ),
    );
  });

  testWidgets('MxEmptyState full with action, compact neutral', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_empty_state',
      Column(
        spacing: 16,
        children: [
          MxEmptyState(
            icon: AppIcons.inbox,
            title: 'No decks yet',
            body: 'Create a deck or add a starter deck to begin.',
            actionLabel: 'Create deck',
            onAction: () {},
          ),
          const MxEmptyState(
            icon: AppIcons.search,
            title: 'No match',
            body: 'Try another word.',
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
    );
  });

  testWidgets('MxAppBar both densities', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_app_bar',
      Column(
        children: [
          const MxAppBar(title: 'Library'),
          MxAppBar(
            title: 'Japanese N5 · Verbs of motion and a very long name',
            density: MxAppBarDensity.content,
            leading: MxIconButton(
              icon: AppIcons.back,
              semanticLabel: 'Back',
              onPressed: () {},
            ),
            actions: [
              MxIconButton(
                icon: AppIcons.search,
                semanticLabel: 'Search',
                onPressed: () {},
              ),
              MxIconButton(
                icon: AppIcons.more,
                semanticLabel: 'More',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('MxStudyTopBar default and mastery accent', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_study_top_bar',
      Column(
        children: [
          MxStudyTopBar(
            modeLabel: 'Review',
            current: 3,
            total: 10,
            counterLabel: '3 / 10',
            closeLabel: 'Close',
            onClose: () {},
          ),
          MxStudyTopBar(
            modeLabel: 'Recall',
            current: 10,
            total: 10,
            counterLabel: '10 / 10',
            closeLabel: 'Close',
            onClose: () {},
            accent: MxSemanticColors.light.mastery,
          ),
        ],
      ),
    );
  });

  testWidgets('MxBreadcrumb short and deep', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_breadcrumb',
      Column(
        children: [
          MxBreadcrumb(
            segments: [
              MxBreadcrumbSegment(label: 'Japanese', onTap: () {}),
              MxBreadcrumbSegment(label: 'N5', onTap: () {}),
              const MxBreadcrumbSegment(label: 'Verbs'),
            ],
          ),
          MxBreadcrumb(
            segments: [
              for (var i = 1; i < 10; i++)
                MxBreadcrumbSegment(label: 'Level $i', onTap: () {}),
              const MxBreadcrumbSegment(label: 'Level 10'),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('MxBottomNav on Library', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_bottom_nav',
      Align(
        alignment: Alignment.bottomCenter,
        child: MxBottomNav(
          destinations: const [
            MxNavDestination(
              icon: AppIcons.library,
              selectedIcon: AppIcons.librarySelected,
              label: 'Library',
            ),
            MxNavDestination(
              icon: AppIcons.study,
              selectedIcon: AppIcons.studySelected,
              label: 'Study',
            ),
            MxNavDestination(
              icon: AppIcons.progress,
              selectedIcon: AppIcons.progressSelected,
              label: 'Progress',
            ),
            MxNavDestination(
              icon: AppIcons.settings,
              selectedIcon: AppIcons.settingsSelected,
              label: 'Settings',
            ),
          ],
          selectedIndex: 0,
          onSelected: (_) {},
        ),
      ),
    );
  });

  testWidgets('MxFab resting', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_fab',
      Align(
        alignment: Alignment.bottomRight,
        child: MxFab(
          icon: AppIcons.add,
          semanticLabel: 'New deck',
          onPressed: () {},
        ),
      ),
    );
  });

  testWidgets('MxAppShell with nav + FAB, and with a footer', (tester) async {
    Widget rows() => MxScreenScroll(
      clearance: MxScrollClearance.fabAboveNav,
      children: [
        for (var i = 0; i < 12; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: MxEmptyState(
              icon: AppIcons.inbox,
              title: 'Row $i',
              isCompact: true,
            ),
          ),
      ],
    );
    await expectThemedGoldens(
      tester,
      'mx_app_shell',
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: MxAppShell(
              appBar: const MxAppBar(title: 'Library'),
              body: rows(),
              bottomBar: MxBottomNav(
                destinations: const [
                  MxNavDestination(
                    icon: AppIcons.library,
                    selectedIcon: AppIcons.librarySelected,
                    label: 'Library',
                  ),
                  MxNavDestination(
                    icon: AppIcons.study,
                    selectedIcon: AppIcons.studySelected,
                    label: 'Study',
                  ),
                ],
                selectedIndex: 0,
                onSelected: (_) {},
              ),
              fab: MxFab(
                icon: AppIcons.add,
                semanticLabel: 'New',
                onPressed: () {},
              ),
            ),
          ),
          Expanded(
            child: MxAppShell(
              appBar: const MxAppBar(title: 'Edit'),
              body: rows(),
              footer: MxFooterBar(
                caption: 'Saved on this device',
                child: MxButton(label: 'Save', isBlock: true, onPressed: () {}),
              ),
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('MxFilterChip and MxChipTrigger', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_chips',
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          MxFilterChip(
            label: 'All',
            count: 128,
            isSelected: true,
            onSelected: (_) {},
          ),
          MxFilterChip(
            label: 'Cards',
            count: 96,
            isSelected: false,
            onSelected: (_) {},
          ),
          MxFilterChip(
            label: 'Decks',
            icon: AppIcons.filter,
            isSelected: false,
            onSelected: (_) {},
          ),
          const MxFilterChip(
            label: 'Disabled',
            isSelected: false,
            onSelected: null,
          ),
          MxChipTrigger(label: 'Sort: Due', onPressed: () {}),
          MxChipTrigger(
            label: 'Filters',
            icon: AppIcons.filters,
            onPressed: () {},
          ),
        ],
      ),
    );
  });

  testWidgets('MxTextField states and MxFieldMessage tones', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_text_field',
      Column(
        spacing: 16,
        children: [
          const MxTextField(hintText: 'Deck name'),
          MxTextField(controller: TextEditingController(text: 'Japanese N5')),
          const MxTextField(
            hintText: 'Deck name',
            errorText: 'Name is required',
          ),
          const MxTextField(hintText: 'Back of the card', isMultiline: true),
          const MxTextField(hintText: 'Disabled', isEnabled: false),
          const MxFieldMessage(
            message: 'Ten tags at most on one card',
            tone: MxFieldMessageTone.warning,
          ),
        ],
      ),
    );
  });

  testWidgets('MxSearchField empty and filled', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_search_field',
      Column(
        spacing: 16,
        children: [
          MxSearchField(
            controller: TextEditingController(),
            hintText: 'Search decks and cards',
            clearLabel: 'Clear',
          ),
          MxSearchField(
            controller: TextEditingController(text: 'irregular verbs'),
            hintText: 'Search decks and cards',
            clearLabel: 'Clear',
          ),
        ],
      ),
    );
  });

  testWidgets('MxToggle and MxSelectionCheckbox', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_toggle_checkbox',
      Row(
        spacing: 8,
        children: [
          MxToggle(isOn: false, onChanged: (_) {}, semanticLabel: 'Off'),
          MxToggle(isOn: true, onChanged: (_) {}, semanticLabel: 'On'),
          const MxToggle(
            isOn: true,
            onChanged: null,
            semanticLabel: 'Disabled',
          ),
          const MxSelectionCheckbox(isChecked: false),
          const MxSelectionCheckbox(isChecked: true),
        ],
      ),
    );
  });
  testWidgets('MxOptionRow and MxSegmentedTray', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_option_tray',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Column(
            children: [
              MxOptionRow(
                title: 'Eight box',
                description: 'Cards climb eight boxes, each a longer interval.',
                isSelected: true,
                onSelected: () {},
              ),
              MxOptionRow(title: 'SM-2', isSelected: false, onSelected: () {}),
              const MxOptionRow(
                title: 'Disabled',
                isSelected: false,
                onSelected: null,
                hasDivider: false,
              ),
            ],
          ),
          MxSegmentedTray(
            segments: const [
              MxSegment(value: 0, label: 'Light'),
              MxSegment(value: 1, label: 'Dark'),
              MxSegment(value: 2, label: 'System'),
            ],
            selected: 2,
            onSelected: (_) {},
          ),
          MxSegmentedTray(
            segments: const [
              MxSegment(value: 7, label: '7 days'),
              MxSegment(value: 30, label: '30 days'),
            ],
            selected: 7,
            onSelected: (_) {},
            isWide: true,
          ),
        ],
      ),
    );
  });
}
