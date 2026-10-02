import 'package:flutter/material.dart';

/// Android's route transition (the SDK default, predictive back included),
/// or none at all when the system's "remove animations" is on (audit
/// 2026-10-03 A11y, SP1 §5.2).
final class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  static final PageTransitionsBuilder _platform =
      const PageTransitionsTheme().builders[TargetPlatform.android]!;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      _platform.delegatedTransition;

  @override
  Duration get transitionDuration => _platform.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _platform.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return _platform.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
