import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// One card field (kit 08/09): the overline label, "Required" or
/// "· optional", the count against the limit, then the input. A required
/// field always shows its count; an optional one shows it once typed.
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

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: context.dimens.space16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.dimens.space4,
      children: [
        _FieldHeader(
          label: label,
          icon: icon,
          isRequired: isRequired,
          controller: controller,
          limit: limit,
        ),
        MxTextField(
          controller: controller,
          focusNode: focusNode,
          label: label,
          hintText: hint,
          errorText: errorText,
          variant: variant,
          // The term and a form field move on; a meaning or detail breaks
          // the line.
          textInputAction: switch (variant) {
            MxTextFieldVariant.term ||
            MxTextFieldVariant.form => TextInputAction.next,
            _ => TextInputAction.newline,
          },
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _FieldHeader extends StatelessWidget {
  const _FieldHeader({
    required this.label,
    required this.icon,
    required this.isRequired,
    required this.controller,
    required this.limit,
  });

  final String label;
  final IconData? icon;
  final bool isRequired;
  final TextEditingController controller;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final icon = this.icon;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.dimens.space4),
      child: Row(
        spacing: context.dimens.space4,
        children: [
          if (icon != null) Icon(icon, size: context.dimens.sizeIconInline),
          // The label and its marker take the room the count leaves, and
          // wrap as a pair rather than splitting the label.
          Expanded(
            child: Wrap(
              spacing: context.dimens.space4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // The input carries the name, so TalkBack reads it once.
                ExcludeSemantics(
                  child: Text(label, style: context.texts.labelMedium),
                ),
                if (isRequired)
                  Text(
                    l10n.cardRequiredLegend,
                    style: context.texts.bodyMedium?.copyWith(
                      color: context.accentColor,
                    ),
                  )
                else
                  Text(
                    l10n.cardOptional,
                    style: context.texts.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final count = value.text.characters.length;
              if (!isRequired && count == 0) return const SizedBox.shrink();
              return Text(
                l10n.cardFieldCount(count, limit),
                style: context.texts.labelSmall?.copyWith(
                  color: count > limit
                      ? context.colors.error
                      : context.colors.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
