import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_screen_scaffold.dart';

/// A screen's one scroll body (DESIGN.md, Layout): the 16 gutter on both
/// sides and a tail, so the last item is never trapped. The tail is 48 under
/// pinned chrome, or clears the FAB (its 52 plus a gutter on each side) while
/// one floats over the body (The Clear Tail Rule), above the system bar.
/// The first item starts flush; the gaps between items are the screen's own.
class MxScreenScroll extends StatelessWidget {
  const MxScreenScroll({required this.children, this.controller, super.key})
    : itemCount = null,
      itemBuilder = null;

  /// A long list, built as it scrolls in.
  const MxScreenScroll.builder({
    required int this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
    this.controller,
    super.key,
  }) : children = const <Widget>[];

  final List<Widget> children;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final double tail = MxScreenScaffoldScope.hasFabOf(context)
        ? AppSize.fab + 2 * AppSpacing.gutter
        : AppSpacing.pageEnd;
    // The system insets the scaffold leaves to the body (a cutout, the
    // status bar without a top bar, the system bar without a footer).
    final EdgeInsets system = MediaQuery.paddingOf(context);
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      AppSpacing.gutter + system.left,
      system.top,
      AppSpacing.gutter + system.right,
      tail + system.bottom,
    );
    final IndexedWidgetBuilder? build = itemBuilder;
    final int? count = itemCount;
    if (build != null && count != null) {
      return ListView.builder(
        controller: controller,
        padding: padding,
        itemCount: count,
        itemBuilder: build,
      );
    }
    return ListView(
      controller: controller,
      padding: padding,
      children: children,
    );
  }
}
