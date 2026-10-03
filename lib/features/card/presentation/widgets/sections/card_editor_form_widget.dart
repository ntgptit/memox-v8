import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_key_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_draft_controller_factory_provider.dart';
import 'package:memox/features/card/presentation/states/card_editor_source_state.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_changed_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_footer_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_app_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_body_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_editor_messages_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// The card editor's form (kit 08/09), in create mode for [deckId] or in
/// edit mode for [detail]'s card. Validation is live; Save waits for a valid
/// card; a changed form asks before it is left (rulings P4a-L1…L6).
class CardEditorFormWidget extends ConsumerStatefulWidget {
  const CardEditorFormWidget({
    super.key,
    required this.deckId,
    required this.deckContext,
    this.detail,
    this.source = CardEditorSource.present,
    this.onOpenTrash,
  });

  /// The deck the card is written to.
  final String deckId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// The card to edit, as it stands now; null creates. "Use theirs" loads it
  /// (SP2a 2.18).
  final CardDetail? detail;

  /// Whether the card under edit is still there (SP2a 2.17).
  final CardEditorSource source;

  /// Opens the Trash from the gone state and a refused Undo (FE-B1).
  final VoidCallback? onOpenTrash;

  @override
  ConsumerState<CardEditorFormWidget> createState() =>
      _CardEditorFormWidgetState();
}

class _CardEditorFormWidgetState extends ConsumerState<CardEditorFormWidget> {
  late var _card = widget.detail?.card;
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
  late CardDraft _saved;
  final _touched = <CardEditorField>{};
  var _isSaving = false;
  var _hasFailed = false;
  var _deckRejects = false;
  var _isGone = false;
  var _isLeaving = false;
  var _hasPendingTag = false;
  final _tagEditor = GlobalKey<CardTagEditorWidgetState>();
  late final _drafts = ref.read(cardDraftControllerFactoryProvider)(
    _isCreating
        ? CardDraftKey.create(widget.deckId)
        : CardDraftKey.edit(_card!.id),
  );

  /// A draft kept from an earlier session, on offer above the fields (R9).
  CardDraft? _offer;

  /// The version a restored draft was written against: Save goes out against
  /// it, so another device's save since then asks first (SP2a 2.18).
  DateTime? _restoredBase;

  /// The version the text on screen is based on: what Save expects and what
  /// a draft records.
  DateTime? get _baseUpdatedAt => _restoredBase ?? _card?.updatedAt;

  bool get _isCreating => widget.detail == null;

  /// A new card's deck went away on Save: nothing is left to write to, so the
  /// page says so. (An edited card that goes away keeps the form; see
  /// [_isCardGone].)
  bool get _isDeckGone => _isCreating && _isGone;

  /// The card under edit was deleted, from outside or found missing on Save:
  /// the form stays with its text, Save is off and the draft is kept.
  bool get _isCardGone =>
      !_isCreating && (_isGone || widget.source == CardEditorSource.gone);

  List<TextEditingController> get _controllers => [
    _front,
    _back,
    _example,
    _hint,
    _pronunciation,
  ];

  @override
  void initState() {
    super.initState();
    _saved = _draft();
    for (final controller in _controllers) {
      controller.addListener(_keepDraft);
    }
    unawaited(_offerKeptDraft());
  }

  @override
  void didUpdateWidget(CardEditorFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The card went away while it was open: what is on screen is written now.
    if (oldWidget.source != widget.source &&
        widget.source == CardEditorSource.gone) {
      _keepNow();
    }
    // A restored card is saveable again. Only the gone-to-present change
    // says so: any other update of a present card must not undo a notFound
    // the Save just found.
    if (!_isCreating &&
        oldWidget.source == CardEditorSource.gone &&
        widget.source == CardEditorSource.present) {
      _isGone = false;
    }
  }

  @override
  void dispose() {
    // What waits for the pause is written now: leaving mid-pause loses
    // nothing.
    unawaited(_drafts.flush());
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
    baseUpdatedAt: _baseUpdatedAt,
  );

  bool get _isDirty => _hasPendingTag || !_draft().sameContentAs(_saved);

  Map<CardEditorField, String> get _texts => {
    CardEditorField.front: _front.text,
    CardEditorField.back: _back.text,
    CardEditorField.example: _example.text,
    CardEditorField.hint: _hint.text,
    CardEditorField.pronunciation: _pronunciation.text,
  };

