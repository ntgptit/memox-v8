import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_button.dart';

/// A session screen's actions, centred under the faces. Two share the row,
/// each up to 160 wide, and stack full width at large text, as 16a's grades
/// do; one button spans the width of that row, so a lone Continue weighs
/// what a pair does (critique 2026-09-30). Any other lone child (the grade
/// row) keeps its own layout.
class StudyCtaRowWidget extends StatelessWidget {
  const StudyCtaRowWidget({super.key, required this.children});

  /// One or two actions.
  final List<Widget> children;

  static const double _actionWidth = 160;

  /// From this text scale on, two actions no longer share a row.
  static const double _stackTextScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final isStacked =
        children.length > 1 &&
        MediaQuery.textScalerOf(context).scale(1) >= _stackTextScale;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.gutter,
        AppSpacing.gutter,
        0,
      ),
      child: switch (children) {
        [final MxButton only] => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 2 * _actionWidth + AppSpacing.control,
            ),
            child: SizedBox(width: double.infinity, child: only),
          ),
        ),
        [final only] => Center(child: only),
        _ when isStacked => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.control,
          children: children,
        ),
        _ => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.control,
          children: [
            for (final action in children)
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _actionWidth),
                  child: SizedBox(width: double.infinity, child: action),
                ),
              ),
          ],
        ),
      },
    );
  }
}
