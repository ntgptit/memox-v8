import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/overlays/card_discard_dialog_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_edit_summary_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_footer_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_field_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_gone_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_tag_editor_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

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
  });

  /// The deck the card is written to.
  final String deckId;
  final Widget Function(String deckId, String currentLabel) deckContext;

  /// The card to edit; null creates.
  final CardDetail? detail;

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
    if (errors.values.any((error) => error != null)) return l10n.cardCaptionFix;
    if (_front.text.trim().isEmpty || _back.text.trim().isEmpty) {
      return l10n.cardCaptionRequired;
    }
    return _isCreating ? l10n.cardCaptionKeepAdding : l10n.cardCaptionEdit;
  }

  VoidCallback? get _onSave =>
      _draft().check() is Ok && !_isSaving && !_deckRejects
      ? () => unawaited(_save())
      : null;

  void _touch(_Field field) => setState(() => _touched.add(field));

  Future<void> _save() async {
    if (_isSaving) return;
    final draft = _draft();
    setState(() {
      _isSaving = true;
      _hasFailed = false;
    });
    final actions = ref.read(cardActionsControllerProvider.notifier);
    try {
      final Outcome<Object?, CardRejection> outcome = _isCreating
          ? await actions.createCard(deckId: widget.deckId, draft: draft)
          : await actions.editCard(cardId: _card!.id, draft: draft);
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
    final discard = await showCardDiscardDialog(context, isNew: _isCreating);
    if (discard && mounted) _leave();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final errors = _errors(l10n);
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
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
      if (!_isGone)
        MxButton(
          label: l10n.cardSave,
          size: MxButtonSize.compact,
          isLoading: _isSaving,
          onPressed: _onSave,
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
      errorText: errors[_Field.front],
      onChanged: (_) => _touch(_Field.front),
    ),
    CardFieldWidget(
      label: l10n.cardFieldBack,
      hint: l10n.cardBackHint,
      limit: CardDraft.maxBackLength,
      controller: _back,
      isRequired: true,
      isMultiline: true,
      errorText: errors[_Field.back],
      onChanged: (_) => _touch(_Field.back),
    ),
    ..._optionalFields(l10n, errors),
    CardTagEditorWidget(
      tags: _tags,
      onChanged: (tags) => setState(() => _tags = tags),
      onPendingChanged: (isPending) =>
          setState(() => _hasPendingTag = isPending),
    ),
  ];

  /// In create, behind "Add details"; in edit, under "Optional details".
  List<Widget> _optionalFields(
    AppLocalizations l10n,
    Map<_Field, String?> errors,
  ) {
    if (!_isDetailsOpen) {
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
          child: MxButton(
            label: l10n.cardAddDetails,
            icon: AppIcons.details,
            tone: MxButtonTone.outline,
            isBlock: true,
            onPressed: () => setState(() => _isDetailsOpen = true),
          ),
        ),
      ];
    }
    return [
      if (!_isCreating)
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
      for (final (field, icon, label, hint, controller) in [
        (
          _Field.example,
          AppIcons.example,
          l10n.cardFieldExample,
          l10n.cardExampleHint,
          _example,
        ),
        (
          _Field.hint,
          AppIcons.hint,
          l10n.cardFieldHint,
          l10n.cardHintHint,
          _hint,
        ),
        (
          _Field.pronunciation,
          AppIcons.pronunciation,
          l10n.cardFieldPronunciation,
          l10n.cardPronunciationHint,
          _pronunciation,
        ),
      ])
        CardFieldWidget(
          label: label,
          hint: hint,
          icon: icon,
          limit: CardDraft.maxOptionalLength,
          controller: controller,
          isMultiline: true,
          errorText: errors[field],
          onChanged: (_) => _touch(field),
        ),
    ];
  }
}
