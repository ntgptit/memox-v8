import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_code_field.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

/// How a field takes its text. Every boxed variant shares one box and one
/// type: the form fill, radius 12, padding 12, 52 tall, the body role
/// (DEV-169).
enum MxTextFieldVariant {
  /// A form or dialog entry: one line.
  form,

  /// A multi-line entry (a card's meaning or detail, pasted rows): grows
  /// with its lines, Enter breaks the line.
  detail,

  /// A card's term: wraps like [detail] but is one line of meaning, so
  /// Enter still moves on.
  term,

  /// A typed study answer (kit Fill): bare — no fill, no edge in any state —
  /// one centred line in the study term role, inside the answer face that
  /// frames it (FE-A6 P4 F1).
  study,

  /// A sign-in code (account UI spec U2; sign-in redesign 2026-10-05 §4.1):
  /// six slots painted over one hidden field, which keeps the numeric
  /// keyboard, the one-time-code autofill, paste and the TalkBack label.
  code,
}

typedef _Geometry = ({
  double floor,
  double horizontal,
  double vertical,
  bool isMultiline,
});

/// Every form field: a filled surface on the Outline Edge at rest (a ghost
/// edge when disabled), a primary edge on focus, and an error edge with an MxFieldMessage below. Focus, caret,
/// selection and IME are the platform's. Validation and the message text are
/// the caller's.
class MxTextField extends StatelessWidget {
  const MxTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.errorText,
    this.variant = MxTextFieldVariant.form,
    this.isEnabled = true,
    this.isAutofocused = false,
    this.isReadOnly = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.leading,
    this.trailing,
  }) : assert(
         variant == MxTextFieldVariant.form ||
             (leading == null && trailing == null),
         'Only a form field takes leading and trailing slots: a multi-line box '
         'measures its text across its whole width',
       );

  /// [field] on [controller]: a multi-line box that must follow typing owns
  /// one when its caller does not. The outer field keeps the key.
  MxTextField._on(MxTextField field, TextEditingController this.controller)
    : focusNode = field.focusNode,
      label = field.label,
      hintText = field.hintText,
      errorText = field.errorText,
      variant = field.variant,
      isEnabled = field.isEnabled,
      isAutofocused = field.isAutofocused,
      isReadOnly = field.isReadOnly,
      onChanged = field.onChanged,
      onSubmitted = field.onSubmitted,
      textInputAction = field.textInputAction,
      leading = field.leading,
      trailing = field.trailing;

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// The field's name for TalkBack, announced with its value. Never painted:
  /// the caller shows its own label, and a hint disappears once typed.
  final String? label;
  final String? hintText;

  /// Non-null turns the field to its error tone and shows this message below.
  final String? errorText;
  final MxTextFieldVariant variant;
  final bool isEnabled;

  /// Takes the focus when first shown, such as the sign-in code.
  final bool isAutofocused;

  /// Shows the value but takes no input, such as a code being checked.
  final bool isReadOnly;

  final ValueChanged<String>? onChanged;

  /// The keyboard's action key (Done, Next…) was pressed.
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Widget? leading;
  final Widget? trailing;

  /// The digits a sign-in code holds (auth spec O1).
  static const int codeLength = 6;

  static _Geometry _geometry(MxTextFieldVariant variant) => switch (variant) {
    MxTextFieldVariant.form || MxTextFieldVariant.code => (
      floor: AppSize.input,
      horizontal: AppSpacing.grouped,
      // Centred by the floor: see _field.
      vertical: 0,
      isMultiline: false,
    ),
    // One line sits exactly as a form field does; more lines keep 12 above
    // and below.
    MxTextFieldVariant.detail || MxTextFieldVariant.term => (
      floor: AppSize.input,
      horizontal: AppSpacing.grouped,
      vertical: AppSpacing.grouped,
      isMultiline: true,
    ),
    MxTextFieldVariant.study => (
      floor: AppSize.touchTarget,
      horizontal: 0,
      vertical: 0,
      isMultiline: false,
    ),
  };

  TextStyle _valueStyle(BuildContext context) {
    final styles = context.textStyles;
    return switch (variant) {
      MxTextFieldVariant.study => styles.studyTerm,
      MxTextFieldVariant.code => styles.fieldCode,
      _ => context.texts.bodyMedium!,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (variant == MxTextFieldVariant.code) return MxCodeField(field: this);
    final controller = this.controller;
    if (!_geometry(variant).isMultiline) return _field(context, null);
    // A multi-line box pads to its floor around what it holds, which follows
    // the text and the width.
    Widget sized() => LayoutBuilder(
      builder: (context, constraints) => _field(context, constraints.maxWidth),
    );
    if (controller == null) return _OwnController(field: this);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => sized(),
    );
  }

  /// The vertical padding that brings the box to its floor. A form field
  /// centres one line; a multi-line box keeps its padding, or more when
  /// what it shows (its value, or its hint while empty) is shorter than the
  /// floor, measured at [width] and the reader's text scale.
  double _verticalPadding(
    BuildContext context,
    double? width,
    TextStyle valueStyle,
    TextStyle hintStyle,
  ) {
    final geometry = _geometry(variant);
    double lineOf(TextStyle style) => style.fontSize! * style.height!;
    if (width == null) {
      final scaler = MediaQuery.textScalerOf(context);
      final line = math.max(
        scaler.scale(lineOf(valueStyle)),
        scaler.scale(lineOf(hintStyle)),
      );
      // Scaled text that outgrows the floor sets the height itself.
      return math.max(0, (geometry.floor - line) / 2);
    }
    final inner = width - 2 * geometry.horizontal;
    // ponytail: two TextPainter layouts per rebuild, and the controller
    // rebuilds on every keystroke and caret move. Cheap at the card fields'
    // 240-character cap; cache on (text, width, scale) if a longer-form
    // variant ever arrives.
    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        textHeightBehavior: DefaultTextHeightBehavior.maybeOf(context),
      )..layout(maxWidth: inner);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final value = controller?.text ?? '';
    // A typed value sizes the box alone: the hint is hidden and holds no
    // room (maintainHintSize off), so a short value sits on the 52 floor
    // beside the other fields. An empty value still holds one line.
    final hint = hintText;
    final shown = measure(value.isEmpty ? ' ' : value, valueStyle);
    final content = value.isEmpty && hint != null
        ? math.max(shown, measure(hint, hintStyle))
        : shown;
    return math.max(geometry.vertical, (geometry.floor - content) / 2);
  }

  // The code variant never reaches here: MxCodeField draws it.
  Widget _field(BuildContext context, double? width) {
    final colors = context.colors;
    final hasError = errorText != null;
    final geometry = _geometry(variant);
    // The theme carries the field (spec §4.6): its fill, which lightens on
    // focus, and its edges; an error holds the error edge at rest too.
    final fields = Theme.of(context).inputDecorationTheme;
    final restingEdge = hasError ? fields.errorBorder : fields.enabledBorder;
    // The box height is a floor painted by the decorator itself, reached by
    // padding (InputDecoration.constraints reserves the height but paints
    // the fill and edge around the text only); more lines or scaled text
    // grow the box.
    final textStyle = _valueStyle(context);
    final hintStyle = context.fieldHint;
    final isBare = variant == MxTextFieldVariant.study;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: isAutofocused,
      enabled: isEnabled,
      readOnly: isReadOnly,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      maxLines: geometry.isMultiline ? null : 1,
      // A term wraps but is one line of meaning: Enter fires the action.
      keyboardType: switch (variant) {
        MxTextFieldVariant.detail => TextInputType.multiline,
        _ => TextInputType.text,
      },
      style: textStyle,
      textAlign: isBare ? TextAlign.center : TextAlign.start,
      cursorColor: colors.primary,
      textAlignVertical: TextAlignVertical.center,
      decoration: isBare
          ? const InputDecoration(
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            )
          : InputDecoration(
              hintText: hintText,
              hintStyle: hintStyle,
              maintainHintSize: false,
              contentPadding: EdgeInsets.symmetric(
                horizontal: geometry.horizontal,
                vertical: _verticalPadding(
                  context,
                  width,
                  textStyle,
                  hintStyle,
                ),
              ),
              prefixIcon: leading == null
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.grouped,
                        end: AppSpacing.control,
                      ),
                      child: leading,
                    ),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: trailing == null
                  ? null
                  : Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.control,
                        end: AppSpacing.grouped,
                      ),
                      child: trailing,
                    ),
              suffixIconConstraints: const BoxConstraints(),
              border: restingEdge,
              enabledBorder: restingEdge,
              disabledBorder: fields.disabledBorder,
              focusedBorder: hasError
                  ? fields.focusedErrorBorder
                  : fields.focusedBorder,
            ),
    );
    // A bare field has no padded box to reach its floor with: the floor
    // holds the 48 touch target around its one line.
    final target = isBare
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: geometry.floor),
            child: field,
          )
        : field;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label case final name?)
          Semantics(label: name, child: target)
        else
          target,
        if (errorText case final message?) MxFieldMessage(message: message),
      ],
    );
    if (isEnabled) return column;
    return Opacity(opacity: AppOpacity.disabled, child: column);
  }
}

/// Owns the controller a multi-line box listens to when its caller passed none.
class _OwnController extends StatefulWidget {
  const _OwnController({required this.field});

  final MxTextField field;

  @override
  State<_OwnController> createState() => _OwnControllerState();
}

class _OwnControllerState extends State<_OwnController> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      MxTextField._on(widget.field, _controller);
}
