import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Which pinned chrome the scroll's tail must clear. The caller picks it from
/// the chrome its screen has: nav or a footer is [base], because both are
/// in-flow.
enum MxScrollClearance { base, fab, fabAboveNav }

/// The single scrollable region of a screen: the shared 16 gutter and a tail
/// clearance derived from the pinned chrome, plus the gesture inset.
class MxScreenScroll extends StatelessWidget {
  const MxScreenScroll({
    super.key,
    required this.children,
    this.clearance = MxScrollClearance.base,
  });

  final List<Widget> children;
  final MxScrollClearance clearance;

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
        start: context.dimens.space16,
        end: context.dimens.space16,
        bottom: tail + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}
