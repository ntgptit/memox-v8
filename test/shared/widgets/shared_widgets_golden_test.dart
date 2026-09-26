@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

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
          MxButton(
            label: 'Good',
            detail: '6d',
            tone: MxButtonTone.secondary,
            onPressed: () {},
          ),
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

  // FE-C2: an ellipsized line clips at its box; stacked marks must survive.
  testWidgets('ellipsized Vietnamese keeps its stacked marks', (tester) async {
    const long = 'Ẳng Ổn định Ỗ Ẫm thực · Nguyễn Hằng · Ẳ Ổ Ỗ Ẫ Ẳ Ổ Ỗ Ẫ';
    await expectThemedGoldens(
      tester,
      'mx_vietnamese_ellipsis',
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MxAppBar(title: long),
          MxListRow(title: long, subtitle: long),
          SizedBox(width: 160, child: MxTagChip(label: long)),
          // A card row's back (screen 07): 1.45 holds the marks, measured.
          _RowDescription('$long · $long'),
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
}

class _RowDescription extends StatelessWidget {
  const _RowDescription(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: context.textStyles.rowDescription,
  );
}
