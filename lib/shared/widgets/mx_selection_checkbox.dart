import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// The selection-mode box on a card row, the Material 3 checkbox: an
/// `onSurfaceVariant` edge when clear, an accent fill with an `onAccentColor`
/// check when checked (the fill is a non-text mark, so the accent, not the
/// `primary` that is 2.46:1 on a dark sheet). It is painted only (ruling I6):
/// the caller's row is the tap target and carries the checked semantics.
class MxSelectionCheckbox extends StatelessWidget {
  const MxSelectionCheckbox({super.key, required this.isChecked});

  final bool isChecked;

  /// Contract geometry, below the 16 icon floor (ruling I2).
  static const double _checkSize = 14;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return SizedBox.square(
      dimension: dimens.sizeSelectionControl,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isChecked ? context.accentColor : null,
          borderRadius: BorderRadius.circular(dimens.radiusCheckbox),
          border: isChecked
              ? null
              : Border.all(
                  color: context.colors.onSurfaceVariant,
                  width: dimens.strokeControl,
                ),
        ),
        child: isChecked
            ? Center(
                child: Icon(
                  AppIcons.check,
                  size: _checkSize,
                  color: context.onAccentColor,
                ),
              )
            : null,
      ),
    );
  }
}
