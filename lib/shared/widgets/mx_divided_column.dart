import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Rows stacked with the ghost hairline between them and none after the
/// last: the one owner of list dividers (DEV-305). A section, a sheet or a
/// full-bleed card holds its rows in one; a row draws no edge of its own.
class MxDividedColumn extends StatelessWidget {
  const MxDividedColumn({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = SizedBox(
      height: AppStroke.hairline,
      child: ColoredBox(color: context.derivedColors.ghostBorder),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, child) in children.indexed) ...[
          if (index > 0) divider,
          child,
        ],
      ],
    );
  }
}
