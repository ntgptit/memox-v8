import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A study body that may outgrow the screen at large text (FE-A6 P3 C4): a
/// soft fade over its bottom edge while more of it is below, so a cut row
/// reads as "scroll for more" (Impeccable after P3). Decorative: it takes
/// no taps and says nothing to TalkBack.
class StudyScrollFadeWidget extends StatefulWidget {
  const StudyScrollFadeWidget({super.key, required this.child});

  /// A scroll view.
  final Widget child;

  @override
  State<StudyScrollFadeWidget> createState() => _StudyScrollFadeWidgetState();
}

class _StudyScrollFadeWidgetState extends State<StudyScrollFadeWidget> {
  var _hasMoreBelow = false;

  bool _onMetrics(ScrollMetrics metrics) {
    final hasMoreBelow = metrics.extentAfter > 0;
    if (hasMoreBelow != _hasMoreBelow) {
      setState(() => _hasMoreBelow = hasMoreBelow);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ground = context.colors.surface;
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) => _onMetrics(notification.metrics),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) => _onMetrics(notification.metrics),
            child: widget.child,
          ),
        ),
        if (_hasMoreBelow)
          Positioned(
            key: const ValueKey('study-scroll-fade'),
            left: 0,
            right: 0,
            bottom: 0,
            height: AppSpacing.section,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [ground.withValues(alpha: 0), ground],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
