import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Rows stacked with the ghost hairline between them and none after the
/// last: the one owner of list dividers (DEV-305). A section, a sheet or a
/// full-bleed card holds its rows in one; a row draws no edge of its own.
/// A long, paged list keeps its rows lazy with [divided] instead.
class MxDividedColumn extends StatelessWidget {
  const MxDividedColumn({super.key, required this.children});

  final List<Widget> children;

  /// [rows] with the hairline between them, as the children of a lazy
  /// scroll view (the users and log lists): each row is still built only
  /// when it comes into view.
  static List<Widget> divided(List<Widget> rows) => [
    for (final (index, row) in rows.indexed) ...[
      if (index > 0) const _Hairline(),
      row,
    ],
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: divided(children),
  );
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppStroke.hairline,
    child: ColoredBox(color: context.derivedColors.ghostBorder),
  );
}
