import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dot_overline.dart';

/// The card editor's shared legend (kit 08, 09): a dot and "Required" above
/// the fields, so each field's own marker reads against it.
class CardRequiredLegendWidget extends StatelessWidget {
  const CardRequiredLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: MxDotOverline(label: context.l10n.cardRequiredLegend),
    );
  }
}
