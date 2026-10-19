import 'package:flutter/material.dart' show RefreshIndicator;
import 'package:flutter/widgets.dart';

/// Pull to refresh over a scrollable [child], even one shorter than the
/// screen: the drag down always reaches [onRefresh]. ForUI has no pull to
/// refresh, so this is Flutter's indicator, kept out of the features.
/// The drag has no TalkBack or keyboard equivalent: a screen that offers it
/// also offers a Refresh action (screen 28).
class MxPullRefresh extends StatelessWidget {
  const MxPullRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ScrollConfiguration(
        behavior: behavior.copyWith(
          physics: AlwaysScrollableScrollPhysics(
            parent: behavior.getScrollPhysics(context),
          ),
        ),
        child: child,
      ),
    );
  }
}
