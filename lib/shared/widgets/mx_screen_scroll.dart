import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// Which pinned chrome the scroll's tail must clear. The caller picks it from
/// the chrome its screen has: nav or a footer is [base], because both are
/// in-flow.
enum MxScrollClearance { base, fab, fabAboveNav }

/// The single scrollable region of a screen: the screen margin, the body's
/// gap under the app bar and a tail clearance derived from the pinned chrome,
/// plus the gesture inset. The gap is the scroll's, so no screen picks its
/// own (spacing spec 2026-10-20, L1).
class MxScreenScroll extends StatelessWidget {
  const MxScreenScroll({
    super.key,
    required this.children,
    this.clearance = MxScrollClearance.base,
    this.top,
  });

  final List<Widget> children;
  final MxScrollClearance clearance;

  /// The gap above the first child; `space8` when null. A screen that sits
  /// close under its own chrome (Library under its search field) or a pane
  /// with its own layout passes its value.
  final double? top;

  @override
  Widget build(BuildContext context) {
    final tail = switch (clearance) {
      MxScrollClearance.base => context.dimens.space24,
      MxScrollClearance.fab =>
        context.dimens.space24 +
            context.dimens.sizeFab +
            context.dimens.space24,
      MxScrollClearance.fabAboveNav =>
        context.dimens.space4 + context.dimens.sizeFab + context.dimens.space24,
    };
    return ListView(
      padding: EdgeInsetsDirectional.only(
        start: context.screenMargin,
        top: top ?? context.dimens.space8,
        end: context.screenMargin,
        bottom: tail + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}
