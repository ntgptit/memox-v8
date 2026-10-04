import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

export 'package:memox/core/theme/components/chrome_style.dart'
    show MxAppBarDensity;

/// What sits before the title: nothing (the title starts on the gutter, in
/// line with the body), back, or close (a task or a selection to leave).
enum MxAppBarLeading { none, back, close }

/// The bar's one text action ("Select", "Edit"): the text tone, never a
/// primary fill (a form's save lives in its footer).
class MxAppBarTextAction {
  const MxAppBarTextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;
}

/// The most icon actions a bar carries: with a leading control on a 360
/// phone the title keeps a readable share.
const int _maxIconActions = 3;

/// The top bar (DESIGN.md, MxAppBar): 56 tall, flat `surface` that steps to
/// `surface-container` once content scrolls under it; a leading control, a
/// one-line title, and up to three icon actions or one text action. Its
/// content keeps to the 720 column while its ground spans the window.
///
/// Selecting is not a mode of the bar: the caller passes `close` and the
/// count as the title ("3 selected"), and [isTitleLive] so TalkBack hears the
/// count change.
class MxAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MxAppBar({
    required this.title,
    this.density = MxAppBarDensity.screen,
    this.leading = MxAppBarLeading.none,
    this.onLeading,
    this.actions = const <MxIconButton>[],
    this.textAction,
    this.isTitleLive = false,
    super.key,
  });

  final String title;
  final MxAppBarDensity density;
  final MxAppBarLeading leading;

  /// Runs instead of the default, which pops through `Navigator.maybePop` so
  /// a caller's `PopScope` (and predictive back) still decides.
  final VoidCallback? onLeading;

  /// At most three; none when [textAction] is set.
  final List<MxIconButton> actions;
  final MxAppBarTextAction? textAction;
  final bool isTitleLive;

  @override
  Size get preferredSize => const Size.fromHeight(AppSize.appBar);

  @override
  State<MxAppBar> createState() => _MxAppBarState();
}

class _MxAppBarState extends State<MxAppBar> {
  ScrollNotificationObserverState? _observer;
  bool _isScrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_onScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_onScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_onScroll);
    super.dispose();
  }

  // The screen's own vertical scroll only, as Material's AppBar reads it.
  void _onScroll(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) {
      return;
    }
    if (!defaultScrollNotificationPredicate(notification)) {
      return;
    }
    if (axisDirectionToAxis(notification.metrics.axisDirection) !=
        Axis.vertical) {
      return;
    }
    final bool isUnder = notification.metrics.extentBefore > 0;
    if (isUnder == _isScrolledUnder) {
      return;
    }
    setState(() => _isScrolledUnder = isUnder);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.actions.length <= _maxIconActions,
      'MxAppBar carries at most $_maxIconActions icon actions.',
    );
    assert(
      widget.textAction == null || widget.actions.isEmpty,
      'MxAppBar carries icon actions or one text action, not both.',
    );
    final ColorScheme colors = context.colors;
    return Material(
      color: mxAppBarGround(colors, isScrolledUnder: _isScrolledUnder),
      child: SafeArea(
        bottom: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.contentMax,
              minHeight: AppSize.appBar,
            ),
            child: Row(
              children: [
                _leading(context),
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: widget.isTitleLive,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mxAppBarTitleStyle(
                        context.texts,
                        colors,
                        widget.density,
                      ),
                    ),
                  ),
                ),
                ..._trailing(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // The title starts on the gutter; after a leading control it starts 8
  // past that control's 48 target, which sits 4 from the edge.
  Widget _leading(BuildContext context) {
    if (widget.leading == MxAppBarLeading.none) {
      return const SizedBox(width: AppSpacing.gutter);
    }
    final MaterialLocalizations words = MaterialLocalizations.of(context);
    final bool isBack = widget.leading == MxAppBarLeading.back;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.micro,
        end: AppSpacing.control,
      ),
      child: MxIconButton(
        icon: isBack ? Icons.arrow_back : Icons.close,
        semanticLabel: isBack
            ? words.backButtonTooltip
            : words.closeButtonTooltip,
        onPressed: widget.onLeading ?? () => Navigator.maybePop(context),
      ),
    );
  }

  List<Widget> _trailing() {
    final MxAppBarTextAction? text = widget.textAction;
    if (text != null) {
      return [
        MxButton(
          label: text.label,
          onPressed: text.onPressed,
          tone: MxButtonTone.text,
          size: MxButtonSize.small,
        ),
        const SizedBox(width: AppSpacing.micro),
      ];
    }
    if (widget.actions.isEmpty) {
      return const [SizedBox(width: AppSpacing.gutter)];
    }
    return [...widget.actions, const SizedBox(width: AppSpacing.micro)];
  }
}
