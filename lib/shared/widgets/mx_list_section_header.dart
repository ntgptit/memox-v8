import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The overline that introduces a list, with one optional trailing
/// affordance (a ChipTrigger, a Badge, a Button or a plain count). The
/// trailing widget owns its own colours and moves under the label when the
/// row cannot hold both.
class MxListSectionHeader extends StatelessWidget {
  const MxListSectionHeader({
    super.key,
    required this.label,
    this.trailing,
    this.isAfterFilterBand = false,
  });

  final String label;
  final Widget? trailing;

  /// 2 above instead of 0, where the header follows a filter band.
  final bool isAfterFilterBand;

  static const double _afterFilterBandTop = 2;
  static const _padding = EdgeInsetsDirectional.only(
    start: AppSpacing.micro,
    end: AppSpacing.micro,
    bottom: AppSpacing.control,
  );
  static const _afterFilterBandPadding = EdgeInsetsDirectional.fromSTEB(
    AppSpacing.micro,
    _afterFilterBandTop,
    AppSpacing.micro,
    AppSpacing.control,
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: isAfterFilterBand ? _afterFilterBandPadding : _padding,
    // A trailing too wide for the row (large text) moves under the label.
    child: OverflowBar(
      alignment: MainAxisAlignment.spaceBetween,
      spacing: AppSpacing.control,
      overflowSpacing: AppSpacing.control,
      children: [
        Text(
          label.toUpperCase(),
          semanticsLabel: label,
          style: context.textStyles.overline,
        ),
        ?trailing,
      ],
    ),
  );
}
