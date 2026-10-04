import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/components/field_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

export 'package:memox/core/theme/components/field_style.dart'
    show MxTextFieldVariant;
export 'package:memox/shared/widgets/mx_field_message.dart'
    show MxFieldMessageTone;

/// The digits a one-time code holds.
const int _codeLength = 6;

/// The one trailing action a field may carry, drawn as an `MxIconButton`.
class MxTextFieldAction {
  const MxTextFieldAction({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;

  /// Read aloud and shown as the tooltip.
  final String semanticLabel;
  final VoidCallback onPressed;
}

/// The app's one text input (DESIGN.md, The One Field Rule). The caller names
/// the variant and supplies localized copy and input behaviour; fill, edges,
/// padding, type and every state's look are the contract's, never the
/// caller's.
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
    this.isReadOnly = false,
    this.leadingIcon,
    this.trailingAction,
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

  /// Disabled: the whole field dims and cannot be focused or selected.
  final bool isEnabled;

  /// Read-only: full contrast on `surface-container`, no edge and no cursor;
  /// it can still be focused, selected and copied.
  final bool isReadOnly;

  /// A glyph before the text, in `on-surface-variant`.
  final IconData? leadingIcon;
  final MxTextFieldAction? trailingAction;
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
      readOnly: isReadOnly,
      showCursor: isReadOnly ? false : null,
      autofocus: shouldAutofocus,
      obscureText: isObscured,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: mxFieldTextStyle(context.texts, variant),
      textAlign: _isCode ? TextAlign.center : TextAlign.start,
      // A growing field keeps its first line where it starts.
      textAlignVertical: _grows ? TextAlignVertical.top : null,
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
    return _dimmedUnlessEnabled(_withLabelAndMessage(field, line));
  }

  Widget _dimmedUnlessEnabled(Widget child) {
    if (isEnabled) {
      return child;
    }
    return Opacity(opacity: AppOpacity.disabled, child: child);
  }

  Widget _withLabelAndMessage(Widget field, String? line) {
    final String? title = label;
    if (title == null && line == null) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          // Read once, as the field's own name, not as a loose line above it.
          ExcludeSemantics(
            child: _Label(text: title, requiredText: requiredText),
          ),
          const SizedBox(height: AppSpacing.control),
        ],
        _named(field, title),
        if (line != null) ...[
          const SizedBox(height: AppSpacing.micro),
          MxFieldMessage(message: line, tone: messageTone),
        ],
      ],
    );
  }

  /// The visible label is the field's accessible name (WCAG 4.1.2).
  Widget _named(Widget field, String? title) {
    if (title == null) {
      return field;
    }
    // The "Required" mark follows the name as its hint.
    return Semantics(label: title, hint: requiredText, child: field);
  }

  InputDecoration _decoration(BuildContext context, bool hasError) {
    final IconData? glyph = leadingIcon;
    final MxTextFieldAction? action = trailingAction;
    return mxFieldDecoration(
      colors: context.colors,
      texts: context.texts,
      variant: variant,
      hint: hint,
      hasError: hasError,
      isReadOnly: isReadOnly,
      prefixIcon: glyph == null
          ? null
          : Icon(
              glyph,
              size: AppIconSize.medium,
              color: context.colors.onSurfaceVariant,
            ),
      suffixIcon: action == null
          ? null
          : MxIconButton(
              icon: action.icon,
              semanticLabel: action.semanticLabel,
              onPressed: action.onPressed,
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
