import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_nav_rail.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

/// Group A: the app bars, study bar, breadcrumb, bottom nav, rail and FAB.
class GalleryChromeSection extends StatelessWidget {
  const GalleryChromeSection({super.key});

  static const double _railHeight = 320;

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context);
    return GallerySection(
      title: context.l10n.galleryAChromeNavigation,
      children: [
        MxAppBar(title: context.l10n.navLibrary),
        MxAppBar(
          title: context.l10n.galleryJapaneseN5VerbsOfMotion,
          density: MxAppBarDensity.content,
          leading: MxIconButton(
            icon: AppIcons.back,
            semanticLabel: context.l10n.commonBack,
            onPressed: () {},
          ),
          actions: [
            MxIconButton(
              icon: AppIcons.search,
              semanticLabel: context.l10n.gallerySearch,
              onPressed: () {},
            ),
            MxIconButton(
              icon: AppIcons.more,
              semanticLabel: context.l10n.galleryMore,
              onPressed: () {},
            ),
          ],
        ),
        MxStudyTopBar(
          modeLabel: context.l10n.galleryReview,
          current: 3,
          total: 10,
          counterLabel: '3 / 10',
          closeLabel: context.l10n.galleryClose,
          onClose: () {},
        ),
        MxStudyTopBar(
          modeLabel: context.l10n.galleryRecall,
          current: 10,
          total: 10,
          counterLabel: '10 / 10',
          closeLabel: context.l10n.galleryClose,
          onClose: () {},
          accent: context.semanticColors.mastery,
          accentInk: context.derivedColors.statusMasteredInk,
        ),
        MxBreadcrumb(
          segments: [
            for (var level = 1; level < 10; level++)
              MxBreadcrumbSegment(
                label: context.l10n.galleryLevel(level),
                onTap: () {},
              ),
            MxBreadcrumbSegment(label: context.l10n.galleryLevel(10)),
          ],
        ),
        MxBottomNav(
          destinations: destinations,
          selectedIndex: 0,
          onSelected: (_) {},
        ),
        // The rail a window of 600 dp and more shows instead (FE-C5).
        SizedBox(
          height: _railHeight,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxNavRail(
              destinations: destinations,
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: MxFab(
            icon: AppIcons.add,
            semanticLabel: context.l10n.galleryNewDeck,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  static List<MxNavDestination> _destinations(BuildContext context) => [
    MxNavDestination(
      icon: AppIcons.library,
      selectedIcon: AppIcons.librarySelected,
      label: context.l10n.navLibrary,
    ),
    MxNavDestination(
      icon: AppIcons.study,
      selectedIcon: AppIcons.studySelected,
      label: context.l10n.navStudy,
    ),
    MxNavDestination(
      icon: AppIcons.progress,
      selectedIcon: AppIcons.progressSelected,
      label: context.l10n.navProgress,
    ),
    MxNavDestination(
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settingsSelected,
      label: context.l10n.navSettings,
    ),
  ];
}
