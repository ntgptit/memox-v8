import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// An overview's blocks in one column, or in two when the content area is wide
/// enough. The choice is the width this widget is given (the content area, with
/// the navigation rail already taken off), not the window's size class.
class MxTwoColumns extends StatelessWidget {
  const MxTwoColumns({super.key, required this.start, required this.end});

  /// The blocks of the leading column, top to bottom.
  final List<Widget> start;

  /// The blocks of the trailing column; they follow [start] in one column.
  final List<Widget> end;

  /// The content width from which two columns of 300 or more fit with a
  /// `space24` gap between them.
  static const double minWidth = 672;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < minWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: dimens.space16,
            children: [...start, ...end],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: dimens.space24,
          children: [
            Expanded(child: _column(dimens.space16, start)),
            Expanded(child: _column(dimens.space16, end)),
          ],
        );
      },
    );
  }

  Widget _column(double gap, List<Widget> blocks) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: gap,
    children: blocks,
  );
}
