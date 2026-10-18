import 'package:flutter/widgets.dart';
import 'package:memox/shared/widgets/mx_divider.dart';

/// Rows stacked with an inset divider between them and none after the last:
/// the one owner of list dividers (DEV-305). A section, a sheet or a
/// full-bleed card holds its rows in one; a row draws no edge of its own.
/// A long, paged list keeps its rows lazy with [divided] instead.
///
/// The line is [MxDivider], inset 16 at each end, at the rows' own content
/// edge.
class MxDividedColumn extends StatelessWidget {
  const MxDividedColumn({super.key, required this.children});

  final List<Widget> children;

  /// [rows] with the divider between them, as the children of a lazy scroll
  /// view (the users and log lists): each row is still built only when it
  /// comes into view.
  static List<Widget> divided(List<Widget> rows) => [
    for (final (index, row) in rows.indexed) ...[
      if (index > 0) const MxDivider(),
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
