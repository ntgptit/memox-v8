import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/card/presentation/providers/card_tag_filter_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';

/// Picks the tags [deckId]'s card list shows (UC-TAG-001 steps 6-7; FE-B2
/// spec D3). Completes with the set to apply, or null when dismissed, which
/// keeps [applied] (A5).
Future<Set<String>?> showCardTagFilterSheet(
  BuildContext context, {
  required String deckId,
  required Set<String> applied,
}) => showMxBottomSheet<Set<String>>(
  context,
  builder: (_) => CardTagFilterSheetWidget(deckId: deckId, applied: applied),
);

/// Every tag with its cards in this deck, 0 included (BE-B2 D3), in the
/// catalog's order: a checked row never moves. A search heads the list once
/// there are more than eight; it never drops a chosen tag.
class CardTagFilterSheetWidget extends ConsumerStatefulWidget {
  const CardTagFilterSheetWidget({
    super.key,
    required this.deckId,
    required this.applied,
  });

  final String deckId;
  final Set<String> applied;

  @override
  ConsumerState<CardTagFilterSheetWidget> createState() =>
      _CardTagFilterSheetWidgetState();
}

class _CardTagFilterSheetWidgetState
    extends ConsumerState<CardTagFilterSheetWidget> {
  /// Above this many tags the sheet offers its search (shape brief §5).
  static const int _searchAbove = 8;
  static const int _skeletonRows = 3;

  final _search = TextEditingController();
  late final Set<String> _draft = {...widget.applied};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(String tagId) => setState(() {
    if (!_draft.remove(tagId)) _draft.add(tagId);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tags = ref.watch(cardTagFilterProvider(widget.deckId));
    return switch (tags) {
      AsyncData(:final value) when value.isEmpty => _none(l10n),
      AsyncData(:final value) => _picker(l10n, value),
      // The head stays, so TalkBack names the sheet; Retry is the one
      // primary, and Close beside it is outline (The One Indigo Rule).
      AsyncError(:final isLoading) => MxBottomSheet(
        title: l10n.cardTagFilterTitle,
        footer: MxSheetActions.single(
          isInSheet: true,
          label: l10n.cardTagFilterClose,
          onPressed: () => Navigator.of(context).pop(),
          tone: MxButtonTone.outline,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.control,
            end: AppSpacing.control,
            bottom: AppSpacing.control,
          ),
          child: MxErrorState(
            title: l10n.cardTagFilterLoadError,
            body: l10n.libraryLoadErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(cardTagFilterProvider(widget.deckId)),
            isRetrying: isLoading,
          ),
        ),
      ),
      _ => MxBottomSheet(
        title: l10n.cardTagFilterTitle,
        subtitle: l10n.cardTagFilterNone,
        child: MxSkeletonList(
          semanticLabel: l10n.commonLoading,
          rows: _skeletonRows,
        ),
      ),
    };
  }

  /// No tag in the library: where tags come from, and Close.
  Widget _none(AppLocalizations l10n) => MxBottomSheet(
    title: l10n.cardTagFilterTitle,
    subtitle: l10n.cardTagFilterEmpty,
    // A lone Close stays primary (The One Indigo Rule, R8).
    footer: MxSheetActions.single(
      isInSheet: true,
      label: l10n.cardTagFilterClose,
      onPressed: () => Navigator.of(context).pop(),
    ),
    child: const SizedBox.shrink(),
  );

  Widget _picker(AppLocalizations l10n, List<TagCount> tags) {
    // A tag gone from the library leaves the draft too (FE-B2 spec D12).
    _draft.retainAll({for (final tag in tags) tag.id});
    final shown = tags.matching(_search.text);
    return MxBottomSheet(
      title: l10n.cardTagFilterTitle,
      subtitle: _draft.isEmpty
          ? l10n.cardTagFilterNone
          : l10n.cardTagFilterChosen(_draft.length),
      footer: MxSheetActions(
        isInSheet: true,
        cancelLabel: l10n.cardTagFilterClear,
        onCancel: _draft.isEmpty ? null : () => setState(_draft.clear),
        confirmLabel: l10n.cardTagFilterApply,
        onConfirm: () => Navigator.of(context).pop({..._draft}),
      ),
      child: Column(
        children: [
          if (tags.length > _searchAbove)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.control,
              ),
              child: MxSearchField(
                controller: _search,
                hintText: l10n.cardTagFilterSearchHint,
                clearLabel: l10n.cardTagFilterSearchClear,
                onChanged: (_) => setState(() {}),
              ),
            ),
          MxDividedColumn(
            children: [
              for (final tag in shown)
                _TagRow(
                  key: ValueKey(tag.id),
                  tag: tag,
                  isChecked: _draft.contains(tag.id),
                  onTap: () => _toggle(tag.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One tag: the box, the name and its cards in this deck. The whole row is
/// the target and one checkbox node.
class _TagRow extends StatelessWidget {
  const _TagRow({
    super.key,
    required this.tag,
    required this.isChecked,
    required this.onTap,
  });

  final TagCount tag;
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      checked: isChecked,
      child: MxListRow(
        leading: MxSelectionCheckbox(isChecked: isChecked),
        title: tag.name,
        trailing: Text(
          context.l10n.cardTagFilterCount(tag.cardCount),
          style: context.textStyles.counter,
        ),
        onTap: onTap,
      ),
    ),
  );
}
