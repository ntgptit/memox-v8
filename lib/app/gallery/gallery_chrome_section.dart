import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// Group A: the app bars, study bar, breadcrumb, bottom nav and FAB.
class GalleryChromeSection extends StatelessWidget {
  const GalleryChromeSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'A · Chrome & navigation',
    children: [
      const MxAppBar(title: 'Library'),
      MxAppBar(
        title: 'Japanese N5 · Verbs of motion and a very long deck name',
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
        accent: context.semanticColors.mastery,
      ),
      MxBreadcrumb(
        segments: [
          for (var level = 1; level < 10; level++)
            MxBreadcrumbSegment(label: 'Level $level', onTap: () {}),
          const MxBreadcrumbSegment(label: 'Level 10'),
        ],
      ),
      MxBottomNav(
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
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: MxFab(
          icon: AppIcons.add,
          semanticLabel: 'New deck',
          onPressed: () {},
        ),
      ),
    ],
  );
}
