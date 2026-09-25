import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/widgets/items/card_add_details_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// One optional card field's input: its text, its message, and the touch
/// that lets the form show that message.
typedef CardOptionalInput = ({
  TextEditingController controller,
  String? errorText,
  VoidCallback onChanged,
});

/// The card editor's optional details (kit 08/09): "Add details" until
/// opened, then example, hint and pronunciation, under an "Optional
/// details" overline in edit.
class CardOptionalFieldsWidget extends StatelessWidget {
  const CardOptionalFieldsWidget({
    super.key,
    required this.isOpen,
    required this.hasHeader,
    required this.onOpen,
    required this.example,
    required this.hint,
    required this.pronunciation,
  });

  final bool isOpen;

  /// Edit names the group; create opens it from "Add details" instead.
  final bool hasHeader;
  final VoidCallback onOpen;
  final CardOptionalInput example;
  final CardOptionalInput hint;
  final CardOptionalInput pronunciation;

  @override
  Widget build(BuildContext context) {
    if (!isOpen) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
        child: CardAddDetailsWidget(onPressed: onOpen),
      );
    }
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.micro,
              0,
              AppSpacing.micro,
              AppSpacing.control,
            ),
            child: Text(
              l10n.cardOptionalDetails.toUpperCase(),
              semanticsLabel: l10n.cardOptionalDetails,
              style: context.textStyles.overline,
            ),
          ),
        for (final (input, icon, label, hintText) in [
          (
            example,
            AppIcons.example,
            l10n.cardFieldExample,
            l10n.cardExampleHint,
          ),
          (hint, AppIcons.hint, l10n.cardFieldHint, l10n.cardHintHint),
          (
            pronunciation,
            AppIcons.pronunciation,
            l10n.cardFieldPronunciation,
            l10n.cardPronunciationHint,
          ),
        ])
          CardFieldWidget(
            label: label,
            hint: hintText,
            icon: icon,
            limit: CardDraft.maxOptionalLength,
            controller: input.controller,
            variant: MxTextFieldVariant.detail,
            errorText: input.errorText,
            onChanged: (_) => input.onChanged(),
          ),
      ],
    );
  }
}
