import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_code_field.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

/// How a field takes its text. Every boxed variant shares one box and one
/// type: the Material 3 outlined field, radius 12, padding 16, 56 tall, the
/// input role (DEV-169, DEV-372).
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

typedef _Geometry = ({
  double floor,
  double horizontal,
  double vertical,
  bool isMultiline,
});

/// Every form field: the Material 3 outlined field, with no fill. The edge is
/// the outline at rest, the focus ring on focus and the error tone in error
/// (the error container's on-colour while the pointer is over it); the label
/// sits above it, and a supporting row below holds the supporting text or the
/// error message, with the counter at its trailing end. Focus, selection and
/// IME are the platform's; the caret turns to the error tone with the edge.
/// Validation and the message text are the caller's.
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

  /// [field] on [controller]: a multi-line box that must follow typing owns
  /// one when its caller does not. The outer field keeps the key.
  MxTextField._on(MxTextField field, TextEditingController this.controller)
    : focusNode = field.focusNode,
      label = field.label,
      labelLeading = field.labelLeading,
      labelTrailing = field.labelTrailing,
      hintText = field.hintText,
      supportingText = field.supportingText,
      counter = field.counter,
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

  /// The field's name: painted above the box, 4 clear of it and on its text
  /// inset, in `onSurfaceVariant` (the error tone in error), and announced
  /// by TalkBack with the value. A hint disappears once typed, so a field
  /// that needs a name always gets a label. The bare study field and the code
  /// slots paint none: the screen around them names them.
  final String? label;

  /// A glyph before the painted [label], such as an optional field's mark.
  /// It takes the label's colour; the caller sizes it.
  final Widget? labelLeading;

  /// A marker after the painted [label], such as "Required".
  final Widget? labelTrailing;
  final String? hintText;

  /// A line under the box on its text inset, in the supporting-text role. An
  /// [errorText] takes its place.
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

  final ValueChanged<String>? onChanged;

  /// The keyboard's action key (Done, Next…) was pressed.
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Widget? leading;
  final Widget? trailing;

  /// The digits a sign-in code holds (auth spec O1).
  static const int codeLength = 6;

  static _Geometry _geometry(
    BuildContext context,
    MxTextFieldVariant variant,
  ) => switch (variant) {
    MxTextFieldVariant.form || MxTextFieldVariant.code => (
      floor: context.dimens.sizeInput,
      horizontal: context.dimens.space16,
      // Centred by the floor: see _field.
      vertical: 0,
      isMultiline: false,
    ),
    // One line sits exactly as a form field does; more lines keep 12 above
    // and below.
    MxTextFieldVariant.detail || MxTextFieldVariant.term => (
      floor: context.dimens.sizeInput,
      horizontal: context.dimens.space16,
      vertical: context.dimens.space12,
      isMultiline: true,
    ),
    MxTextFieldVariant.study => (
      floor: context.dimens.sizeControl,
      horizontal: 0,
      vertical: 0,
      isMultiline: false,
    ),
  };

  TextStyle _valueStyle(BuildContext context) {
    return switch (variant) {
      MxTextFieldVariant.study ||
      MxTextFieldVariant.code => context.texts.displaySmall!,
      _ => context.texts.bodyLarge!,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (variant == MxTextFieldVariant.code) return MxCodeField(field: this);
    final controller = this.controller;
    if (!_geometry(context, variant).isMultiline) return _field(context, null);
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
    final geometry = _geometry(context, variant);
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
    // room (maintainHintSize off), so a short value sits on the 56 floor
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
    final geometry = _geometry(context, variant);
    // The theme carries the field (spec §4.6): its edge, suffix glyph and
    // hint resolve from the decorator's own states, and a disabled field takes
    // the theme's disabled edge and hint once, with no wrapper dimming them
    // again.
    final fields = Theme.of(context).inputDecorationTheme;
    // The box height is a floor painted by the decorator itself, reached by
    // padding (InputDecoration.constraints reserves the height but paints
    // the fill and edge around the text only); more lines or scaled text
    // grow the box.
    final textStyle = _valueStyle(context).copyWith(
      color: isEnabled
          ? null
          : colors.onSurface.withValues(
              alpha: context.dimens.opacityDisabledContent,
            ),
    );
    final hintStyle = WidgetStateProperty.resolveAs(
      fields.hintStyle!,
      <WidgetState>{},
    );
    final isBare = variant == MxTextFieldVariant.study;
    final field = TextField(
      // Autofocus is read once, on mount: a field that was disabled when
      // first built takes the focus when it is enabled, so the flip remounts.
      key: ValueKey(isEnabled),
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
      cursorColor: hasError ? colors.error : colors.primary,
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
                      padding: EdgeInsetsDirectional.only(
                        start: context.dimens.space12,
                        end: context.dimens.space8,
                      ),
                      child: leading,
                    ),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: trailing == null
                  ? null
                  : Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: context.dimens.space8,
                        end: context.dimens.space12,
                      ),
                      child: trailing,
                    ),
              suffixIconConstraints: const BoxConstraints(),
              // The decorator is in error, so its states reach the edge and
              // the suffix glyph; the message is the supporting row's, and a
              // widget of no size adds no line of its own.
              error: hasError ? const SizedBox.shrink() : null,
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
    final heading = _paintedLabel(context, hasError);
    final supporting = _supportingRow(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ?heading,
        if (label case final name?)
          Semantics(label: name, child: target)
        else
          target,
        ?supporting,
      ],
    );
  }

  /// The label above the box, or null when this field paints none.
  Widget? _paintedLabel(BuildContext context, bool hasError) {
    final name = label;
    if (name == null) return null;
    if (variant == MxTextFieldVariant.study) return null;
    final color = _supportColor(
      context,
      hasError: hasError,
      isEnabled: isEnabled,
    );
    final leading = labelLeading;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.dimens.space16,
        end: context.dimens.space16,
        bottom: context.dimens.space4,
      ),
      child: IconTheme.merge(
        data: IconThemeData(color: color),
        child: Row(
          spacing: context.dimens.space4,
          children: [
            ?leading,
            // The label and its marker take the room there is, and wrap as
            // a pair rather than splitting the label.
            Expanded(
              child: Wrap(
                spacing: context.dimens.space4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // The field below carries the name, so TalkBack reads it
                  // once.
                  ExcludeSemantics(
                    child: Text(
                      name,
                      style: context.texts.labelMedium?.copyWith(color: color),
                    ),
                  ),
                  ?labelTrailing,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The row under the box: the error message, or the supporting text, with
  /// the counter at its trailing end; null when there is none of them.
  Widget? _supportingRow(BuildContext context) {
    final message = errorText;
    final support = supportingText;
    final count = counter;
    if (message == null && support == null && count == null) return null;
    final hasError = message != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: switch ((message, support)) {
            (final message?, _) => MxFieldMessage(message: message),
            (_, final support?) => _SupportingLine(
              text: support,
              color: _supportColor(
                context,
                hasError: false,
                isEnabled: isEnabled,
              ),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
        if (count != null)
          _SupportingLine(
            text: count,
            color: _supportColor(
              context,
              hasError: hasError,
              isEnabled: isEnabled,
            ),
          ),
      ],
    );
  }
}

/// The colour of a field's label, supporting text and counter: the variant
/// tone, the error tone in error, the disabled content tone when disabled.
Color _supportColor(
  BuildContext context, {
  required bool hasError,
  required bool isEnabled,
}) {
  final colors = context.colors;
  return switch ((isEnabled, hasError)) {
    (false, _) => colors.onSurface.withValues(
      alpha: context.dimens.opacityDisabledContent,
    ),
    (_, true) => colors.error,
    _ => colors.onSurfaceVariant,
  };
}

/// A line of the supporting row, on the field's text inset, in the
/// supporting-text role (`bodySmall`): the supporting text and the counter.
class _SupportingLine extends StatelessWidget {
  const _SupportingLine({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: context.dimens.space16,
      top: context.dimens.space4,
      end: context.dimens.space16,
    ),
    child: Text(text, style: context.texts.bodySmall?.copyWith(color: color)),
  );
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
