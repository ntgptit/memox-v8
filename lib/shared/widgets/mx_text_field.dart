import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' show InputBorder;
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_code_field.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_user_edits.dart';

/// How a field takes its text. Every boxed variant is ForUI's large touch
/// text field (DEV-169, DEV-372).
enum MxTextFieldVariant {
  /// A form or dialog entry: one line.
  form,

  /// A multi-line entry (a card's meaning or detail, pasted rows): grows
  /// with its lines, Enter breaks the line.
  detail,

  /// A card's term: wraps like [detail] but is one line of meaning, so
  /// Enter still moves on.
  term,

  /// A typed study answer (kit Fill): bare — no edge in any state —
  /// one centred line in the study term role, inside the answer face that
  /// frames it (FE-A6 P4 F1).
  study,

  /// A sign-in code (account UI spec U2; sign-in redesign 2026-10-05 §4.1):
  /// six slots painted over one hidden field, which keeps the numeric
  /// keyboard, the one-time-code autofill, paste and the TalkBack label.
  code,
}

/// Every form field, on ForUI's [FTextField]: ForUI's border at rest, its
/// focus ring on focus and its error tone in error; the label above it, and
/// a supporting row below that holds the supporting text or the error
/// message, with the counter at its trailing end. Focus, selection and IME
/// are the platform's. Validation and the message text are the caller's.
class MxTextField extends StatelessWidget {
  const MxTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.labelLeading,
    this.labelTrailing,
    this.hintText,
    this.supportingText,
    this.counter,
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

  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// The field's name: painted above the box in the label role (the error
  /// tone in error), and announced by TalkBack with the value. A hint
  /// disappears once typed, so a field that needs a name always gets a label.
  /// The bare study field and the code slots paint none: the screen around
  /// them names them.
  final String? label;

  /// A glyph before the painted [label], such as an optional field's mark.
  /// It takes the label's colour; the caller sizes it.
  final Widget? labelLeading;

  /// A marker after the painted [label], such as "Required".
  final Widget? labelTrailing;
  final String? hintText;

  /// A line under the box, in ForUI's description style. An [errorText]
  /// takes its place.
  final String? supportingText;

  /// The count against a limit, such as "12 / 60", at the trailing end of the
  /// supporting row. It takes the error tone with the field.
  final String? counter;

  /// Non-null turns the field to its error tone and shows this message below.
  final String? errorText;
  final MxTextFieldVariant variant;
  final bool isEnabled;

  /// Takes the focus when first shown, such as the sign-in code.
  final bool isAutofocused;

  /// Shows the value but takes no input, such as a code being checked.
  final bool isReadOnly;

  /// The person changed the text (not the selection, not the code).
  final ValueChanged<String>? onChanged;

  /// The keyboard's action key (Done, Next…) was pressed.
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Widget? leading;
  final Widget? trailing;

  /// The digits a sign-in code holds (auth spec O1).
  static const int codeLength = 6;

  bool get _isMultiline =>
      variant == MxTextFieldVariant.detail ||
      variant == MxTextFieldVariant.term;

  @override
  Widget build(BuildContext context) {
    if (variant == MxTextFieldVariant.code) return MxCodeField(field: this);
    final edits = MxUserEdits(onChanged);
    final isBare = variant == MxTextFieldVariant.study;
    final hasError = errorText != null;
    final field = FTextField(
      // Autofocus is read once, on mount: a field that was disabled when
      // first built takes the focus when it is enabled, so the flip remounts.
      key: ValueKey(isEnabled),
      control: FTextFieldControl.managed(
        controller: controller,
        onChange: edits.onChange,
      ),
      size: FTextFieldSizeVariant.lg,
      style: isBare
          ? _bareStyle(context)
          : const FTextFieldStyleDelta.context(),
      label: isBare ? null : _paintedLabel(context, hasError),
      hint: hintText,
      description: hasError || isBare ? null : _supportingRow(context, null),
      error: hasError ? _supportingRow(context, errorText) : null,
      focusNode: focusNode,
      autofocus: isAutofocused,
      enabled: isEnabled,
      readOnly: isReadOnly,
      onSubmit: onSubmitted,
      textInputAction: textInputAction,
      inputFormatters: [edits.formatter],
      maxLines: _isMultiline ? null : 1,
      // A term wraps but is one line of meaning: Enter fires the action.
      keyboardType: variant == MxTextFieldVariant.detail
          ? TextInputType.multiline
          : TextInputType.text,
      textAlign: isBare ? TextAlign.center : TextAlign.start,
      prefixBuilder: leading == null
          ? null
          : (context, _, _) => Padding(
              padding: EdgeInsetsDirectional.only(
                start: context.dimens.space12,
                end: context.dimens.space8,
              ),
              child: leading,
            ),
      suffixBuilder: trailing == null
          ? null
          : (context, _, _) => Padding(
              padding: EdgeInsetsDirectional.only(
                start: context.dimens.space8,
                end: context.dimens.space12,
              ),
              child: trailing,
            ),
    );
    // A bare field has no box to reach its 48 target with: the floor holds
    // it around its one line.
    final target = isBare
        ? ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.dimens.sizeControl),
            child: Center(child: field),
          )
        : field;
    if (label case final name?) return Semantics(label: name, child: target);
    return target;
  }

  /// The study answer: no edge in any state, no padding, the term role.
  FTextFieldStyleDelta _bareStyle(BuildContext context) =>
      FTextFieldStyleDelta.delta(
        border:
            const FVariants<
              FTextFieldVariantConstraint,
              FTextFieldVariant,
              InputBorder,
              Delta
            >.all(InputBorder.none),
        contentPadding: const EdgeInsetsGeometryDelta.value(EdgeInsets.zero),
        contentTextStyle:
            FVariants<
              FTextFieldVariantConstraint,
              FTextFieldVariant,
              TextStyle,
              TextStyleDelta
            >.all(context.texts.term),
      );

  /// The label above the box, with its leading glyph and trailing marker.
  Widget? _paintedLabel(BuildContext context, bool hasError) {
    final name = label;
    if (name == null) return null;
    final leading = labelLeading;
    return Row(
      spacing: context.dimens.space4,
      children: [
        ?leading,
        // The label and its marker take the room there is, and wrap as a
        // pair rather than splitting the label.
        Expanded(
          child: Wrap(
            spacing: context.dimens.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // The field carries the name, so TalkBack reads it once.
              ExcludeSemantics(child: Text(name)),
              ?labelTrailing,
            ],
          ),
        ),
      ],
    );
  }

  /// The row under the box: [message] (the error) or the supporting text,
  /// with the counter at its trailing end; null when there is none of them.
  Widget? _supportingRow(BuildContext context, String? message) {
    final support = supportingText;
    final count = counter;
    if (message == null && support == null && count == null) return null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.dimens.space8,
      children: [
        Expanded(
          child: switch ((message, support)) {
            (final message?, _) => MxFieldMessage(message: message),
            (_, final support?) => Text(support),
            _ => const SizedBox.shrink(),
          },
        ),
        ?switch (count) {
          final value? => Text(value),
          null => null,
        },
      ],
    );
  }
}
