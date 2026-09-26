import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
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
///
/// Holding − or + repeats the step (FE-A3 D6). With [onValueSubmitted], a
/// tap on the number turns it into a digits-only field; Done or leaving the
/// field hands the text back, and the caller parses and validates it.
class MxStepper extends StatefulWidget {
  const MxStepper({
    super.key,
    required this.value,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onDecrement,
    required this.onIncrement,
    this.valueLabel,
    this.editHint,
    this.onValueSubmitted,
    this.maxDigits = _defaultMaxDigits,
    this.isInvalid = false,
    this.isBusy = false,
    this.isEnabled = true,
  });

  final int value;
  final String decrementLabel;
  final String incrementLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  /// The number's name for TalkBack ("Cards per session"), read with its
  /// value.
  final String? valueLabel;

  /// The action TalkBack names for typing a value ("Edit").
  final String? editHint;

  /// Non-null makes the number typeable; receives the typed digits.
  final ValueChanged<String>? onValueSubmitted;

  /// How many digits the field takes.
  final int maxDigits;
  final bool isInvalid;

  /// A spinner replaces the number while the write is in flight.
  final bool isBusy;
  final bool isEnabled;

  /// So 1 and 200 occupy the same width.
  static const double _valueColumn = 48;
  static const double _buttonPadding = 0;

  /// Cards per session tops out at 200.
  static const int _defaultMaxDigits = 3;

  @override
  State<MxStepper> createState() => _MxStepperState();
}

class _MxStepperState extends State<MxStepper> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  var _isEditing = false;

  bool get _canEdit =>
      widget.onValueSubmitted != null && widget.isEnabled && !widget.isBusy;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _submit();
    });
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _edit() {
    final text = widget.value.toString();
    _field.value = TextEditingValue(
      text: text,
      selection: TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    setState(() => _isEditing = true);
    _focus.requestFocus();
  }

  void _submit() {
    if (!_isEditing) return;
    setState(() => _isEditing = false);
    widget.onValueSubmitted?.call(_field.text);
  }

  /// A step while typing first hands over what was typed.
  VoidCallback? _step(VoidCallback? onStep) {
    if (onStep == null || !widget.isEnabled) return null;
    return () {
      _submit();
      onStep();
    };
  }

  @override
  Widget build(BuildContext context) {
    final control = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.micro,
      children: [
        _StepButton(
          icon: AppIcons.remove,
          label: widget.decrementLabel,
          onPressed: _step(widget.onDecrement),
        ),
        _value(context),
        _StepButton(
          icon: AppIcons.add,
          label: widget.incrementLabel,
          onPressed: _step(widget.onIncrement),
        ),
      ],
    );
    if (widget.isEnabled) return control;
    return Opacity(opacity: AppOpacity.disabled, child: control);
  }

  Widget _value(BuildContext context) {
    final colors = context.colors;
    final style = context.textStyles.stepperValue(isInvalid: widget.isInvalid);
    final box = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: MxStepper._valueColumn,
        minHeight: AppSize.buttonSmall,
      ),
      child: DecoratedBox(
        key: const ValueKey('mx-stepper-value'),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          // Ruling I3. A null border when valid and not typing: turning
          // invalid adds colour, never layout.
          border: widget.isInvalid || _isEditing
              ? Border.all(
                  color: widget.isInvalid
                      ? colors.error
                      : context.derivedColors.primaryInk,
                  width: AppStroke.hairline,
                )
              : null,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: switch ((widget.isBusy, _isEditing)) {
            (true, _) => const MxSpinner(),
            (_, true) => SizedBox(
              width: MxStepper._valueColumn,
              child: TextField(
                controller: _field,
                focusNode: _focus,
                style: style,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.maxDigits),
                ],
                decoration: const InputDecoration.collapsed(hintText: null),
                onSubmitted: (_) => _submit(),
              ),
            ),
            _ => Text(widget.value.toString(), style: style),
          },
        ),
      ),
    );
    if (_isEditing) return box;
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: _canEdit,
      label: widget.valueLabel,
      value: widget.value.toString(),
      onTap: _canEdit ? _edit : null,
      onTapHint: _canEdit ? widget.editHint : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _canEdit ? _edit : null,
        // The box stays button-small; the tap target is a full one.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
          child: Center(widthFactor: 1, heightFactor: 1, child: box),
        ),
      ),
    );
  }
}

/// A − or + button. A hold repeats it, first after
/// [AppDurations.stepperRepeatDelay] and then every
/// [AppDurations.stepperRepeatInterval], until release or a null
/// [onPressed] (the caller's bound).
class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  Timer? _timer;

  /// Set once a hold has stepped, so its release is not one more tap.
  var _hasRepeated = false;

  @override
  void didUpdateWidget(_StepButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _stop();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start(PointerDownEvent _) {
    _hasRepeated = false;
    _stop();
    if (widget.onPressed == null) return;
    _timer = Timer(AppDurations.stepperRepeatDelay, () {
      _repeat();
      _timer = Timer.periodic(
        AppDurations.stepperRepeatInterval,
        (_) => _repeat(),
      );
    });
  }

  void _repeat() {
    final onPressed = widget.onPressed;
    if (onPressed == null) {
      _stop();
      return;
    }
    _hasRepeated = true;
    onPressed();
  }

  void _stop([PointerEvent? _]) {
    _timer?.cancel();
    _timer = null;
  }

  void _tap() {
    if (_hasRepeated) {
      _hasRepeated = false;
      return;
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Listener(
      onPointerDown: _start,
      onPointerUp: _stop,
      onPointerCancel: _stop,
      child: Tooltip(
        message: widget.label,
        // The icon carries the name into the button node; announcing the
        // tooltip too would read it twice.
        excludeFromSemantics: true,
        child: TextButton(
          onPressed: widget.onPressed == null ? null : _tap,
          style:
              appButtonStyle(
                fill: colors.surfaceContainer,
                ink: colors.onSurface,
                edge: BorderSide.none,
                focusColor: context.derivedColors.primaryInk,
                height: AppSize.buttonSmall,
                radius: AppRadius.md,
                padding: MxStepper._buttonPadding,
                label: context.textStyles.buttonLabel,
              ).copyWith(
                fixedSize: const WidgetStatePropertyAll(
                  Size.square(AppSize.buttonSmall),
                ),
              ),
          child: Icon(
            widget.icon,
            size: AppIconSize.compact,
            semanticLabel: widget.label,
          ),
        ),
      ),
    );
  }
}
