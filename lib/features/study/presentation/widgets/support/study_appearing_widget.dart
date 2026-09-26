import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A hidden study face (16a, 19): the kit's still placeholder bar until
/// [isShown], then [child] fading and rising in (16a Motion); at once under
/// Remove animations.
class StudyAppearingWidget extends StatelessWidget {
  const StudyAppearingWidget({
    super.key,
    required this.isShown,
    required this.child,
  });

  final bool isShown;
  final Widget child;

  static const Offset _rise = Offset(0, 0.04);

  @override
  Widget build(BuildContext context) {
    final isStill = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: isStill ? Duration.zero : AppDurations.standard,
      switchInCurve: Easing.standard,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(begin: _rise, end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: isShown
          ? KeyedSubtree(key: const ValueKey(true), child: child)
          : const _HiddenBar(key: ValueKey(false)),
    );
  }
}

/// A hidden face (kit Recall): a still bar, not a loading skeleton — nothing
/// is loading, and it says nothing to TalkBack.
class _HiddenBar extends StatelessWidget {
  const _HiddenBar({super.key});

  static const Size _size = Size(140, 14);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.fromSize(
      size: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    ),
  );
}
