import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The column every screen is: top chrome, one scroll body and a bottom bar,
/// with the FAB layered above. The app bar and footer are in-flow siblings of
/// the body, never overlapping it. The app bar sits in the body column rather
/// than `Scaffold.appBar`, so it can grow with text scaling (ruling R1). The
/// footer sits there too, so it stays above the keyboard.
class MxAppShell extends StatelessWidget {
  const MxAppShell({
    super.key,
    required this.body,
    this.appBar,
    this.bottomBar,
    this.footer,
    this.fab,
  });

  final Widget body;

  /// MxAppBar or MxStudyTopBar.
  final Widget? appBar;

  /// The navigation bar (MxBottomNav). It owns its own gesture inset.
  final Widget? bottomBar;

  /// The commit bar (MxFooterBar).
  final Widget? footer;

  /// The pinned action (MxFab), anchored by the contract's placement rule.
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final appBar = this.appBar;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        children: [
          ?appBar,
          Expanded(
            child: appBar == null
                ? SafeArea(bottom: false, child: body)
                : MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: body,
                  ),
          ),
          ?footer,
        ],
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: fab,
      floatingActionButtonLocation: _MxFabLocation(
        hasBottomBar: bottomBar != null,
      ),
    );
  }
}

/// FAB placement (Fab contract, caller-owned): 16 from the trailing edge;
/// 24 + gesture inset above the bottom, or 4 above the bottom bar, which
/// already carries the inset.
final class _MxFabLocation extends FloatingActionButtonLocation {
  const _MxFabLocation({required this.hasBottomBar});

  final bool hasBottomBar;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final fab = geometry.floatingActionButtonSize;
    final x = switch (geometry.textDirection) {
      TextDirection.ltr =>
        geometry.scaffoldSize.width -
            geometry.minInsets.right -
            AppSpacing.gutter -
            fab.width,
      TextDirection.rtl => geometry.minInsets.left + AppSpacing.gutter,
    };
    // The part of the gesture inset not already covered by a bottom widget.
    final bottomContent = geometry.scaffoldSize.height - geometry.contentBottom;
    final inset = math.max(0.0, geometry.minViewPadding.bottom - bottomContent);
    final gap = hasBottomBar ? AppSpacing.micro : AppSpacing.section;
    return Offset(x, geometry.contentBottom - fab.height - gap - inset);
  }

  @override
  bool operator ==(Object other) =>
      other is _MxFabLocation && other.hasBottomBar == hasBottomBar;

  @override
  int get hashCode => hasBottomBar.hashCode;
}
