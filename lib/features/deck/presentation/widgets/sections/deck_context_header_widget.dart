import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/presentation/providers/deck_view_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Where a card operation writes (kit 08/09): the deck's path ending in the
/// operation, and a line naming the destination deck. It is not a picker.
/// `app/` passes it to the card editor (ruling P4a-L7, spec D8).
class DeckContextHeaderWidget extends ConsumerWidget {
  const DeckContextHeaderWidget({
    super.key,
    required this.deckId,
    required this.currentLabel,
  });

  final String deckId;

  /// The operation's segment: "New card", "Edit".
  final String currentLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(deckViewProvider(deckId))) {
        AsyncData(value: Ok(:final value)) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MxBreadcrumb(
              segments: [
                MxBreadcrumbSegment(label: context.l10n.navLibrary),
                for (final entry in value.breadcrumb)
                  MxBreadcrumbSegment(label: entry.name),
                MxBreadcrumbSegment(label: value.deck.name),
                MxBreadcrumbSegment(label: currentLabel),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.control,
              ),
              child: Row(
                spacing: AppSpacing.control,
                children: [
                  const MxIconTile(icon: AppIcons.library),
                  Flexible(
                    child: Text(
                      value.deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.settingsLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // The page says why when the deck fails or is gone.
        AsyncData() || AsyncError() => const SizedBox.shrink(),
        _ => const _LoadingHeader(),
      };
}

/// The path and destination lines' place while the deck loads, so the form
/// below does not jump when they arrive.
class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  static const double _pathWidth = 200;
  static const double _nameWidth = 120;

  @override
  Widget build(BuildContext context) => Semantics(
    // The bars say nothing; the header is heard once as loading.
    container: true,
    label: context.l10n.commonLoading,
    child: const ExcludeSemantics(
      child: MxSkeletonPulse(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.control,
            AppSpacing.gutter,
            AppSpacing.control,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.grouped,
            children: [
              MxSkeleton(width: _pathWidth),
              MxSkeleton(width: _nameWidth),
            ],
          ),
        ),
      ),
    ),
  );
}
