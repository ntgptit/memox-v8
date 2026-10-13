import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

/// The overview's content ("Flashcard Color Tokens" §5): one column, or two
/// side by side once the content area holds two [AppSize.overviewColumnMin]
/// columns and the section gap. It measures its own area, not the window.
class StudyHomeOverviewColumnsWidget extends StatelessWidget {
  const StudyHomeOverviewColumnsWidget({
    super.key,
    required this.lead,
    required this.trail,
  });

  /// The resume card, when a session waits, and the workload.
  final List<Widget> lead;

  /// The decks.
  final Widget trail;

  static const double _splitWidth =
      2 * AppSize.overviewColumnMin + AppSpacing.section;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final leadColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.gutter,
        children: lead,
      );
      if (constraints.maxWidth < _splitWidth) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.gutter,
          children: [leadColumn, trail],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.section,
        children: [
          Expanded(child: leadColumn),
          Expanded(child: trail),
        ],
      );
    },
  );
}
