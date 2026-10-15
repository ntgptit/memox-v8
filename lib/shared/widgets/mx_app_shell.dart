import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';

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
    this.notice,
    this.isSession = false,
  }) : assert(
         fab == null || footer == null,
         'the Fab contract anchors a FAB to the bottom or above the nav, '
         'never over a footer',
       );

  final Widget body;

  /// MxAppBar or MxStudyTopBar.
  final Widget? appBar;

  /// The navigation bar (MxBottomNav). It owns its own gesture inset.
  final Widget? bottomBar;

  /// The commit bar (MxFooterBar).
  final Widget? footer;

  /// The pinned action (MxFab), anchored by the contract's placement rule.
  final Widget? fab;

  /// A standing MxFloatingNotice over the bottom of the body, 16 in from
  /// each side and above the bottom edge (SB-U1). The body is padded below
  /// by its height, so the end of a scroll clears it.
  final Widget? notice;

  /// A study session keeps the `sizeContentMax` column, centred, in every
  /// window size. Any other screen takes `sizeContentMaxWide` from medium up.
  final bool isSession;

  /// Whether the keyboard is up. Its Scaffold resizes the body above the
  /// keyboard and strips the inset from the body's MediaQuery, so a widget
  /// in the body or footer asks here; outside a shell it reads MediaQuery.
  static bool isTypingOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TypingScope>()?.isTyping ??
      MediaQuery.viewInsetsOf(context).bottom > 0;

  @override
  Widget build(BuildContext context) {
    final appBar = this.appBar;
    // An outer shell (the tab shell) has already stripped the inset from
    // this shell's MediaQuery, so its scope answers first.
    return _TypingScope(
      isTyping: isTypingOf(context),
      child: _scaffold(context, appBar),
    );
  }

  double _columnWidth(BuildContext context) {
    final dimens = context.dimens;
    final isNarrow = isSession || context.windowSize == WindowSize.compact;
    return isNarrow ? dimens.sizeContentMax : dimens.sizeContentMaxWide;
  }

  /// [child] centred in the window, no wider than the shell's column.
  Widget _inColumn(BuildContext context, Widget child) {
    final width = _columnWidth(context);
    return LayoutBuilder(
      builder: (_, constraints) => Center(
        child: SizedBox(
          width: math.min(constraints.maxWidth, width),
          child: child,
        ),
      ),
    );
  }

  Widget _scaffold(BuildContext context, Widget? appBar) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      // A compact window gets its full width, up to `sizeContentMax`; from
      // medium the column is centred at `sizeContentMaxWide`, or stays at
      // `sizeContentMax` in a study session; the ground fills the rest (FE-C5).
      // A context below the Scaffold, whose MediaQuery has already lost the
      // bottom inset when a bottom nav owns it; the shell's own context would
      // hand that inset back to the body.
      body: Builder(
        builder: (bodyContext) => _ScrolledUnderScope(
          builder: (isScrolledUnder) => Column(
            children: [
              if (appBar != null)
                _AppBarGround(
                  // Only the app bar takes the scrolled-under ground; the
                  // study bar paints its own.
                  isScrolledUnder: isScrolledUnder && appBar is MxAppBar,
                  child: _inColumn(context, appBar),
                ),
              Expanded(
                child: _inColumn(
                  context,
                  Column(
                    children: [
                      Expanded(
                        // The app bar owns the top inset; a footer owns the
                        // bottom one.
                        child: MediaQuery.removePadding(
                          context: bodyContext,
                          removeTop: appBar != null,
                          removeBottom: footer != null,
                          child: _NoticeLayer(
                            notice: notice,
                            child: appBar == null
                                ? SafeArea(bottom: false, child: body)
                                : body,
                          ),
                        ),
                      ),
                      ?footer,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: fab,
      floatingActionButtonLocation: _MxFabLocation(
        hasBottomBar: bottomBar != null,
        dimens: context.dimens,
        columnMax: _columnWidth(context),
      ),
    );
  }
}

/// Tells [builder] whether the body's scroll has moved content under the app
/// bar: its vertical scroll, not a nested or sideways one (Material 3: the
/// bar steps from `surface` to `surfaceContainer`).
class _ScrolledUnderScope extends StatefulWidget {
  const _ScrolledUnderScope({required this.builder});

  final Widget Function(bool isScrolledUnder) builder;

  @override
  State<_ScrolledUnderScope> createState() => _ScrolledUnderScopeState();
}

class _ScrolledUnderScopeState extends State<_ScrolledUnderScope> {
  ScrollNotificationObserverState? _observer;
  var _isScrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context)
      ?..addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return;
    if (!defaultScrollNotificationPredicate(notification)) return;
    final metrics = notification.metrics;
    final isScrolledUnder = switch (metrics.axisDirection) {
      AxisDirection.up => metrics.extentAfter > 0,
      AxisDirection.down => metrics.extentBefore > 0,
      AxisDirection.left || AxisDirection.right => _isScrolledUnder,
    };
    if (isScrolledUnder == _isScrolledUnder) return;
    setState(() => _isScrolledUnder = isScrolledUnder);
  }

  @override
  Widget build(BuildContext context) => widget.builder(_isScrolledUnder);
}

/// The app bar's ground, full-bleed behind the capped column: `surface`, or
/// `surfaceContainer` once content scrolls under it. The colour eases over
/// `Durations.short4` unless the platform asks for reduced motion.
class _AppBarGround extends StatelessWidget {
  const _AppBarGround({required this.isScrolledUnder, required this.child});

  final bool isScrolledUnder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        end: isScrolledUnder ? colors.surfaceContainer : colors.surface,
      ),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Durations.short4,
      curve: Easing.standard,
      builder: (_, color, child) => ColoredBox(color: color!, child: child),
      child: child,
    );
  }
}

