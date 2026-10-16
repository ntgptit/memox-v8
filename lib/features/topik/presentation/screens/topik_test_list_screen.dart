import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_list_choice_provider.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_test_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/overlays/topik_sort_sheet_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_test_list_header_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_test_list_skeleton_widget.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_divided_column.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

/// Screen 35 (UC-TOPIK-001): one level's tests of the chosen section, in
/// the chosen order, each with its status, updated in place as attempts
/// change (A2). Where a row leads, `app/` decides.
class TopikTestListScreen extends ConsumerWidget {
  const TopikTestListScreen({
    super.key,
    required this.level,
    required this.onOpenTest,
  });

  final TopikLevel level;
  final ValueChanged<String> onOpenTest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choiceProvider = topikTestListChoiceProvider(level);
    final choice = ref.watch(choiceProvider);
    final body = switch (ref.watch(topikCatalogProvider)) {
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          title: l10n.topikErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(topikCatalogProvider),
          isRetrying: isLoading,
        ),
      ],
      AsyncValue(:final value?) => _loaded(
        context,
        topikTestsOf(
          value,
          level: level,
          section: choice.section,
          order: choice.order,
        ),
        choice,
        onSort: () => unawaited(_sort(context, ref, choice.order)),
      ),
      _ => [TopikTestListSkeletonWidget(semanticLabel: l10n.topikLoadingTests)],
    };
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.topikLevelName(level),
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          // Navigation, so it stays in every state (The Content Gate Rule).
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MxSegmentedTray<TopikSection>(
              segments: [
                for (final section in [
                  TopikSection.reading,
                  TopikSection.listening,
                ])
                  MxSegment(
                    value: section,
                    label: l10n.topikSectionName(section),
                  ),
              ],
              selected: choice.section,
              onSelected: (section) => _pickSection(ref, section),
              isWide: true,
            ),
          ),
          SizedBox(height: context.dimens.space16),
          ...body,
        ],
      ),
    );
  }

  List<Widget> _loaded(
    BuildContext context,
    List<TopikCatalogEntry> entries,
    TopikTestListChoice choice, {
    required VoidCallback onSort,
  }) {
    final l10n = context.l10n;
    if (entries.isEmpty) {
      return [
        MxEmptyState(
          icon: choice.section == TopikSection.reading
              ? AppIcons.book
              : AppIcons.headphones,
          title: l10n.topikSectionEmpty,
          tone: MxEmptyStateTone.neutral,
        ),
      ];
    }
    return [
      TopikTestListHeaderWidget(
        section: choice.section,
        testCount: entries.length,
        order: choice.order,
        onSort: onSort,
      ),
      SizedBox(height: context.dimens.space16),
      MxCard(
        isFullBleed: true,
        child: MxDividedColumn(
          children: [
            for (final entry in entries)
              TopikTestRowWidget(
                entry: entry,
                onOpen: () => onOpenTest(entry.test.testId),
              ),
          ],
        ),
      ),
    ];
  }

  void _pickSection(WidgetRef ref, TopikSection section) => ref
      .read(topikTestListChoiceProvider(level).notifier)
      .pickSection(section);

  Future<void> _sort(
    BuildContext context,
    WidgetRef ref,
    TopikTestOrder selected,
  ) async {
    final order = await showTopikSortSheet(context, selected: selected);
    if (order == null || !context.mounted) return;
    ref.read(topikTestListChoiceProvider(level).notifier).pickOrder(order);
  }
}
