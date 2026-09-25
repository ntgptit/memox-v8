import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Group B: every Button tone, size and state, and the IconButton.
class GalleryActionsSection extends StatelessWidget {
  const GalleryActionsSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: context.l10n.galleryBActions,
    children: [
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          for (final tone in MxButtonTone.values)
            MxButton(label: tone.name, tone: tone, onPressed: () {}),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          MxButton(
            label: context.l10n.gallerySmall,
            size: MxButtonSize.small,
            icon: AppIcons.add,
            onPressed: () {},
          ),
          MxButton(
            label: context.l10n.galleryCompact,
            size: MxButtonSize.compact,
            onPressed: () {},
          ),
          MxButton(
            label: context.l10n.galleryChip,
            size: MxButtonSize.chip,
            onPressed: () {},
          ),
          MxButton(
            label: context.l10n.galleryReveal,
            size: MxButtonSize.study,
            onPressed: () {},
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxButton(label: context.l10n.galleryDisabled, onPressed: null),
          MxButton(
            label: context.l10n.gallerySaving,
            isLoading: true,
            onPressed: () {},
          ),
        ],
      ),
      MxButton(
        label: context.l10n.galleryABlockActionWhoseLabel,
        icon: AppIcons.play,
        isBlock: true,
        onPressed: () {},
      ),
      Row(
        children: [
          MxIconButton(
            icon: AppIcons.back,
            semanticLabel: context.l10n.commonBack,
            onPressed: () {},
          ),
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
          MxIconButton(
            icon: AppIcons.close,
            semanticLabel: context.l10n.galleryClose,
            onPressed: null,
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxFilterChip(
            label: context.l10n.galleryAll,
            count: 128,
            isSelected: true,
            onSelected: (_) {},
          ),
          MxFilterChip(
            label: context.l10n.galleryCards,
            count: 96,
            isSelected: false,
            onSelected: (_) {},
          ),
          MxFilterChip(
            label: context.l10n.galleryDecks,
            icon: AppIcons.filter,
            isSelected: false,
            onSelected: (_) {},
          ),
          MxChipTrigger(
            label: context.l10n.gallerySortDue,
            icon: AppIcons.sort,
            onPressed: () {},
          ),
          MxChipTrigger(
            label: context.l10n.galleryFilters,
            icon: AppIcons.filters,
            onPressed: () {},
          ),
        ],
      ),
    ],
  );
}
