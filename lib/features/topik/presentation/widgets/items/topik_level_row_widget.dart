import 'package:flutter/material.dart';
import 'package:memox/l10n/meta_line.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/presentation/widgets/support/topik_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A level on screen 34: its name, what it covers and its test count. A
/// level without a valid test keeps its row as information, not as a
/// disabled control: no chevron, no tap, not dimmed (BR-TOPIK-008,
/// critique F5).
class TopikLevelRowWidget extends StatelessWidget {
  const TopikLevelRowWidget({
    super.key,
    required this.level,
    required this.testCount,
    required this.onOpen,
  });

  final TopikLevel level;
  final int testCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasTests = testCount > 0;
    final count = hasTests
        ? l10n.topikTestCount(testCount)
        : l10n.topikNoTestsYet;
    return MxListRow(
      title: l10n.topikLevelName(level),
      meta: Text(
        metaTerms([
          l10n.topikLevelGrades(level),
          l10n.topikBothSections,
          count,
        ]),
        style: context.texts.bodyMedium?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      leading: const MxIconTile(icon: AppIcons.fileText),
      hasChevron: hasTests,
      onTap: hasTests ? onOpen : null,
    );
  }
}
