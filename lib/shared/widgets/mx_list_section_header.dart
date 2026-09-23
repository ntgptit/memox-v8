import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The overline that introduces a list, with one optional trailing
/// affordance (a ChipTrigger, a Badge, a Button or a plain count). The
/// trailing widget owns its own colours.
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      spacing: AppSpacing.control,
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: context.textStyles.overline,
          ),
        ),
        ?trailing,
      ],
    ),
  );
}
