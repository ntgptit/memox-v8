import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_level_row_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 34 (UC-TOPIK-001): the two exams, each with the number of valid
/// tests the bundled content holds. Where a level leads, `app/` decides.
class TopikHomeScreen extends ConsumerWidget {
  const TopikHomeScreen({super.key, required this.onOpenLevel});

  final ValueChanged<TopikLevel> onOpenLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final children = switch (ref.watch(topikCatalogProvider)) {
      AsyncError(:final error, :final isLoading) => [
        MxErrorState(
          title: l10n.topikErrorTitle,
          body: error is Failure ? l10n.failure(error) : l10n.topikErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(topikCatalogProvider),
          isRetrying: isLoading,
        ),
      ],
      AsyncValue(:final value?) => [_levels(context, value)],
      _ => [
        MxListSectionHeader(label: l10n.topikPractice),
        MxCard(
          isFullBleed: true,
          child: MxSkeletonList(semanticLabel: l10n.topikLoadingTests, rows: 2),
        ),
      ],
    };
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.topikTitle,
        subtitle: l10n.topikSubtitle,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(children: children),
    );
  }

  Widget _levels(BuildContext context, List<TopikCatalogEntry> entries) =>
      MxSection(
        title: context.l10n.topikPractice,
        children: [
          for (final level in TopikLevel.values)
            TopikLevelRowWidget(
              level: level,
              testCount: entries.where((e) => e.test.level == level).length,
              onOpen: () => onOpenLevel(level),
            ),
        ],
      );
}
