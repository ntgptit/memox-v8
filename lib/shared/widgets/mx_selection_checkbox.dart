import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/control_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The mark of a multi-select row: an 18 box, r4, a 2dp `outline` stroke when
/// empty and an Indigo Accent box with a `primary-container` check when
/// chosen. It
/// paints only; the row that holds it owns the tap, the label and the 48 area,
/// and its semantics merge this checked state.
class MxSelectionCheckbox extends StatelessWidget {
  const MxSelectionCheckbox({required this.isChecked, super.key});

  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    final style = mxCheckboxColors(context.colors, isChecked: isChecked);
    final Color? edge = style.edge;
    return Semantics(
      checked: isChecked,
      child: AnimatedContainer(
        duration: AppDurations.toggle,
        width: AppSize.checkbox,
        height: AppSize.checkbox,
        decoration: BoxDecoration(
          color: style.box,
          borderRadius: BorderRadius.circular(AppRadius.xs),
          border: edge == null
              ? null
              : Border.all(color: edge, width: AppStroke.control),
        ),
        child: isChecked
            ? Icon(Icons.check, size: AppIconSize.small, color: style.check)
            : null,
      ),
    );
  }
}
