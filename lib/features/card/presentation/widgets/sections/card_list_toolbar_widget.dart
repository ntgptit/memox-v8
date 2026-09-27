import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_tag_filter_sheet_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_list_labels_widget.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/card/presentation/providers/card_tag_filter_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

/// The four filters with their counts, then Tags (screen 07). The search
/// shows above them once the app bar asks for it; the sort sits in the
/// header. Tags is selected while tags are applied (FE-B2 spec D14); its
/// tap opens the sheet and never toggles.
class CardListToolbarWidget extends ConsumerWidget {
  const CardListToolbarWidget({
    super.key,
    required this.deckId,
    required this.request,
    required this.counts,
    required this.onFilter,
  });

  final String deckId;
  final CardListRequestState request;
  final CardListCounts counts;
  final ValueChanged<CardListFilter> onFilter;

  /// Applying tags shows other cards, so the selection goes (BR-TAG-005).
  void _apply(WidgetRef ref, Set<String> tagIds) {
    ref.read(cardListRequestProvider(deckId).notifier).filterTags(tagIds);
    ref.read(cardSelectionProvider(deckId).notifier).clear();
  }

  Future<void> _openTags(BuildContext context, WidgetRef ref) async {
    final tagIds = await showCardTagFilterSheet(
      context,
      deckId: deckId,
      applied: request.tags.ids,
    );
    if (tagIds == null || !context.mounted) return;
    _apply(ref, tagIds);
  }

  /// A tag deleted or merged away leaves the applied set (spec D12).
  void _prune(WidgetRef ref, List<TagCount> tags) {
    final applied = request.tags.ids;
    final kept = {
      for (final tag in tags)
        if (applied.contains(tag.id)) tag.id,
    };
    if (kept.length == applied.length) return;
    ref.read(cardListRequestProvider(deckId).notifier).filterTags(kept);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final applied = request.tags.ids.length;
    ref.listen(
      cardTagFilterProvider(deckId),
      (_, next) => next.whenData((tags) => _prune(ref, tags)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      // The chips never shrink or wrap, so their row scrolls.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: AppSpacing.micro,
          children: [
            for (final filter in CardListFilter.values)
              MxFilterChip(
                label: l10n.cardFilter(filter),
                count: counts.of(filter),
                isSelected: filter == request.filter,
                onSelected: (_) => onFilter(filter),
              ),
            MxFilterChip(
              label: l10n.cardFilterTags,
              icon: AppIcons.tag,
              count: applied == 0 ? null : applied,
              isSelected: applied > 0,
              onSelected: (_) => unawaited(_openTags(context, ref)),
            ),
          ],
        ),
      ),
    );
  }
}
