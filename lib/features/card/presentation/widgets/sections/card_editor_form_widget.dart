import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_edit_summary_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_footer_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_optional_fields_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_trash_section_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

enum _Field { front, back, example, hint, pronunciation }

/// The card editor's form (kit 08/09), in create mode for [deckId] or in
/// edit mode for [detail]'s card. Validation is live; Save waits for a valid
/// card; a changed form asks before it is left (rulings P4a-L1…L6).
class CardEditorFormWidget extends ConsumerStatefulWidget {
  const CardEditorFormWidget({
    super.key,
    required this.deckId,
    required this.deckContext,
    this.detail,
    this.onOpenTrash,
  });

  /// The deck the card is written to.
  final String deckId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// The card to edit; null creates.
  final CardDetail? detail;

  /// Opens the Trash from the gone state and a refused Undo (FE-B1).
  final VoidCallback? onOpenTrash;

  @override
  ConsumerState<CardEditorFormWidget> createState() =>
      _CardEditorFormWidgetState();
}

class _CardEditorFormWidgetState extends ConsumerState<CardEditorFormWidget> {
  late final _card = widget.detail?.card;
  late final _front = TextEditingController(text: _card?.front);
  late final _back = TextEditingController(text: _card?.back);
  late final _example = TextEditingController(text: _card?.example);
  late final _hint = TextEditingController(text: _card?.hint);
  late final _pronunciation = TextEditingController(text: _card?.pronunciation);
  final _frontFocus = FocusNode();
  late var _tags = <String>[
    for (final tag in widget.detail?.tags ?? const <TagEntity>[]) tag.name,
  ];
  late var _isFlagged = _card?.isFlagged ?? false;
  late var _isDetailsOpen = !_isCreating;
  late var _saved = _draft();
  final _touched = <_Field>{};
  var _isSaving = false;
  var _hasFailed = false;
  var _deckRejects = false;
  var _isGone = false;
  var _isLeaving = false;
  var _hasPendingTag = false;
  final _tagEditor = GlobalKey<CardTagEditorWidgetState>();

  bool get _isCreating => widget.detail == null;

  List<TextEditingController> get _controllers => [
    _front,
    _back,
    _example,
    _hint,
    _pronunciation,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    _frontFocus.dispose();
    super.dispose();
  }

  static String? _optional(TextEditingController controller) =>
      controller.text.trim().isEmpty ? null : controller.text;

  CardDraft _draft() => CardDraft(
    front: _front.text,
    back: _back.text,
    example: _optional(_example),
    hint: _optional(_hint),
    pronunciation: _optional(_pronunciation),
    isFlagged: _isFlagged,
    tagNames: _tags,
  );

  bool get _isDirty {
    final draft = _draft();
    return _hasPendingTag ||
        draft.front != _saved.front ||
        draft.back != _saved.back ||
        draft.example != _saved.example ||
        draft.hint != _saved.hint ||
        draft.pronunciation != _saved.pronunciation ||
        draft.isFlagged != _saved.isFlagged ||
        !listEquals(draft.tagNames, _saved.tagNames);
  }

  /// What differs from the saved card, named for the discard dialog (kit 09),
  /// by the same comparisons as [_isDirty].
  List<String> _editedParts(AppLocalizations l10n) {
    final draft = _draft();
    return [
      if (draft.front != _saved.front) l10n.cardEditedTerm,
      if (draft.back != _saved.back) l10n.cardEditedMeaning,
      if (draft.example != _saved.example) l10n.cardEditedExample,
      if (draft.hint != _saved.hint) l10n.cardEditedHint,
      if (draft.pronunciation != _saved.pronunciation)
        l10n.cardEditedPronunciation,
      if (draft.isFlagged != _saved.isFlagged) l10n.cardEditedFlag,
      if (_hasPendingTag || !listEquals(draft.tagNames, _saved.tagNames))
        l10n.cardEditedTags,
    ];
  }

  /// Ruling P4a-L2: a blank side speaks once touched; a long one at once.
  String? _sideError(
    _Field field,
    Outcome<void, CardRejection> rule,
    String blank,
    String tooLong,
  ) => switch (rule) {
    Ok() => null,
    Rejected(reason: CardRejection.blankContent) =>
      _touched.contains(field) ? blank : null,
    Rejected() => tooLong,
  };

