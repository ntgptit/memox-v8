import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
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

  /// A standing MxFloatingNotice over the bottom of the body, the screen
  /// margin in from each side and above the bottom edge (SB-U1). The body is padded below
  /// by its height, so the end of a scroll clears it.
  final Widget? notice;

  /// A full-screen study session: one column of at most
  /// [AppSize.contentMaxWidth] at every window size ("Flashcard Color
  /// Tokens" §5).
  final bool isSession;

  /// The widest the column grows: [AppSize.contentMaxWidth] on a compact
  /// window and in a session, [AppSize.contentMaxWidthWide] from
  /// [AppSize.navRailBreakpoint].
  double _columnMaxWidth(BuildContext context) =>
      isSession || context.isCompactWindow
      ? AppSize.contentMaxWidth
      : AppSize.contentMaxWidthWide;

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
      child: _ToastHost(child: _scaffold(context, appBar)),
    );
  }

  Widget _scaffold(BuildContext context, Widget? appBar) {
    final columnMaxWidth = _columnMaxWidth(context);
    return Scaffold(
      backgroundColor: context.colors.surface,
      // A wide window centres the column at its maximum; the ground fills
      // the rest (FE-C5). A phone gets its full width.
      // A context below the Scaffold, whose MediaQuery has already lost the
      // bottom inset when a bottom nav owns it; the shell's own context would
      // hand that inset back to the body.
      body: Builder(
        builder: (bodyContext) => LayoutBuilder(
          builder: (_, constraints) => Center(
            child: SizedBox(
              width: math.min(constraints.maxWidth, columnMaxWidth),
              child: Column(
                children: [
                  ?appBar,
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
        ),
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: fab,
      floatingActionButtonLocation: _MxFabLocation(
        hasBottomBar: bottomBar != null,
        columnMaxWidth: columnMaxWidth,
        margin: context.screenMargin,
      ),
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

/// Raises the toast over the footers on stage beneath it ([MxToastClearance]).
///
/// The ScaffoldMessenger shows a toast only in the outermost Scaffold of a
/// nested set, and that Scaffold floats it above its own bottom bar alone: a
/// footer is in-flow in a body, so no Scaffold knows it is there. Without
/// this, the toast covered the lower half of a footer's action while it
/// showed (a tab's form under the tab shell, a full-screen route alike). So
/// the shell whose Scaffold is outermost lifts its snackbar inset by the
/// tallest footer reported to it; a shell inside another Scaffold, as a tab's
/// screen, leaves its footers to the shell around it.
class _ToastHost extends StatefulWidget {
  const _ToastHost({required this.child});

  final Widget child;

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> {
  /// Each footer on stage, by its [MxToastClearance], and the height it needs.
  final Map<Object, double> _clearances = {};

  ThemeData? _base;
  double _lift = 0;
  ThemeData? _lifted;

  void _clear(Object footer, double height) {
    if (!mounted || _clearances[footer] == height) return;
    setState(() => _clearances[footer] = height);
  }

  void _release(Object footer) {
    if (!mounted || !_clearances.containsKey(footer)) return;
    setState(() => _clearances.remove(footer));
  }

  @override
  Widget build(BuildContext context) {
    // The same test as ScaffoldMessengerState._isRoot: a Scaffold above
    // this one is where the toast shows.
    if (Scaffold.maybeOf(context) != null) return widget.child;
    final lift = _clearances.values.fold(0.0, math.max);
    return _ToastScope(
      host: this,
      child: Theme(
        data: _liftedBy(Theme.of(context), lift),
        child: widget.child,
      ),
    );
  }

  /// [base] with the toast's bottom inset raised by [lift]; [base] itself
  /// when nothing needs clearing, so no descendant rebuilds for it.
  ThemeData _liftedBy(ThemeData base, double lift) {
    if (lift == 0) return base;
    final lifted = _lifted;
    if (lifted != null && identical(base, _base) && lift == _lift) {
      return lifted;
    }
    final inset = base.snackBarTheme.insetPadding ?? EdgeInsets.zero;
    _base = base;
    _lift = lift;
    return _lifted = base.copyWith(
      snackBarTheme: base.snackBarTheme.copyWith(
        insetPadding: inset.copyWith(bottom: inset.bottom + lift),
      ),
    );
  }
}

/// Hands [_ToastHostState] to the footers under the shell that hosts it.
class _ToastScope extends InheritedWidget {
  const _ToastScope({required this.host, required super.child});

  final _ToastHostState host;

  @override
  bool updateShouldNotify(_ToastScope oldWidget) => host != oldWidget.host;
}

/// Keeps the shell's toast above [child], a bar at the bottom of the screen
/// (MxFooterBar wraps itself in it): while [child] is on stage, the toast
/// floats a gutter above its top edge instead of over its actions. The
/// gesture inset [child] pads below itself is not counted, as the toast
/// already stands above that inset. A bar off stage, on another tab or under
/// a covering route, is not counted either.
class MxToastClearance extends StatefulWidget {
  const MxToastClearance({super.key, required this.child});

  final Widget child;

  @override
  State<MxToastClearance> createState() => _MxToastClearanceState();
}

class _MxToastClearanceState extends State<MxToastClearance> {
  _ToastHostState? _host;
  bool _isOnStage = true;
  double _inset = 0;
  double _height = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = context
        .dependOnInheritedWidgetOfExactType<_ToastScope>()
        ?.host;
    if (!identical(host, _host)) _releaseLater(_host);
    _host = host;
    _isOnStage = TickerMode.valuesOf(context).enabled;
    _inset = MediaQuery.paddingOf(context).bottom;
    // The host is an ancestor; it is told after this frame's build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
  }

  void _measured(Size size) {
    _height = size.height;
    _report();
  }

  void _report() {
    if (!mounted) return;
    _host?._clear(this, _isOnStage ? math.max(0.0, _height - _inset) : 0);
  }

  /// After the frame, since the tree is locked while it is torn down.
  void _releaseLater(_ToastHostState? host) {
    if (host == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => host._release(this));
  }

  @override
  void dispose() {
    _releaseLater(_host);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SizeReporter(onSize: _measured, child: widget.child);
}

/// FAB placement (Fab contract, caller-owned): the screen margin from the
/// column's trailing edge, which on a phone is the screen's (FE-C5);
/// 24 + gesture inset above the bottom, or 4 above the bottom bar, which
/// already carries the inset.
final class _MxFabLocation extends FloatingActionButtonLocation {
  const _MxFabLocation({
    required this.hasBottomBar,
    required this.columnMaxWidth,
    required this.margin,
  });

  final bool hasBottomBar;
  final double columnMaxWidth;
  final double margin;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final fab = geometry.floatingActionButtonSize;
    final width = geometry.scaffoldSize.width;
    final column = math.min(width, columnMaxWidth);
    final columnStart = (width - column) / 2;
    final columnEnd = columnStart + column;
    final x = switch (geometry.textDirection) {
      TextDirection.ltr =>
        math.min(columnEnd, width - geometry.minInsets.right) -
            margin -
            fab.width,
      TextDirection.rtl =>
        math.max(columnStart, geometry.minInsets.left) + margin,
    };
    // The part of the gesture inset not already covered by a bottom widget.
    final bottomContent = geometry.scaffoldSize.height - geometry.contentBottom;
    final inset = math.max(0.0, geometry.minViewPadding.bottom - bottomContent);
    final gap = hasBottomBar ? AppSpacing.micro : AppSpacing.section;
    return Offset(x, geometry.contentBottom - fab.height - gap - inset);
  }

  @override
  bool operator ==(Object other) =>
      other is _MxFabLocation &&
      other.hasBottomBar == hasBottomBar &&
      other.columnMaxWidth == columnMaxWidth &&
      other.margin == margin;

  @override
  int get hashCode => Object.hash(hasBottomBar, columnMaxWidth, margin);
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
        : _noticeHeight + context.screenMargin;
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
          start: context.screenMargin,
          end: context.screenMargin,
          bottom: context.screenMargin + inset,
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
