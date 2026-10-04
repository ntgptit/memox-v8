import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/components/field_style.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

export 'package:memox/core/theme/components/field_style.dart'
    show MxTextFieldVariant;
export 'package:memox/shared/widgets/mx_field_message.dart'
    show MxFieldMessageTone;

/// The digits a one-time code holds.
const int _codeLength = 6;

/// A text input (DESIGN.md, Components › Inputs). The caller names the
/// variant and supplies localized copy; fill, edges, padding and type are
/// the variant's.
class MxTextField extends StatelessWidget {
  const MxTextField({
    required this.controller,
    this.variant = MxTextFieldVariant.form,
    this.label,
    this.requiredText,
    this.hint,
    this.message,
    this.messageTone = MxFieldMessageTone.error,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.isEnabled = true,
    this.shouldAutofocus = false,
    this.isObscured = false,
    this.keyboardType,
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;
  final MxTextFieldVariant variant;

  /// The field label above the field.
  final String? label;

  /// "Required", beside the label, when the field must be filled.
  final String? requiredText;
  final String? hint;

  /// The line under the field; an error also turns the edge to `error`.
  final String? message;
  final MxFieldMessageTone messageTone;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool isEnabled;
  final bool shouldAutofocus;
  final bool isObscured;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  bool get _isCode => variant == MxTextFieldVariant.code;
  bool get _grows =>
      variant == MxTextFieldVariant.detail ||
      variant == MxTextFieldVariant.meaning ||
      variant == MxTextFieldVariant.term;

  @override
  Widget build(BuildContext context) {
    final String? line = message;
    final bool hasError =
        line != null && messageTone == MxFieldMessageTone.error;
    final Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: isEnabled,
      autofocus: shouldAutofocus,
      obscureText: isObscured,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: mxFieldTextStyle(context.texts, variant),
      textAlign: _isCode ? TextAlign.center : TextAlign.start,
      keyboardType: _isCode ? TextInputType.number : keyboardType,
      textInputAction: textInputAction,
      autofillHints: _isCode ? const [AutofillHints.oneTimeCode] : null,
      inputFormatters: _isCode
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_codeLength),
            ]
          : null,
      minLines: _grows ? 1 : null,
      maxLines: _grows ? null : 1,
      decoration: _decoration(context, hasError),
    );
    final String? title = label;
    if (title == null && line == null) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          _Label(text: title, requiredText: requiredText),
          const SizedBox(height: AppSpacing.control),
        ],
        field,
        if (line != null) ...[
          const SizedBox(height: AppSpacing.micro),
          MxFieldMessage(message: line, tone: messageTone),
        ],
      ],
    );
  }

  InputDecoration _decoration(BuildContext context, bool hasError) {
    final ColorScheme colors = context.colors;
    final double radius = mxFieldRadius(variant);
    if (variant == MxTextFieldVariant.study) {
      return InputDecoration(
        hintText: hint,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isCollapsed: true,
      );
    }
    return InputDecoration(
      hintText: hint,
      contentPadding: mxFieldPadding(
        mxFieldTextStyle(context.texts, variant),
        mxFieldMinHeight(variant),
      ),
      enabledBorder: mxFieldBorder(
        color: hasError ? colors.error : colors.outlineVariant,
        radius: radius,
      ),
      focusedBorder: mxFieldBorder(
        color: hasError ? colors.error : colors.primary,
        radius: radius,
        width: AppStroke.control,
      ),
      disabledBorder: mxFieldBorder(
        color: colors.outlineVariant,
        radius: radius,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, this.requiredText});

  final String text;
  final String? requiredText;

  @override
  Widget build(BuildContext context) {
    final String? mark = requiredText;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: Text(text, style: mxFieldLabelStyle(context.texts))),
        if (mark != null) ...[
          const SizedBox(width: AppSpacing.control),
          Text(mark, style: mxRequiredStyle(context.texts, context.colors)),
        ],
      ],
    );
  }
}
