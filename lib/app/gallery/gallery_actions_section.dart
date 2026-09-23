import 'package:flutter/material.dart';
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
    title: 'B · Actions',
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
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          const MxButton(label: 'Disabled', onPressed: null),
          MxButton(label: 'Saving', isLoading: true, onPressed: () {}),
        ],
      ),
      MxButton(
        label: 'A block action whose label is long enough to wrap',
        icon: AppIcons.play,
        isBlock: true,
        onPressed: () {},
      ),
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
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
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
          MxChipTrigger(
            label: 'Sort: Due',
            icon: AppIcons.sort,
            onPressed: () {},
          ),
          MxChipTrigger(
            label: 'Filters',
            icon: AppIcons.filters,
            onPressed: () {},
          ),
        ],
      ),
    ],
  );
}
