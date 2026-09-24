import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

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
    this.isMultiline = false,
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
  final bool isMultiline;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.micro,
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
          hintText: hint,
          errorText: errorText,
          isMultiline: isMultiline,
          textInputAction: isMultiline
              ? TextInputAction.newline
              : TextInputAction.next,
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
    final styles = context.textStyles;
    final icon = this.icon;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.micro),
      child: Row(
        spacing: AppSpacing.micro,
        children: [
          if (icon != null) Icon(icon, size: AppIconSize.inline),
          // The label and its marker take the room the count leaves, and
          // wrap as a pair rather than splitting the label.
          Expanded(
            child: Wrap(
              spacing: AppSpacing.micro,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  semanticsLabel: label,
                  style: styles.overline,
                ),
                if (isRequired)
                  Text(l10n.cardRequiredLegend, style: styles.requiredMarker)
                else
                  Text(l10n.cardOptional, style: styles.rowDescription),
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
                style: styles.fieldCount(isOver: count > limit),
              );
            },
          ),
        ],
      ),
    );
  }
}
