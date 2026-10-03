import 'package:flutter/foundation.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// The card editor's text fields, keyed for its messages.
enum CardEditorField { front, back, example, hint, pronunciation }

/// What the card editor says about its fields: the parts a discard names,
/// each field's message and the footer caption.
extension CardEditorMessages on AppLocalizations {
  /// What differs from the saved card, named for the discard dialog (kit 09),
  /// by the same comparisons as the form's dirty check.
  List<String> cardEditedParts({
    required CardDraft draft,
    required CardDraft saved,
    required bool hasPendingTag,
  }) => [
    if (draft.front != saved.front) cardEditedTerm,
    if (draft.back != saved.back) cardEditedMeaning,
    if (draft.example != saved.example) cardEditedExample,
    if (draft.hint != saved.hint) cardEditedHint,
    if (draft.pronunciation != saved.pronunciation) cardEditedPronunciation,
    if (draft.isFlagged != saved.isFlagged) cardEditedFlag,
    if (hasPendingTag || !listEquals(draft.tagNames, saved.tagNames))
      cardEditedTags,
  ];

  /// Ruling P4a-L2: a blank side speaks once [touched]; a long one at once.
  String? _sideError(
    bool touched,
    Outcome<void, CardRejection> rule,
    String blank,
    String tooLong,
  ) => switch (rule) {
    Ok() => null,
    Rejected(reason: CardRejection.blankContent) => touched ? blank : null,
    Rejected() => tooLong,
  };

  /// The message of each field in [texts], for the fields in [touched].
  Map<CardEditorField, String?> cardEditorErrors(
    Map<CardEditorField, String> texts,
    Set<CardEditorField> touched,
  ) {
    String? optional(CardEditorField field) =>
        switch (CardDraft.checkOptional(texts[field]!)) {
          Ok() => null,
          Rejected() => cardOptionalTooLong,
        };
    return {
      CardEditorField.front: _sideError(
        touched.contains(CardEditorField.front),
        CardDraft.checkFront(texts[CardEditorField.front]!),
        cardFrontBlank,
        cardFrontTooLong,
      ),
      CardEditorField.back: _sideError(
        touched.contains(CardEditorField.back),
        CardDraft.checkBack(texts[CardEditorField.back]!),
        cardBackBlank,
        cardBackTooLong,
      ),
      CardEditorField.example: optional(CardEditorField.example),
      CardEditorField.hint: optional(CardEditorField.hint),
      CardEditorField.pronunciation: optional(CardEditorField.pronunciation),
    };
  }

  /// The footer caption for the form's state.
  String cardEditorCaption({
    required Map<CardEditorField, String> texts,
    required Map<CardEditorField, String?> errors,
    required bool isCreating,
    required bool isSaving,
    required bool isCardGone,
    required bool deckRejects,
  }) {
    if (isSaving) return cardCaptionSaving;
    if (isCardGone) return cardCaptionGone;
    if (deckRejects) return cardCaptionDeckRejects;
    final isMissing =
        texts[CardEditorField.front]!.trim().isEmpty ||
        texts[CardEditorField.back]!.trim().isEmpty;
    if (errors.values.any((error) => error != null)) {
      // Kit 09: an edit that lost a required side asks for it by name.
      return !isCreating && isMissing ? cardCaptionAddMissing : cardCaptionFix;
    }
    if (isMissing) return cardCaptionRequired;
    return isCreating ? cardCaptionKeepAdding : cardCaptionEdit;
  }
}
