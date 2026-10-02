import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// An eyebrow led by a static primary dot: the Resume banners' marker
/// (13, 14; critique 2026-09-30 part 2). The dot is decorative; the label
/// reads as typed. It carries no padding, so the caller places it.
class MxDotOverline extends StatelessWidget {
  const MxDotOverline({super.key, required this.label});

  final String label;

  static const double _dotSize = 6;

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppSpacing.micro,
    children: [
      ExcludeSemantics(
        child: SizedBox.square(
          dimension: _dotSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
      Flexible(
        child: Text(
          label.toUpperCase(),
          semanticsLabel: label,
          style: context.textStyles.eyebrow,
        ),
      ),
    ],
  );
}
