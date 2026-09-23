import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';

/// Group G: the empty state in each tone (Skeleton, Spinner and ErrorState
/// join in phase 6).
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
    ],
  );
}