  /// In edit, Save waits for a change (critique 2026-09-30 part 3d-1);
  /// create saves whatever is valid.
  VoidCallback? get _onSave =>
      _draft().check() is Ok &&
          !_isSaving &&
          !_deckRejects &&
          !_isCardGone &&
          (_isCreating || _isDirty)
      ? () => unawaited(_save())
      : null;

  void _touch(CardEditorField field) => setState(() => _touched.add(field));

  /// The draft kept for this form, offered back when it differs from what the
  /// form shows now; a draft equal to it is dropped (R9).
  Future<void> _offerKeptDraft() async {
    final kept = await _drafts.read();
    if (kept == null) return;
    if (kept.sameContentAs(_saved)) {
      unawaited(_drafts.clear());
      return;
    }
    if (mounted) setState(() => _offer = kept);
  }

  /// Every change goes to the draft once typing pauses. While an earlier
  /// draft is on offer it stays as it is until the person answers it.
  void _keepDraft() {
    if (_isLeaving || _offer != null) return;
    _drafts.schedule(_draft(), saved: _saved);
  }

  void _restoreOffer() {
    final draft = _offer;
    if (draft == null) return;
    // _offer is still set while the controllers change, so the listeners
    // write nothing: the kept draft is already what is on screen.
    _front.text = draft.front;
    _back.text = draft.back;
    _example.text = draft.example ?? '';
    _hint.text = draft.hint ?? '';
    _pronunciation.text = draft.pronunciation ?? '';
    setState(() {
      _tags = [...draft.tagNames];
      _isFlagged = draft.isFlagged;
      _isDetailsOpen = _isDetailsOpen || draft.hasOptionalText;
      _restoredBase = draft.baseUpdatedAt;
      _offer = null;
    });
  }

  /// The card went to the Trash from here: its edits go with it, and the
  /// gone card that follows writes nothing.
  void _dropEdits() {
    _isLeaving = true;
    unawaited(_drafts.clear());
  }

  void _discardOffer() {
    setState(() => _offer = null);
    unawaited(_drafts.clear());
  }

