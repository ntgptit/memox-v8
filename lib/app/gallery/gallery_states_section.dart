import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// Group G: loading, empty and error.
class GalleryStatesSection extends StatelessWidget {
  const GalleryStatesSection({super.key});

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'G · Loading, empty & error',
    children: [
      MxEmptyState(
        icon: AppIcons.inbox,
        title: 'No decks yet',
        body: 'Create a deck or add a starter deck to begin.',
        actionLabel: 'Create deck',
        onAction: () {},
      ),
      for (final tone in MxEmptyStateTone.values.skip(1))
        MxEmptyState(
          icon: AppIcons.search,
          title: tone.name,
          body: 'Compact, ${tone.name} tone.',
          tone: tone,
          isCompact: true,
        ),
      const MxSkeletonRow(),
      const MxSkeletonRow(),
      const Row(
        spacing: AppSpacing.gutter,
        children: [
          MxSpinner(),
          MxSpinner(size: MxSpinnerSize.compact),
          MxSpinner(size: MxSpinnerSize.standard),
          MxSpinner(size: MxSpinnerSize.large),
        ],
      ),
      MxErrorState(
        title: 'Could not load decks',
        body: 'Nothing was lost. Try again in a moment.',
        retryLabel: 'Retry',
        onRetry: () {},
      ),
      const MxErrorState(
        title: 'Deck not found',
        body: 'It may have been deleted on this device.',
        icon: AppIcons.alert,
      ),
    ],
  );
}
