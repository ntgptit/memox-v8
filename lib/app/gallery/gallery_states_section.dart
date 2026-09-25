import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
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
    title: context.l10n.galleryGLoadingEmptyError,
    children: [
      MxEmptyState(
        icon: AppIcons.inbox,
        title: context.l10n.galleryNoDecksYet,
        body: context.l10n.galleryCreateADeckOrAdd,
        actionLabel: context.l10n.galleryCreateDeck,
        onAction: () {},
      ),
      for (final tone in MxEmptyStateTone.values.skip(1))
        MxEmptyState(
          icon: AppIcons.search,
          title: tone.name,
          body: context.l10n.galleryCompactTone(tone.name),
          tone: tone,
          isCompact: true,
        ),
      MxSkeletonList(semanticLabel: context.l10n.commonLoading, rows: 2),
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
        title: context.l10n.galleryCouldNotLoadDecks,
        body: context.l10n.galleryLoadErrorBody,
        retryLabel: context.l10n.commonRetry,
        onRetry: () {},
      ),
      MxErrorState(
        title: context.l10n.galleryDeckNotFound,
        body: context.l10n.galleryItMayHaveBeenDeleted,
        icon: AppIcons.alert,
      ),
    ],
  );
}