  Map<_Field, String?> _errors(AppLocalizations l10n) {
    String? optional(TextEditingController controller) =>
        switch (CardDraft.checkOptional(controller.text)) {
          Ok() => null,
          Rejected() => l10n.cardOptionalTooLong,
        };
    return {
      _Field.front: _sideError(
        _Field.front,
        CardDraft.checkFront(_front.text),
        l10n.cardFrontBlank,
        l10n.cardFrontTooLong,
      ),
      _Field.back: _sideError(
        _Field.back,
        CardDraft.checkBack(_back.text),
        l10n.cardBackBlank,
        l10n.cardBackTooLong,
      ),
      _Field.example: optional(_example),
      _Field.hint: optional(_hint),
      _Field.pronunciation: optional(_pronunciation),
    };
  }

  String _caption(AppLocalizations l10n, Map<_Field, String?> errors) {
    if (_isSaving) return l10n.cardCaptionSaving;
    if (_deckRejects) return l10n.cardCaptionDeckRejects;
    if (errors.values.any((error) => error != null)) {
      // Kit 09: an edit that lost a required side asks for it by name.
      final isMissing = _front.text.trim().isEmpty || _back.text.trim().isEmpty;
      return !_isCreating && isMissing
          ? l10n.cardCaptionAddMissing
          : l10n.cardCaptionFix;
    }
    if (_front.text.trim().isEmpty || _back.text.trim().isEmpty) {
      return l10n.cardCaptionRequired;
    }
    return _isCreating ? l10n.cardCaptionKeepAdding : l10n.cardCaptionEdit;
  }

  /// In edit, Save waits for a change (critique 2026-09-30 part 3d-1);
  /// create saves whatever is valid.
  VoidCallback? get _onSave =>
      _draft().check() is Ok &&
          !_isSaving &&
          !_deckRejects &&
          (_isCreating || _isDirty)
      ? () => unawaited(_save())
      : null;

  void _touch(_Field field) => setState(() => _touched.add(field));