  /// [overwrites] saves over a version another device saved ("Keep mine").
  Future<void> _save({bool overwrites = false}) async {
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
          : await actions.editCard(
              cardId: _card!.id,
              draft: draft,
              expectedUpdatedAt: overwrites ? null : _baseUpdatedAt,
            );
      if (!mounted) return;
      if (outcome case Rejected(reason: CardRejection.changedElsewhere)) {
        setState(() => _isSaving = false);
        await _resolveConflict();
        return;
      }
      _afterSave(outcome, draft);
    } on Failure {
      // Ruling P4a-L3: said in the form, with the typed content kept.
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasFailed = true;
      });
    } catch (error, stack) {
      // Any other error must not leave the hold on: Back, close and Cancel
      // work again (SP2a 2.16). _save runs unawaited, so the error is
      // reported here rather than thrown into the zone.
      if (mounted && _isSaving) setState(() => _isSaving = false);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'card editor',
        ),
      );
    }
  }

  /// SP2a 2.18: another device saved this card since the editor opened.
  Future<void> _resolveConflict() async {
    final choice = await showCardChangedDialog(context);
    if (!mounted) return;
    switch (choice) {
      case CardConflictChoice.keepMine:
        unawaited(_save(overwrites: true));
      case CardConflictChoice.useTheirs:
        _adoptTheirs();
      case null:
        return;
    }
  }

  /// "Use theirs": the card as the other device left it replaces the form's
  /// text, and the draft goes with the edits it held.
  void _adoptTheirs() {
    final theirs = widget.detail;
    if (theirs == null) return;
    final card = theirs.card;
    _card = card;
    _restoredBase = null;
    _front.text = card.front;
    _back.text = card.back;
    _example.text = card.example ?? '';
    _hint.text = card.hint ?? '';
    _pronunciation.text = card.pronunciation ?? '';
    _tagEditor.currentState?.clearInput();
    setState(() {
      _tags = [for (final tag in theirs.tags) tag.name];
      _isFlagged = card.isFlagged;
      _touched.clear();
      _hasFailed = false;
      _offer = null;
      _saved = _draft();
    });
    // The new text armed a write; clearing cancels it.
    unawaited(_drafts.clear());
  }

  void _afterSave(Outcome<Object?, CardRejection> outcome, CardDraft draft) {
    final l10n = context.l10n;
    switch (outcome) {
      case Ok() when _isCreating:
        _clearForNext();
        showMxSnackbar(context, message: l10n.cardAddedToast);
      case Ok():
        _saved = draft;
        unawaited(_drafts.clear());
        _leave();
      case Rejected(reason: CardRejection.notACardContainer):
        _keepNow();
        setState(() {
          _isSaving = false;
          _deckRejects = true;
        });
      case Rejected(reason: CardRejection.notFound):
        _keepNow();
        setState(() {
          _isSaving = false;
          _isGone = true;
        });
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
      _offer = null;
    });
    // The cleared controllers armed a write; clearing cancels it.
    unawaited(_drafts.clear());
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

  /// What is on screen is what a refusal would strand: it goes to the draft
  /// at once, ahead of any earlier draft on offer (SP2a 2.15). A form nobody
  /// touched has nothing to write, and an unchanged write would drop the
  /// draft on offer, so that draft stays offered.
  void _keepNow() {
    if (_isLeaving) return;
    if (_offer != null && _draft().sameContentAs(_saved)) return;
    _offer = null;
    _drafts.schedule(_draft(), saved: _saved);
    unawaited(_drafts.flush());
  }

  Future<void> _confirmLeave() async {
    if (_isSaving) return;
    final discard = await showCardDiscardDialog(
      context,
      isNew: _isCreating,
      edited: _isCreating
          ? const []
          : context.l10n.cardEditedParts(
              draft: _draft(),
              saved: _saved,
              hasPendingTag: _hasPendingTag,
            ),
    );
    if (!discard || !mounted) return;
    unawaited(_drafts.clear());
    _leave();
  }

  void _close() {
    if (_isSaving) return;
    unawaited(Navigator.of(context).maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errors = l10n.cardEditorErrors(_texts, _touched);
    final isTyping = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      // A refused deck leaves without asking: its text is already in the
      // draft. A save in flight holds Back (SP2a 2.15, 2.16).
      canPop:
          !_isSaving &&
          (_isLeaving || _isGone || _deckRejects || _isCardGone || !_isDirty),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _isSaving) return;
        unawaited(_confirmLeave());
      },
      child: MxAppShell(
        appBar: CardEditorAppBarWidget(
          isCreating: _isCreating,
          isCardGone: _isCardGone,
          isFlagged: _isFlagged,
          isSaving: _isSaving,
          onClose: _close,
          onToggleFlag: () {
            setState(() => _isFlagged = !_isFlagged);
            _keepDraft();
          },
        ),
        footer: _isDeckGone
            ? null
            : CardEditorFooterWidget(
                caption: l10n.cardEditorCaption(
                  texts: _texts,
                  errors: errors,
                  isCreating: _isCreating,
                  isSaving: _isSaving,
                  isCardGone: _isCardGone,
                  deckRejects: _deckRejects,
                ),
                saveLabel: _isCreating
                    ? l10n.cardSaveCard
                    : l10n.cardSaveChanges,
                hasFailed: _hasFailed,
                isSaving: _isSaving,
                onCancel: _isSaving ? null : _close,
                onSave: _onSave,
              ),
        body: _body(errors, isTyping: isTyping),
      ),
    );
  }

  Widget _body(
    Map<CardEditorField, String?> errors, {
    required bool isTyping,
  }) => CardEditorBodyWidget(
    deckId: widget.deckId,
    deckContext: widget.deckContext,
    isDeckGone: _isDeckGone,
    isTyping: isTyping,
    onLeave: _leave,
    detail: widget.detail,
    card: _card,
    source: widget.source,
    isCardGone: _isCardGone,
    isDeckRejecting: _deckRejects,
    hasOffer: _offer != null,
    onRestoreOffer: _restoreOffer,
    onDiscardOffer: _discardOffer,
    front: _front,
    back: _back,
    example: _example,
    hint: _hint,
    pronunciation: _pronunciation,
    frontFocus: _frontFocus,
    errors: errors,
    onTouch: _touch,
    isDetailsOpen: _isDetailsOpen,
    onOpenDetailsSection: () => setState(() => _isDetailsOpen = true),
    tagEditorKey: _tagEditor,
    tags: _tags,
    onTagsChanged: (tags) {
      setState(() => _tags = tags);
      _keepDraft();
    },
    onPendingTagChanged: (isPending) =>
        setState(() => _hasPendingTag = isPending),
    onOpenDetails: _close,
    onOpenTrash: widget.onOpenTrash,
    onTrashed: _dropEdits,
  );
}
