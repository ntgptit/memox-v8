import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/app_button_style.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// The bounded integer input (cards per session). It owns the invalid ring,
/// the busy spinner and the disabled dim. The bounds, the clamping and the
/// validation message are the caller's: at a bound, pass null for that
/// button's callback and it stops without a separate look.
class MxStepper extends StatelessWidget {
  const MxStepper({
    super.key,
    required this.value,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onDecrement,
    required this.onIncrement,
    this.isInvalid = false,
    this.isBusy = false,
    this.isEnabled = true,
  });

  final int value;
  final String decrementLabel;
  final String incrementLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool isInvalid;

  /// A spinner replaces the number while the write is in flight.
  final bool isBusy;
  final bool isEnabled;

  /// So 1 and 200 occupy the same width.
  static const double _valueColumn = 48;
  static const double _buttonPadding = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final control = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.micro,
      children: [
        _StepButton(
          icon: AppIcons.remove,
          label: decrementLabel,
          onPressed: isEnabled ? onDecrement : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _valueColumn,
            minHeight: AppSize.buttonSmall,
          ),
          child: DecoratedBox(
            key: const ValueKey('mx-stepper-value'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              // Ruling I3. A null border when valid: turning invalid adds
              // colour, never layout.
              border: isInvalid
                  ? Border.all(color: colors.error, width: AppStroke.hairline)
                  : null,
            ),
            child: Center(
              widthFactor: 1,
              child: isBusy
                  ? const MxSpinner()
                  : Text(
                      value.toString(),
                      style: context.textStyles.stepperValue(
                        isInvalid: isInvalid,
                      ),
                    ),
            ),
          ),
        ),
        _StepButton(
          icon: AppIcons.add,
          label: incrementLabel,
          onPressed: isEnabled ? onIncrement : null,
        ),
      ],
    );
    if (isEnabled) return control;
    return Opacity(opacity: AppOpacity.disabled, child: control);
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: label,
      // The icon carries the name into the button node; announcing the
      // tooltip too would read it twice.
      excludeFromSemantics: true,
      child: TextButton(
        onPressed: onPressed,
        style:
            appButtonStyle(
              fill: colors.surfaceContainer,
              ink: colors.onSurface,
              edge: BorderSide.none,
              focusColor: colors.primary,
              height: AppSize.buttonSmall,
              radius: AppRadius.md,
              padding: MxStepper._buttonPadding,
              label: context.textStyles.buttonLabel,
            ).copyWith(
              fixedSize: const WidgetStatePropertyAll(
                Size.square(AppSize.buttonSmall),
              ),
            ),
        child: Icon(icon, size: AppIconSize.compact, semanticLabel: label),
      ),
    );
  }
}
