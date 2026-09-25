import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

/// What a field holds, which sets its box and its type (kit 08/09).
enum MxTextFieldVariant {
  /// A form or dialog entry: one line, 52 tall, on the muted fill.
  form,

  /// An optional card detail (kit OptionalField): grows from 40.
  detail,

  /// A card's meaning (kit Back): 16/500, grows from 76.
  meaning,

  /// A card's term (kit Front): 24/700, 18/700 past 30 characters, wraps
  /// from 66; Enter still moves on.
  term,
}

typedef _Geometry = ({
  double floor,
  double horizontal,
  double radius,
  bool isMultiline,
});

/// Every form field: a filled surface with a ghost edge, a primary edge on
/// focus, and an error edge with an MxFieldMessage below. Focus, caret,
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
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.leading,
    this.trailing,
  });

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
  final ValueChanged<String>? onChanged;

  /// The keyboard's action key (Done, Next…) was pressed.
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Widget? leading;
  final Widget? trailing;

  static const double _detailFloor = 40;
  static const double _meaningFloor = 76;
  static const double _termFloor = 66;

  /// Past this many characters a term steps down to 18 (kit).
  static const int _termLongAt = 30;

  static _Geometry _geometry(MxTextFieldVariant variant) => switch (variant) {
    MxTextFieldVariant.form => (
      floor: AppSize.input,
      horizontal: AppSpacing.grouped,
      radius: AppRadius.md,
      isMultiline: false,
    ),
    MxTextFieldVariant.detail => (
      floor: _detailFloor,
      horizontal: AppSpacing.grouped,
      radius: AppRadius.md,
      isMultiline: true,
    ),
    MxTextFieldVariant.meaning => (
      floor: _meaningFloor,
      horizontal: AppSpacing.gutter,
      radius: AppRadius.xl,
      isMultiline: true,
    ),
    MxTextFieldVariant.term => (
      floor: _termFloor,
      horizontal: AppSpacing.gutter,
      radius: AppRadius.xl,
      isMultiline: true,
    ),
  };

  TextStyle _valueStyle(BuildContext context) {
    final styles = context.textStyles;
    return switch (variant) {
      MxTextFieldVariant.form => context.texts.bodyMedium!,
      MxTextFieldVariant.detail => styles.fieldDetail,
      MxTextFieldVariant.meaning => styles.fieldMeaning,
      MxTextFieldVariant.term
          when (controller?.text.characters.length ?? 0) > _termLongAt =>
        styles.fieldTermLong,
      MxTextFieldVariant.term => styles.fieldTerm,
    };
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    // A term restyles as it grows past its long mark.
    if (variant == MxTextFieldVariant.term && controller != null) {
      return ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _field(context),
      );
    }
    return _field(context);
  }

  Widget _field(BuildContext context) {
    final colors = context.colors;
    final ghost = context.derivedColors.ghostBorder;
    final hasError = errorText != null;
    final geometry = _geometry(variant);
    OutlineInputBorder edge(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(geometry.radius),
      borderSide: BorderSide(color: color, width: AppStroke.hairline),
    );
    final restingEdge = edge(hasError ? colors.error : ghost);
    // The box height is a floor: padding centres one line of the taller of
    // the value and the hint in it, the constraint absorbs the font's
    // rounding, and more lines or scaled text grow the box.
    final textStyle = _valueStyle(context);
    final hintStyle = variant == MxTextFieldVariant.term
        ? context.textStyles.fieldTermHint
        : context.textStyles.inputHint;
    double lineOf(TextStyle style) => style.fontSize! * style.height!;
    final lineHeight = math.max(lineOf(textStyle), lineOf(hintStyle));
    final isForm = variant == MxTextFieldVariant.form;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: isEnabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      maxLines: geometry.isMultiline ? null : 1,
      // A term wraps but is one line of meaning: Enter fires the action.
      keyboardType: switch (variant) {
        MxTextFieldVariant.detail ||
        MxTextFieldVariant.meaning => TextInputType.multiline,
        _ => TextInputType.text,
      },
      style: textStyle,
      cursorColor: colors.primary,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        constraints: BoxConstraints(minHeight: geometry.floor),
        filled: true,
        // The editor's boxes sit white on the page; a form field lightens
        // only on focus.
        fillColor: WidgetStateColor.resolveWith(
          (states) => !isForm || states.contains(WidgetState.focused)
              ? colors.surfaceContainerLowest
              : colors.surfaceContainerLow,
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: geometry.horizontal,
          vertical: (geometry.floor - lineHeight) / 2,
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
        disabledBorder: edge(ghost),
        focusedBorder: edge(hasError ? colors.error : colors.primary),
      ),
    );
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label case final name?)
          Semantics(label: name, child: field)
        else
          field,
        if (errorText case final message?) MxFieldMessage(message: message),
      ],
    );
    if (isEnabled) return column;
    return Opacity(opacity: AppOpacity.disabled, child: column);
  }
}
