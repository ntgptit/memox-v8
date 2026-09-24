import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';

/// Every form field: a filled surface with a ghost edge, a lighter fill and a
/// primary edge on focus, and an error edge with an MxFieldMessage below.
/// Focus, caret, selection and IME are the platform's. Validation and the
/// message text are the caller's.
class MxTextField extends StatelessWidget {
  const MxTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.isMultiline = false,
    this.isEnabled = true,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.leading,
    this.trailing,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// Non-null turns the field to its error tone and shows this message below.
  final String? errorText;

  /// The card editor's box: starts at 40 and grows with the text.
  final bool isMultiline;
  final bool isEnabled;
  final ValueChanged<String>? onChanged;

  /// The keyboard's action key (Done, Search…) was pressed.
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Widget? leading;
  final Widget? trailing;

  static const double _multilineMinHeight = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ghost = context.derivedColors.ghostBorder;
    final hasError = errorText != null;
    OutlineInputBorder edge(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: AppStroke.hairline),
    );
    final restingEdge = edge(hasError ? colors.error : ghost);
    // The box height is a floor, painted by the decorator itself: padding
    // centres one line of text in it at 1x, and scaled text grows the box.
    // (InputDecoration.constraints reserves the height but paints the fill
    // and edge around the text only.)
    final textStyle = context.texts.bodyMedium!;
    final lineHeight = textStyle.fontSize! * textStyle.height!;
    final floor = isMultiline ? _multilineMinHeight : AppSize.input;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: isEnabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      maxLines: isMultiline ? null : 1,
      keyboardType: isMultiline ? TextInputType.multiline : null,
      style: textStyle,
      cursorColor: colors.primary,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: context.textStyles.inputHint,
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.surfaceContainerLowest
              : colors.surfaceContainerLow,
        ),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.grouped,
          vertical: (floor - lineHeight) / 2,
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
        field,
        if (errorText case final message?) MxFieldMessage(message: message),
      ],
    );
    if (isEnabled) return column;
    return Opacity(opacity: AppOpacity.disabled, child: column);
  }
}
