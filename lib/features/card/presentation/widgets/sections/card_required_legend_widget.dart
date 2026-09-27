import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The card editor's shared legend (kit 08, 09): a dot and "Required" above
/// the fields, so each field's own marker reads against it.
class CardRequiredLegendWidget extends StatelessWidget {
  const CardRequiredLegendWidget({super.key});

  /// The kit's legend dot.
  static const double _dotSize = 6;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.cardRequiredLegend;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.control),
      child: Row(
        spacing: AppSpacing.micro,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: _dotSize),
            ),
          ),
          Text(
            label.toUpperCase(),
            semanticsLabel: label,
            style: context.textStyles.overline,
          ),
        ],
      ),
    );
  }
}
