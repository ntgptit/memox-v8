import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// One card field (kit 08/09): the label with its glyph and "Required" or
/// "· optional", then the input, then the count against the limit at the
/// trailing end of its supporting row. A required field always shows its
/// count; an optional one shows it once typed. The count turns to the error
/// tone with the field's error, which a text past the limit always carries.
class CardFieldWidget extends StatelessWidget {
  const CardFieldWidget({
    super.key,
    required this.label,
    required this.hint,
    required this.limit,
    required this.controller,
    this.icon,
    this.isRequired = false,
    this.variant = MxTextFieldVariant.form,
    this.focusNode,
    this.errorText,
    this.onChanged,
    this.isReadOnly = false,
  });

  final String label;
  final String hint;

  /// In characters as a person sees them (BR-CARD-002, BR-CARD-003).
  final int limit;
  final TextEditingController controller;

  /// The optional fields' glyph (kit `OptionalField`).
  final IconData? icon;
  final bool isRequired;

  /// How the field takes its text: a term moves on at Enter, a meaning or
  /// detail breaks the line. Every card field shares the form box.
  final MxTextFieldVariant variant;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  /// Held while the card saves, so nothing typed meanwhile is lost to the
  /// form clearing for the next card.
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final icon = this.icon;
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimens.space16),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final count = value.text.characters.length;
          return MxTextField(
            controller: controller,
            focusNode: focusNode,
            label: label,
            labelLeading: icon == null
                ? null
                : Icon(icon, size: context.dimens.sizeIconInline),
            labelTrailing: isRequired
                ? Text(
                    l10n.cardRequiredLegend,
                    style: context.texts.body.copyWith(
                      color: context.colors.primary,
                    ),
                  )
                : Text(
                    l10n.cardOptional,
                    style: context.texts.body.copyWith(
                      color: context.colors.mutedForeground,
                    ),
                  ),
            hintText: hint,
            counter: !isRequired && count == 0
                ? null
                : l10n.cardFieldCount(count, limit),
            errorText: errorText,
            variant: variant,
            isReadOnly: isReadOnly,
            // The term and a form field move on; a meaning or detail breaks
            // the line.
            textInputAction: switch (variant) {
              MxTextFieldVariant.term ||
              MxTextFieldVariant.form => TextInputAction.next,
              _ => TextInputAction.newline,
            },
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}