  Future<void> _save() async {
    if (_isSaving) return;
    // The tag still in its field is part of the card (critique 2026-09-30
    // part 3d-2, E8); a refused one stops the save, saying why.
    if (!(_tagEditor.currentState?.commitPending() ?? true)) return;
    final draft = _draft();
    setState(() {
      _isSaving = true;
      _hasFailed = false;
    });
    final actions = ref.read(cardActionsControllerProvider.notifier);
    try {
      final Outcome<Object?, CardRejection> outcome = _isCreating
          ? await actions.createCard(deckId: widget.deckId, draft: draft)
          : await _edit(draft);
      if (!mounted) return;
      _afterSave(outcome, draft);
    } on Failure {
      // Ruling P4a-L3: said in the form, with the typed content kept.
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasFailed = true;
      });
    }
  }

  /// The content, then the flag only when the person toggled it here: the
  /// flag is not content (BR-CARD-009), so a save never writes back the one
  /// the editor opened with (DEV-220). The controller is read again for the
  /// second write: nothing keeps it alive across the first.
  Future<Outcome<void, CardRejection>> _edit(CardDraft draft) async {
    final cardId = _card!.id;
    final outcome = await ref
        .read(cardActionsControllerProvider.notifier)
        .editCard(cardId: cardId, draft: draft);
    if (outcome is! Ok || draft.isFlagged == _saved.isFlagged || !mounted) {
      return outcome;
    }
    return ref
        .read(cardActionsControllerProvider.notifier)
        .setFlagged(cardIds: {cardId}, isFlagged: draft.isFlagged);
  }

  void _afterSave(Outcome<Object?, CardRejection> outcome, CardDraft draft) {
    final l10n = context.l10n;
    switch (outcome) {
      case Ok() when _isCreating:
        _clearForNext();
        showMxSnackbar(context, message: l10n.cardAddedToast);
      case Ok():
        _saved = draft;
        _leave();
      case Rejected(reason: CardRejection.notACardContainer):
        setState(() {
          _isSaving = false;
          _deckRejects = true;
        });
      case Rejected(reason: CardRejection.notFound):
        setState(() => _isGone = true);
      case Rejected(:final reason):
        setState(() => _isSaving = false);
        showMxSnackbar(context, message: l10n.cardRejection(reason));
    }
  }

  /// UC-CARD-001 A4: the next card starts from an empty form.
  void _clearForNext() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _tagEditor.currentState?.clearInput();
    setState(() {
      _tags = [];
      _isFlagged = false;
      _touched.clear();
      _isSaving = false;
      _saved = _draft();
    });
    _frontFocus.requestFocus();
  }

  /// Leaves once the frame shows the form as leaving, so the guard lets go.
  void _leave() {
    setState(() {
      _isLeaving = true;
      _isSaving = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(Navigator.of(context).maybePop());
    });
  }

  Future<void> _confirmLeave() async {
    final discard = await showCardDiscardDialog(
      context,
      isNew: _isCreating,
      edited: _isCreating ? const [] : _editedParts(context.l10n),
    );
    if (discard && mounted) _leave();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errors = _errors(l10n);
    final isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: _isLeaving || _isGone || !_isDirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: MxAppShell(
        appBar: _appBar(l10n),
        footer: _isGone
            ? null
            : CardEditorFooterWidget(
                caption: _caption(l10n, errors),
                saveLabel: _isCreating
                    ? l10n.cardSaveCard
                    : l10n.cardSaveChanges,
                hasFailed: _hasFailed,
                isSaving: _isSaving,
                onCancel: _close,
                onSave: _onSave,
              ),
        body: _isGone
            ? CardGoneWidget(
                title: _isCreating
                    ? l10n.cardDeckGoneTitle
                    : l10n.cardGoneTitle,
                body: _isCreating ? l10n.cardDeckGoneBody : l10n.cardGoneBody,
                onBack: _leave,
                onOpenTrash: widget.onOpenTrash,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The path is context, not input: it waits while the
                  // keyboard is up (audit P1; §9 row 81 kept at rest).
                  if (!isTyping)
                    widget.deckContext(
                      widget.deckId,
                      _isCreating ? l10n.cardAddTitle : l10n.cardEditCrumb,
                    ),
                  Expanded(
                    child: MxScreenScroll(children: _fields(l10n, errors)),
                  ),
                ],
              ),
      ),
    );
  }

  MxAppBar _appBar(AppLocalizations l10n) => MxAppBar(
    title: _isCreating ? l10n.cardAddTitle : l10n.cardEditTitle,
    density: MxAppBarDensity.content,
    leading: MxIconButton(
      icon: _isCreating ? AppIcons.close : AppIcons.back,
      semanticLabel: _isCreating ? l10n.cardClose : l10n.commonBack,
      onPressed: _close,
    ),
    actions: [
      // Ruling P4a-L6: the flag toggles here, in edit only.
      if (!_isCreating && !_isGone)
        // One node: the button and its toggled state.
        MergeSemantics(
          child: Semantics(
            toggled: _isFlagged,
            child: MxIconButton(
              icon: _isFlagged ? AppIcons.flagged : AppIcons.flag,
              semanticLabel: _isFlagged
                  ? l10n.cardFlagClear
                  : l10n.cardFlagLabel,
              onPressed: () => setState(() => _isFlagged = !_isFlagged),
            ),
          ),
        ),
    ],
  );

  List<Widget> _fields(AppLocalizations l10n, Map<_Field, String?> errors) => [
    const SizedBox(height: AppSpacing.control),
    if (_deckRejects)
      MxInlineBanner(
        tone: MxBannerTone.warning,
        title: l10n.cardDeckRejectsTitle,
        message: l10n.cardDeckRejectsBody,
      ),
    if (widget.detail case final detail?)
      CardEditSummaryWidget(detail: detail, onOpenDetails: _close),
    CardFieldWidget(
      label: l10n.cardFieldFront,
      hint: l10n.cardFrontHint,
      limit: CardDraft.maxFrontLength,
      controller: _front,
      focusNode: _frontFocus,
      isRequired: true,
      variant: MxTextFieldVariant.term,
      errorText: errors[_Field.front],
      onChanged: (_) => _touch(_Field.front),
    ),
    CardFieldWidget(
      label: l10n.cardFieldBack,
      hint: l10n.cardBackHint,
      limit: CardDraft.maxBackLength,
      controller: _back,
      isRequired: true,
      variant: MxTextFieldVariant.detail,
      errorText: errors[_Field.back],
      onChanged: (_) => _touch(_Field.back),
    ),
    // In create, behind "Add details"; in edit, under "Optional details".
    CardOptionalFieldsWidget(
      isOpen: _isDetailsOpen,
      hasHeader: !_isCreating,
      onOpen: () => setState(() => _isDetailsOpen = true),
      example: _input(_Field.example, _example, errors),
      hint: _input(_Field.hint, _hint, errors),
      pronunciation: _input(_Field.pronunciation, _pronunciation, errors),
    ),
    CardTagEditorWidget(
      key: _tagEditor,
      tags: _tags,
      onChanged: (tags) => setState(() => _tags = tags),
      onPendingChanged: (isPending) =>
          setState(() => _hasPendingTag = isPending),
    ),
    if (_card case final card?)
      CardTrashSectionWidget(card: card, onOpenTrash: widget.onOpenTrash),
  ];

  /// One optional field's input, message and touch.
  CardOptionalInput _input(
    _Field field,
    TextEditingController controller,
    Map<_Field, String?> errors,
  ) => (
    controller: controller,
    errorText: errors[field],
    onChanged: () => _touch(field),
  );
}
