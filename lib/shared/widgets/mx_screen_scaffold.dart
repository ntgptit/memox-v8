import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';

/// A screen's frame (DESIGN.md, Layout): the top bar, an optional pinned
/// breadcrumb, one body, an optional in-flow footer, and the FAB layered over
/// the body (never over the footer). It knows no tab, route or bottom bar: the
/// navigation shell hands it the room left over as the bottom inset.
///
/// The body, breadcrumb and footer content sit in the column, centred at
/// 720 (The Column Rule); the page ground fills the rest. The body and the
/// footer ride above the keyboard.
class MxScreenScaffold extends StatelessWidget {
  const MxScreenScaffold({
    required this.body,
    this.appBar,
    this.breadcrumb,
    this.footer,
    this.fab,
    super.key,
  });

  final MxAppBar? appBar;

  /// Pinned under the bar, outside the scroll.
  final MxBreadcrumb? breadcrumb;

  /// Any body: an `MxScreenScroll`, an `MxEmptyState`, a centred form.
  final Widget body;

  final MxFooterBar? footer;

  /// The caller passes `null` while its own state hides the FAB (selecting,
  /// searching); the scroll body's tail follows.
  final MxFab? fab;

  @override
  Widget build(BuildContext context) {
    final MxBreadcrumb? path = breadcrumb;
    final MxFooterBar? commit = footer;
    final MxFab? action = fab;
    Widget region = MxScreenScaffoldScope(hasFab: action != null, child: body);
    if (action != null) {
      region = Stack(
        children: [
          Positioned.fill(child: region),
          PositionedDirectional(
            end: AppSpacing.gutter,
            bottom: AppSpacing.gutter + MediaQuery.paddingOf(context).bottom,
            child: action,
          ),
        ],
      );
    }
    // The footer clears the system bar itself; the body above it does not.
    if (commit != null) {
      region = MediaQuery.removePadding(
        context: context,
        removeBottom: true,
        child: region,
      );
    }
    return Scaffold(
      appBar: appBar,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The pinned breadcrumb is part of the top chrome: one ground with
          // the bar as content passes under them.
          if (path != null) MxAppBarGround(child: _InColumn(child: path)),
          Expanded(child: _InColumn(child: region)),
          ?commit,
        ],
      ),
    );
  }
}

/// Centres its child in the 720 content column.
class _InColumn extends StatelessWidget {
  const _InColumn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppBreakpoints.contentMax),
        child: child,
      ),
    );
  }
}

/// Tells the screen's scroll body whether a FAB floats over it, so its tail
/// clears the FAB (The Clear Tail Rule).
class MxScreenScaffoldScope extends InheritedWidget {
  const MxScreenScaffoldScope({
    required this.hasFab,
    required super.child,
    super.key,
  });

  final bool hasFab;

  /// `false` outside a scaffold.
  static bool hasFabOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MxScreenScaffoldScope>()
          ?.hasFab ??
      false;

  @override
  bool updateShouldNotify(MxScreenScaffoldScope oldWidget) =>
      hasFab != oldWidget.hasFab;
}
