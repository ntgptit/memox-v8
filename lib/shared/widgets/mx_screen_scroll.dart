import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';

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
      MxScrollClearance.base => AppSpacing.section,
      MxScrollClearance.fab =>
        AppSpacing.section + AppSize.fab + AppSpacing.section,
      MxScrollClearance.fabAboveNav =>
        AppSpacing.micro + AppSize.fab + AppSpacing.section,
    };
    return ListView(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.gutter,
        end: AppSpacing.gutter,
        bottom: tail + MediaQuery.paddingOf(context).bottom,
      ),
      children: children,
    );
  }
}
