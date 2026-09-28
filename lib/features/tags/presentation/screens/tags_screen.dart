import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/presentation/controllers/tag_actions_controller.dart';
import 'package:memox/features/tags/presentation/providers/tag_catalog_provider.dart';
import 'package:memox/features/tags/presentation/states/tag_actions_state.dart';
import 'package:memox/features/tags/presentation/widgets/items/tag_row_widget.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_actions_sheet_widget.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_delete_dialog_widget.dart';
import 'package:memox/features/tags/presentation/widgets/overlays/tag_rename_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 05, Tags (UC-TAG-001): every tag of the library with its cards,
/// narrowed as the search is typed, each renamed, merged or deleted from
/// its actions. [onFindCards] opens the Library search with a tag's name
/// (FE-B2 spec D11).
class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key, required this.onFindCards});

  final ValueChanged<String> onFindCards;

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  static const int _skeletonRows = 5;

  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TagActionsController _tags() =>
      ref.read(tagActionsControllerProvider.notifier);

  Future<void> _openActions(TagCount tag) async {
    final action = await showTagActionsSheet(context, tag: tag);
    if (action == null || !mounted) return;
    switch (action) {
      case TagAction.findCards:
        widget.onFindCards(tag.name);
      case TagAction.rename:
        await _rename(tag);
      case TagAction.delete:
        await _delete(tag);
    }
  }

  /// The dialog, then the write; a plan that no longer holds opens the
  /// dialog again on the name typed (D8).
  Future<void> _rename(TagCount tag, {String? name}) async {
    final request = await showTagRenameDialog(context, tag: tag, name: name);
    if (request == null || !mounted) return;
    await _write(
      tag,
      () => _tags().rename(
        tagId: tag.id,
        name: request.name,
        mergeIntoTagId: request.mergeIntoTagId,
      ),
      failure: context.l10n.tagsRenameFailed,
      onReplan: () => _rename(tag, name: request.name),
    );
  }

  Future<void> _delete(TagCount tag) async {
    if (!await showTagDeleteDialog(context, tag: tag) || !mounted) return;
    await _write(
      tag,
      () => _tags().delete(tag.id),
      failure: context.l10n.tagsDeleteFailed,
    );
  }

  /// Runs [write] while [tag]'s row spins, then says how it ended; a
  /// success says nothing, the catalog shows it (spec §6).
  Future<void> _write(
    TagCount tag,
    Future<TagWriteResult> Function() write, {
    required String failure,
    Future<void> Function()? onReplan,
  }) async {
    final result = await write();
    if (!mounted) return;
    final l10n = context.l10n;
    switch (result) {
      case TagWriteResult.done:
        return;
      case TagWriteResult.gone:
        showMxSnackbar(context, message: l10n.tagsGone(tag.name));
      case TagWriteResult.replan:
        await onReplan?.call();
      case TagWriteResult.failed:
        showMxSnackbar(
          context,
          message: failure,
          actionLabel: l10n.commonRetry,
          onAction: () => unawaited(
            _write(tag, write, failure: failure, onReplan: onReplan),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(tagCatalogProvider);
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.tagsTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: _back,
        ),
      ),
      body: MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          MxSearchField(
            controller: _search,
            hintText: l10n.tagsSearchHint,
            clearLabel: l10n.tagsSearchClear,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.grouped),
          ...switch (catalog) {
            AsyncData(:final value) => _catalog(l10n, value),
            AsyncError(:final isLoading) => [
              MxErrorState(
                title: l10n.tagsLoadErrorTitle,
                body: l10n.libraryLoadErrorBody,
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(tagCatalogProvider),
                isRetrying: isLoading,
              ),
            ],
            _ => [
              MxSkeletonList(
                semanticLabel: l10n.commonLoading,
                rows: _skeletonRows,
              ),
            ],
          },
        ],
      ),
    );
  }

  void _back() => unawaited(Navigator.of(context).maybePop());

  /// The header, then the rows, or why there are none: no tag at all, or
  /// none under the search (A6).
  List<Widget> _catalog(AppLocalizations l10n, List<TagCount> tags) {
    final term = _search.text.trim();
    final shown = tags.matching(term);
    final busy = ref.watch(tagActionsControllerProvider);
    final header = MxListSectionHeader(
      label: switch ((tags.isEmpty, shown.isEmpty)) {
        (true, _) => l10n.tagsNone,
        (false, true) => l10n.tagsNoMatches,
        _ => l10n.tagsCount(shown.length),
      },
      trailing: Text(l10n.tagsOrder, style: context.textStyles.overline),
    );
    if (tags.isEmpty) {
      return [
        header,
        MxEmptyState(
          icon: AppIcons.tag,
          title: l10n.tagsEmptyTitle,
          body: l10n.tagsEmptyBody,
          actionLabel: l10n.tagsGoToLibrary,
          onAction: _back,
        ),
      ];
    }
    if (shown.isEmpty) {
      return [
        header,
        MxEmptyState(
          icon: AppIcons.search,
          tone: MxEmptyStateTone.neutral,
          isCompact: true,
          title: l10n.tagsSearchEmptyTitle(term),
          body: l10n.tagsSearchEmptyBody,
        ),
      ];
    }
    return [
      header,
      MxSection(
        children: [
          for (final tag in shown)
            TagRowWidget(
              key: ValueKey(tag.id),
              tag: tag,
              isBusy: busy.isBusy(tag.id),
              onActions: () => unawaited(_openActions(tag)),
            ),
        ],
      ),
    ];
  }
}
