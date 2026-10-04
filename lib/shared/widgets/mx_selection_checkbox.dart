import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The selection-mode box on a card row. It is painted only (ruling I6): the
/// caller's row is the tap target and carries the checked semantics.
class MxSelectionCheckbox extends StatelessWidget {
  const MxSelectionCheckbox({super.key, required this.isChecked});

  final bool isChecked;

  static const double _boxSize = 20;

  /// Contract geometry, below the 16 icon floor (ruling I2).
  static const double _checkSize = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox.square(
      dimension: _boxSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isChecked ? colors.primary : null,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: isChecked
              ? null
              : Border.all(color: colors.outline, width: AppStroke.control),
        ),
        child: isChecked
            ? Center(
                child: Icon(
                  AppIcons.check,
                  size: _checkSize,
                  color: colors.onPrimary,
                ),
              )
            : null,
      ),
    );
  }
}