/// Carries [MxAppShell.isTypingOf] past the Scaffold that strips the inset.
class _TypingScope extends InheritedWidget {
  const _TypingScope({required this.isTyping, required super.child});

  final bool isTyping;

  @override
  bool updateShouldNotify(_TypingScope oldWidget) =>
      isTyping != oldWidget.isTyping;
}

/// FAB placement (Fab contract, caller-owned): 16 from the column's trailing
/// edge, which on a phone is the screen's (FE-C5);
/// 24 + gesture inset above the bottom, or 4 above the bottom bar, which
/// already carries the inset.
final class _MxFabLocation extends FloatingActionButtonLocation {
  const _MxFabLocation({
    required this.hasBottomBar,
    required this.dimens,
    required this.columnMax,
  });

  final bool hasBottomBar;
  final AppDimens dimens;

  /// The widest the content column grows.
  final double columnMax;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final fab = geometry.floatingActionButtonSize;
    final width = geometry.scaffoldSize.width;
    final column = math.min(width, columnMax);
    final columnStart = (width - column) / 2;
    final columnEnd = columnStart + column;
    final x = switch (geometry.textDirection) {
      TextDirection.ltr =>
        math.min(columnEnd, width - geometry.minInsets.right) -
            dimens.space16 -
            fab.width,
      TextDirection.rtl =>
        math.max(columnStart, geometry.minInsets.left) + dimens.space16,
    };
    // The part of the gesture inset not already covered by a bottom widget.
    final bottomContent = geometry.scaffoldSize.height - geometry.contentBottom;
    final inset = math.max(0.0, geometry.minViewPadding.bottom - bottomContent);
    final gap = hasBottomBar ? dimens.space4 : dimens.space24;
    return Offset(x, geometry.contentBottom - fab.height - gap - inset);
  }

  @override
  bool operator ==(Object other) =>
      other is _MxFabLocation &&
      other.hasBottomBar == hasBottomBar &&
      other.dimens == dimens &&
      other.columnMax == columnMax;

  @override
  int get hashCode => Object.hash(hasBottomBar, dimens, columnMax);
}

/// Floats [notice] over the bottom of [child] and pads [child] below by the
/// notice's height, measured after each layout.
class _NoticeLayer extends StatefulWidget {
  const _NoticeLayer({required this.notice, required this.child});

  final Widget? notice;
  final Widget child;

  @override
  State<_NoticeLayer> createState() => _NoticeLayerState();
}

class _NoticeLayerState extends State<_NoticeLayer> {
  double _noticeHeight = 0;

  void _measured(Size size) {
    if (size.height == _noticeHeight) return;
    setState(() => _noticeHeight = size.height);
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;
    if (notice == null) return widget.child;
    final media = MediaQuery.of(context);
    final inset = media.padding.bottom;
    final reserve = _noticeHeight == 0
        ? 0.0
        : _noticeHeight + context.dimens.space16;
    return Stack(
      children: [
        Positioned.fill(
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(bottom: inset + reserve),
            ),
            child: widget.child,
          ),
        ),
        PositionedDirectional(
          start: context.dimens.space16,
          end: context.dimens.space16,
          bottom: context.dimens.space16 + inset,
          child: _SizeReporter(onSize: _measured, child: notice),
        ),
      ],
    );
  }
}

/// Reports its child's size after each layout that changes it.
class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, required super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final measured = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(measured));
  }
}
