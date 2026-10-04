import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
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
/// footer ride above the keyboard. A snackbar shown from the screen floats
/// above its footer and FAB (see [MxScreenScaffoldScope]).
class MxScreenScaffold extends StatefulWidget {
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
  State<MxScreenScaffold> createState() => _MxScreenScaffoldState();
}

class _MxScreenScaffoldState extends State<MxScreenScaffold> {
  /// The footer's height, measured after layout.
  double _footerHeight = 0;

  void _onFooterHeight(double height) {
    if (!mounted || height == _footerHeight) {
      return;
    }
    setState(() => _footerHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.breadcrumb == null || widget.appBar != null,
      'MxScreenScaffold pins a breadcrumb under its bar; give it the bar.',
    );
    // The Scaffold hides the keyboard from its body; read it here, once.
    final bool isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: widget.appBar,
      // The body's own MediaQuery: the Scaffold has already taken the bar's
      // top inset and the keyboard out of it.
      body: Builder(builder: (context) => _frame(context, isTyping)),
    );
  }

  Widget _frame(BuildContext context, bool isTyping) {
    final MxBreadcrumb? path = widget.breadcrumb;
    final MxFooterBar? commit = widget.footer;
    final MxFab? action = widget.fab;
    final MediaQueryData media = MediaQuery.of(context);
    // While typing, the keyboard covers the system bar (a bottom inset the
    // shell hands down included); with a footer, the footer clears it. The
    // body takes no bottom inset in either case.
    final MediaQueryData clear = media.removePadding(removeBottom: true);
    final bool isBottomHeld = commit != null || isTyping;
    final MediaQueryData inner = isBottomHeld ? clear : media;
    Widget region = widget.body;
    if (action != null) {
      final bool isRtl = Directionality.of(context) == TextDirection.rtl;
      final double endInset = isRtl ? inner.padding.left : inner.padding.right;
      region = Stack(
        children: [
          Positioned.fill(child: region),
          PositionedDirectional(
            end: AppSpacing.gutter + endInset,
            bottom: AppSpacing.gutter + inner.padding.bottom,
            child: action,
          ),
        ],
      );
    }
    // What a snackbar must clear: the footer, and the FAB above it.
    final double footerHeight = commit == null ? 0 : _footerHeight;
    final double fabRoom = action == null ? 0 : AppSize.fab + AppSpacing.gutter;
    return MxScreenScaffoldScope(
      hasFab: action != null,
      bottomChrome: footerHeight + fabRoom,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The pinned breadcrumb is part of the top chrome: one ground with
          // the bar as content passes under them.
          if (path != null) MxAppBarGround(child: _InColumn(child: path)),
          Expanded(
            child: MediaQuery(
              data: inner,
              child: _InColumn(child: region),
            ),
          ),
          if (commit != null)
            _Measured(
              onHeight: _onFooterHeight,
              child: MediaQuery(data: isTyping ? clear : media, child: commit),
            ),
        ],
      ),
    );
  }
}

/// Reports its child's height after each layout that changes it.
class _Measured extends SingleChildRenderObjectWidget {
  const _Measured({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  _RenderMeasured createRenderObject(BuildContext context) =>
      _RenderMeasured(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasured render) {
    render.onHeight = onHeight;
  }
}

class _RenderMeasured extends RenderProxyBox {
  _RenderMeasured(this.onHeight);

  ValueChanged<double> onHeight;
  double? _reported;

  @override
  void performLayout() {
    super.performLayout();
    final double height = size.height;
    if (height == _reported) {
      return;
    }
    _reported = height;
    // Not during layout: the scaffold rebuilds with it after this frame.
    SchedulerBinding.instance.addPostFrameCallback((_) => onHeight(height));
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
/// clears the FAB (The Clear Tail Rule), and a snackbar how much bottom
/// chrome (the footer, the FAB) it must float above.
class MxScreenScaffoldScope extends InheritedWidget {
  const MxScreenScaffoldScope({
    required this.hasFab,
    required this.bottomChrome,
    required super.child,
    super.key,
  });

  final bool hasFab;
  final double bottomChrome;

  /// `0` outside a scaffold. Read once, when a snackbar is shown.
  static double bottomChromeOf(BuildContext context) =>
      context
          .getInheritedWidgetOfExactType<MxScreenScaffoldScope>()
          ?.bottomChrome ??
      0;

  /// `false` outside a scaffold.
  static bool hasFabOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MxScreenScaffoldScope>()
          ?.hasFab ??
      false;

  @override
  bool updateShouldNotify(MxScreenScaffoldScope oldWidget) =>
      hasFab != oldWidget.hasFab || bottomChrome != oldWidget.bottomChrome;
}
