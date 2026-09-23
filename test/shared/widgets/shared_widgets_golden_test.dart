@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

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
}
