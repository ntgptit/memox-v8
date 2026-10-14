import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The selection-mode box on a card row, the Material 3 checkbox: an
/// `onSurfaceVariant` edge when clear, a `primary` fill with an `onPrimary`
/// check when checked. It is painted only (ruling I6): the caller's row is the
/// tap target and carries the checked semantics.
class MxSelectionCheckbox extends StatelessWidget {
  const MxSelectionCheckbox({super.key, required this.isChecked});

  final bool isChecked;

  /// Contract geometry, below the 16 icon floor (ruling I2).
  static const double _checkSize = 14;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    return SizedBox.square(
      dimension: dimens.sizeSelectionControl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isChecked ? colors.primary : null,
          borderRadius: BorderRadius.circular(dimens.radiusCheckbox),
          border: isChecked
              ? null
              : Border.all(
                  color: colors.onSurfaceVariant,
                  width: dimens.strokeControl,
                ),
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
