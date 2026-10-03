import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/states/card_editor_source_state.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_draft_banner_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_edit_summary_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_optional_fields_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_trash_section_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_editor_messages_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The card editor's body (kit 08/09): the deck path over the banners and
/// fields, or the deck-gone page. It is laid out from the state its form
/// owns: the form keeps the text, the tags and every rule.
class CardEditorBodyWidget extends StatelessWidget {
  const CardEditorBodyWidget({
    super.key,
    required this.deckId,
    required this.deckContext,
    required this.isDeckGone,
    required this.isTyping,
    required this.onLeave,
    required this.detail,
    required this.card,
    required this.source,
    required this.isCardGone,
    required this.isDeckRejecting,
    required this.hasOffer,
    required this.onRestoreOffer,
    required this.onDiscardOffer,
    required this.front,
    required this.back,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.frontFocus,
    required this.errors,
    required this.onTouch,
    required this.isDetailsOpen,
    required this.onOpenDetailsSection,
    required this.tagEditorKey,
    required this.tags,
    required this.onTagsChanged,
    required this.onPendingTagChanged,
    required this.onOpenDetails,
    required this.onOpenTrash,
    required this.onTrashed,
  });

  final String deckId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// A new card's deck went away on Save.
  final bool isDeckGone;
  final VoidCallback onLeave;

  /// Whether the keyboard is up; read above the shell, which takes the
  /// insets from its body.
  final bool isTyping;

  /// The card under edit; null in create.
  final CardDetail? detail;

  /// The card as the form holds it, for its Trash section.
  final CardEntity? card;
  final CardEditorSource source;
  final bool isCardGone;
  final bool isDeckRejecting;

  /// Whether a draft kept from an earlier session is on offer.
  final bool hasOffer;
  final VoidCallback onRestoreOffer;
  final VoidCallback onDiscardOffer;
  final TextEditingController front;
  final TextEditingController back;
  final TextEditingController example;
  final TextEditingController hint;
  final TextEditingController pronunciation;
  final FocusNode frontFocus;
  final Map<CardEditorField, String?> errors;
  final ValueChanged<CardEditorField> onTouch;
  final bool isDetailsOpen;
  final VoidCallback onOpenDetailsSection;
  final GlobalKey<CardTagEditorWidgetState> tagEditorKey;
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final ValueChanged<bool> onPendingTagChanged;

  /// Leaves the form for the card's details.
  final VoidCallback onOpenDetails;
  final VoidCallback? onOpenTrash;

  /// The card went to the Trash from its Trash section.
  final VoidCallback onTrashed;

  /// One optional field's input, message and touch.
  CardOptionalInput _input(
    CardEditorField field,
    TextEditingController controller,
  ) => (
    controller: controller,
    errorText: errors[field],
    onChanged: () => onTouch(field),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isDeckGone) {
      return CardGoneWidget(
        title: l10n.cardDeckGoneTitle,
        body: l10n.cardDeckGoneBody,
        onBack: onLeave,
        onOpenTrash: onOpenTrash,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The path is context, not input: it waits while the keyboard is up
        // (audit P1; §9 row 81 kept at rest).
        if (!isTyping)
          deckContext(
            deckId,
            detail == null ? l10n.cardAddTitle : l10n.cardEditCrumb,
          ),
        Expanded(child: MxScreenScroll(children: _fields(l10n))),
      ],
    );
  }

  List<Widget> _fields(AppLocalizations l10n) {
    final detail = this.detail;
    return [
      const SizedBox(height: AppSpacing.control),
      if (hasOffer)
        CardDraftBannerWidget(
          onRestore: onRestoreOffer,
          onDiscard: onDiscardOffer,
        ),
      if (isDeckRejecting)
        MxInlineBanner(
          tone: MxBannerTone.warning,
          title: l10n.cardDeckRejectsTitle,
          message: l10n.cardDeckRejectsBody,
        ),
      if (isCardGone)
        MxInlineBanner(
          tone: MxBannerTone.danger,
          title: l10n.cardEditorGoneTitle,
          message: l10n.cardEditorGoneBody,
        )
      else if (source == CardEditorSource.unreadable)
        MxInlineBanner(
          tone: MxBannerTone.warning,
          title: l10n.cardEditorStaleTitle,
          message: l10n.cardEditorStaleBody,
        ),
      if (detail != null)
        CardEditSummaryWidget(detail: detail, onOpenDetails: onOpenDetails),
      CardFieldWidget(
        label: l10n.cardFieldFront,
        hint: l10n.cardFrontHint,
        limit: CardDraft.maxFrontLength,
        controller: front,
        focusNode: frontFocus,
        isRequired: true,
        variant: MxTextFieldVariant.term,
        errorText: errors[CardEditorField.front],
        onChanged: (_) => onTouch(CardEditorField.front),
      ),
      CardFieldWidget(
        label: l10n.cardFieldBack,
        hint: l10n.cardBackHint,
        limit: CardDraft.maxBackLength,
        controller: back,
        isRequired: true,
        variant: MxTextFieldVariant.meaning,
        errorText: errors[CardEditorField.back],
        onChanged: (_) => onTouch(CardEditorField.back),
      ),
      // In create, behind "Add details"; in edit, under "Optional details".
      CardOptionalFieldsWidget(
        isOpen: isDetailsOpen,
        hasHeader: detail != null,
        onOpen: onOpenDetailsSection,
        example: _input(CardEditorField.example, example),
        hint: _input(CardEditorField.hint, hint),
        pronunciation: _input(CardEditorField.pronunciation, pronunciation),
      ),
      CardTagEditorWidget(
        key: tagEditorKey,
        tags: tags,
        onChanged: onTagsChanged,
        onPendingChanged: onPendingTagChanged,
      ),
      if (card case final card? when !isCardGone)
        CardTrashSectionWidget(
          card: card,
          onTrashed: onTrashed,
          onOpenTrash: onOpenTrash,
        ),
    ];
  }
}
